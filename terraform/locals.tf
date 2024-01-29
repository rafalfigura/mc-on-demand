locals {
  aws_account_id = data.aws_caller_identity.current.account_id

  default_server_environment_variables = [{ name = "EULA", value = "TRUE" }]

  ecs_cluster_name = "${var.name}-mc-on-demand-ecs-cluster"
  ecs_service_name = "${var.name}-mc-on-demand-ecs-service"
  ecs_volume_name  = "data"

  efs_gid = 1000
  efs_uid = 1000

  server_environment_variables = concat(local.default_server_environment_variables, var.server_environment_variables)

  minecraft_server_config             = local.minecraft_server_configs_by_edition[var.minecraft_edition]
  minecraft_server_configs_by_edition = {
    "java" = {
      image    = var.minecraft_image_java
      port     = 25565
      protocol = "TCP"
    }
    "bedrock" = {
      image    = var.minecraft_image_bedrock
      port     = 19132
      protocol = "UDP"
    }
  }

  provisioned_vpc_enabled = var.vpc_id != null
  subdomain               = "${var.name}.${var.domain_name}"

  tags = merge(local.tags, {
    "mc-on-demand" = local.subdomain
  })

  minecraft_server_container_name = "minecraft-server"
  watchdog_server_container_name = "watchdog-server"

  log_retention_in_days = 3
  name_prefix           = "${var.name}-mc-on-demand"
}
