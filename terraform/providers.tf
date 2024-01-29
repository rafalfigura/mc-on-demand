provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}
// This provider is used for aws_route53_query_log
// which is only supported in us-east-1
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_query_log
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

  default_tags {
    tags = local.tags
  }
}