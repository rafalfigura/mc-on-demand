resource "aws_cloudwatch_log_group" "query-log-group" {
  name              = "/aws/route53/${aws_route53_zone.hosted-zone.name}"
  retention_in_days = 3
  provider          = aws.us-east-1
}

resource "aws_cloudwatch_log_group" "server-log-group" {
  name_prefix       = "mod-server-logs-"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_group" "watchdog-log-group" {
  name_prefix       = "mod-watchdog-logs-"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_resource_policy" "query-log-resource-policy" {
  policy_document = data.aws_iam_policy_document.query-log-group-policy-document.json
  policy_name     = random_id.query-log-resource-policy-name.dec
  provider        = aws.us-east-1
}

resource "aws_cloudwatch_log_subscription_filter" "query-log-subscription-filter" {
  provider        = aws.us-east-1
  depends_on      = [aws_lambda_permission.allow_cloudwatch]
  destination_arn = aws_lambda_function.autoscaler-lambda.arn
  filter_pattern  = local.subdomain
  log_group_name  = aws_cloudwatch_log_group.query-log-group.name
  name            = random_id.query-log-subscription-filter-name.dec
}

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
      logConfiguration = var.server_debug ? {
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
        { name = "STARTUPMIN", value = tostring(var.server_startup_time) },
        { name = "SHUTDOWNMIN", value = tostring(var.server_shutdown_time) },
        { name = "SNSTOPIC", value = aws_sns_topic.server-notifications.arn },
        { name = "TWILIOFROM", value = "" },
        { name = "TWILIOTO", value = "" },
        { name = "TWILIOAID", value = "" },
        { name = "TWILIOAUTH", value = "" },
      ],
      essential        = true
      image            = "doctorray/minecraft-ecsfargate-watchdog"
      logConfiguration = var.server_debug ? {
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
  family                   = random_id.task-definition-family.dec
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

resource "aws_efs_access_point" "file-system-access-point" {
  file_system_id = aws_efs_file_system.file-system.id

  posix_user {
    gid = local.efs_gid
    uid = local.efs_uid
  }

  root_directory {
    creation_info {
      owner_gid   = local.efs_gid
      owner_uid   = local.efs_uid
      permissions = "0755"
    }

    path = "/minecraft"
  }

  tags = {
    Name = random_id.file-system-access-point-name.dec
  }
}

resource "aws_efs_file_system" "file-system" {
  encrypted = true

  #  lifecycle {
  #    prevent_destroy = true
  #  }

  tags = {
    Name = random_id.file-system-name.dec
  }
}

resource "aws_efs_mount_target" "file-system-mount-target" {
  count           = length(module.vpc.isolated_subnet_ids)
  file_system_id  = aws_efs_file_system.file-system.id
  security_groups = [aws_security_group.file-system-security-group.id]
  subnet_id       = module.vpc.isolated_subnet_ids[count.index]
}

resource "aws_iam_policy" "service-policy" {
  name_prefix = "mod-service-policy-"
  policy      = data.aws_iam_policy_document.service-policy-document.json
}

resource "aws_iam_policy" "file-system-policy" {
  name_prefix = "mod-file-system-policy-"
  policy      = data.aws_iam_policy_document.file-system-policy-document.json
}

resource "aws_iam_policy" "hosted-zone-policy" {
  name_prefix = "mod-hosted-zone-policy-"
  policy      = data.aws_iam_policy_document.hosted-zone-policy-document.json
}

resource "aws_iam_policy" "server-notifications-policy" {
  name_prefix = "mod-server-notifications-policy-"
  policy      = data.aws_iam_policy_document.server-notifications-policy-document.json
}

resource "aws_iam_role" "autoscaler-lambda-role" {
  assume_role_policy = data.aws_iam_policy_document.autoscaler-lambda-policy-document.json
  name_prefix        = "mod-autoscaler-role-"
  provider           = aws.us-east-1
}

resource "aws_iam_role" "task-definition-role" {
  assume_role_policy = data.aws_iam_policy_document.task-definition-assume-role-policy-document.json
  name_prefix        = "mod-task-definition-role-"
}

resource "aws_iam_role" "task-execution-role" {
  assume_role_policy = data.aws_iam_policy_document.task-definition-assume-role-policy-document.json
  name_prefix        = "mod-task-execution-role-"
}

resource "aws_iam_role_policy_attachment" "autoscaler-lambda-basic-execution-policy-attachment" {
  policy_arn = data.aws_iam_policy.autoscaler-lambda-basic-execution-policy.arn
  provider   = aws.us-east-1
  role       = aws_iam_role.autoscaler-lambda-role.name
}

resource "aws_iam_role_policy_attachment" "autoscaler-lambda-cluster-policy-attachment" {
  policy_arn = aws_iam_policy.service-policy.arn
  provider   = aws.us-east-1
  role       = aws_iam_role.autoscaler-lambda-role.name
}

resource "aws_iam_role_policy_attachment" "task-definition-role-service-policy-attachment" {
  policy_arn = aws_iam_policy.service-policy.arn
  role       = aws_iam_role.task-definition-role.name
}

resource "aws_iam_role_policy_attachment" "task-definition-role-file-system-policy-attachment" {
  policy_arn = aws_iam_policy.file-system-policy.arn
  role       = aws_iam_role.task-definition-role.name
}

resource "aws_iam_role_policy_attachment" "task-definition-role-hosted-zone-policy-attachment" {
  policy_arn = aws_iam_policy.hosted-zone-policy.arn
  role       = aws_iam_role.task-definition-role.name
}

resource "aws_iam_role_policy_attachment" "task-definition-role-server-notifications-policy-attachment" {
  policy_arn = aws_iam_policy.server-notifications-policy.arn
  role       = aws_iam_role.task-definition-role.name
}

resource "aws_iam_role_policy_attachment" "task-execution-policy-attachment" {
  policy_arn = data.aws_iam_policy.task-execution-policy.arn
  role       = aws_iam_role.task-execution-role.name
}


resource "aws_route53_query_log" "query-log" {
  provider                 = aws.us-east-1
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.query-log-group.arn
  zone_id                  = aws_route53_zone.hosted-zone.zone_id
}

// dummy record, to be changed whenever the container launches
// which is why changes to the `records` property are ignored
resource "aws_route53_record" "hosted-zone-a-record" {
  name     = local.subdomain
  provider = aws.us-east-1
  records  = ["192.168.1.1"]
  ttl      = 30
  type     = "A"
  zone_id  = aws_route53_zone.hosted-zone.zone_id

  lifecycle {
    ignore_changes = [
      records
    ]
  }
}

// @TODO - create an ability to auto create hosted zone if it doesn't exist
resource "aws_route53_record" "root-hosted-zone-ns-record" {
  name     = local.subdomain
  provider = aws.us-east-1
  records  = aws_route53_zone.hosted-zone.name_servers
  ttl      = 172800
  type     = "NS"
  zone_id  = data.aws_route53_zone.root-hosted-zone.zone_id
}

resource "aws_route53_zone" "hosted-zone" {
  name     = local.subdomain
  provider = aws.us-east-1
}


resource "aws_security_group" "file-system-security-group" {
  name_prefix = "mod-file-system-security-group-"

  ingress {
    security_groups = [aws_security_group.service-security-group.id]
    from_port       = 2049
    protocol        = "TCP"
    to_port         = 2049
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "service-security-group" {
  name_prefix = "mod-service-security-group-"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = local.minecraft_server_config["port"]
    protocol    = local.minecraft_server_config["protocol"]
    to_port     = local.minecraft_server_config["port"]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  vpc_id = module.vpc.vpc_id
}

resource "aws_sns_topic" "server-notifications" {
  name_prefix  = "mod-server-notifications-topic-"
  display_name = "MOD Server Notifications"
}

resource "aws_sns_topic_policy" "server-notifications-topic-policy" {
  arn    = aws_sns_topic.server-notifications.arn
  policy = data.aws_iam_policy_document.server-notifications-topic-policy-document.json
}

resource "aws_sns_topic_subscription" "server-notifications-email-subscription" {
  count     = length(var.server_notifications_email_addresses)
  endpoint  = var.server_notifications_email_addresses[count.index]
  protocol  = "email"
  topic_arn = aws_sns_topic.server-notifications.arn
}

resource "random_id" "autoscaler-lambda-name" {
  byte_length = 5
  prefix      = "mod-autoscaler-"
}

resource "random_id" "cluster-name" {
  byte_length = 5
  prefix      = "mod-cluster-"
}

resource "random_id" "file-system-name" {
  byte_length = 5
  prefix      = "mod-file-system-"
}

resource "random_id" "file-system-access-point-name" {
  byte_length = 5
  prefix      = "mod-file-system-access-point-"
}

resource "random_id" "query-log-resource-policy-name" {
  byte_length = 5
  prefix      = "mod-query-log-resource-policy-"
}

resource "random_id" "query-log-subscription-filter-name" {
  byte_length = 5
  prefix      = "mod-query-log-sub-filter-"
}

resource "random_id" "service-name" {
  byte_length = 5
  prefix      = "mod-service-"
}

resource "random_id" "task-definition-family" {
  byte_length = 5
  prefix      = "mod-task-definition-"
}
