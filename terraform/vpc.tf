module "vpc" {
  source = "./modules/vpc"

  aws_region                    = var.aws_region
  vpc_id                        = var.vpc_id
  vpc_public_subnet_tag_name    = var.vpc_public_subnet_tag_name
  vpc_public_subnet_tag_value   = var.vpc_public_subnet_tag_value
  vpc_isolated_subnet_tag_name  = var.vpc_isolated_subnet_tag_name
  vpc_isolated_subnet_tag_value = var.vpc_isolated_subnet_tag_value
}


resource "aws_security_group" "file-system-security-group" {
  name = "${local.name_prefix}-file-system-security-group"

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
  name = "${local.name_prefix}-service-security-group"

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