module "vpc" {
  source = "./modules/vpc"

  aws_region                    = var.aws_region
  vpc_id                        = var.vpc_id
  vpc_public_subnet_tag_name    = var.vpc_public_subnet_tag_name
  vpc_public_subnet_tag_value   = var.vpc_public_subnet_tag_value
  vpc_isolated_subnet_tag_name  = var.vpc_isolated_subnet_tag_name
  vpc_isolated_subnet_tag_value = var.vpc_isolated_subnet_tag_value
}
