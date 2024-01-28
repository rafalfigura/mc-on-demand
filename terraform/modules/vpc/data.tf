data "aws_vpc" "provisioned-vpc" {
  count = local.provisioned_vpc_enabled ? 1 : 0
  id    = var.vpc_id
}

data "aws_subnets" "provisioned-isolated-subnets" {
  count = local.provisioned_vpc_enabled ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    "${var.vpc_isolated_subnet_tag_name}" = "${var.vpc_isolated_subnet_tag_value}"
  }
}

data "aws_subnets" "provisioned-public-subnets" {
  count = local.provisioned_vpc_enabled ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    "${var.vpc_public_subnet_tag_name}" = "${var.vpc_public_subnet_tag_value}"
  }
}
