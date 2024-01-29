

resource "aws_ecs_cluster" "cluster" {
  name = local.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster-capacity-provider" {
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  cluster_name       = aws_ecs_cluster.cluster.name
}


resource "aws_ecs_service" "service" {
  cluster         = aws_ecs_cluster.cluster.id
  desired_count   = 0
  name            = local.ecs_service_name
  task_definition = aws_ecs_task_definition.task-definition.arn

  deployment_minimum_healthy_percent = 50

  capacity_provider_strategy {
    base              = 1
    capacity_provider = var.fargate_spot_pricing ? "FARGATE_SPOT" : "FARGATE"
    weight            = 1
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.service-security-group.id]
    subnets          = module.vpc.public_subnet_ids
  }
}

resource "aws_ecs_task_definition" "task-definition" {
  container_definitions = jsonencode([
    {
      environment      = local.server_environment_variables
      essential        = false
      image            = local.minecraft_server_config["image"]
      logConfiguration = var.save_server_logs ? {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.server-log-group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = local.minecraft_server_container_name
        }
      } : null
      mountPoints = [
        {
          containerPath = "/data"
          readOnly      = false
          sourceVolume  = local.ecs_volume_name,
        }
      ]
      name         = local.minecraft_server_container_name
      portMappings = [
        {
          containerPort = local.minecraft_server_config["port"]
          hostPort      = local.minecraft_server_config["port"]
          protocol      = local.minecraft_server_config["protocol"]
        }
      ]
    },
    {
      environment = [
        { name = "CLUSTER", value = local.ecs_cluster_name },
        { name = "SERVICE", value = local.ecs_service_name },
        { name = "DNSZONE", value = aws_route53_zone.hosted-zone.id },
        { name = "SERVERNAME", value = local.subdomain },
        { name = "STARTUPMIN", value = tostring(var.server_startup_timeout) },
        { name = "SHUTDOWNMIN", value = tostring(var.server_shutdown_timeout) },
        { name = "SNSTOPIC", value = aws_sns_topic.server-notifications.arn },
        { name = "TWILIOFROM", value = "" },
        { name = "TWILIOTO", value = "" },
        { name = "TWILIOAID", value = "" },
        { name = "TWILIOAUTH", value = "" },
      ],
      essential        = true
      image            = "doctorray/minecraft-ecsfargate-watchdog"
      logConfiguration = var.save_server_logs ? {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.watchdog-log-group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = local.watchdog_server_container_name
        }
      } : null
      name = local.watchdog_server_container_name
    }
  ])

  execution_role_arn       = aws_iam_role.task-execution-role.arn
  family                   = "${var.name}-mc-on-demand"
  cpu                      = var.server_cpu_units
  memory                   = var.server_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task-definition-role.arn

  volume {
    name = local.ecs_volume_name

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.file-system.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.file-system-access-point.id
        iam             = "ENABLED"
      }
    }
  }
}