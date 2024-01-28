variable "aws_region" {
  default     = "us-east-1"
  description = "The AWS region."
  nullable    = false
  type        = string
}

variable "vpc_id" {
  default     = null
  description = "The VPC id."
  type        = string
}

variable "vpc_public_subnet_tag_name" {
  description = "The name/key of the tag to be used for searching for public subnets for the VPC."
  type        = string
}

variable "vpc_public_subnet_tag_value" {
  description = "The value of the tag to be used for searching for public subnets for the VPC."
  type        = string
}

variable "vpc_isolated_subnet_tag_name" {
  description = "The name/key of the tag to be used for searching for isolated subnets for the VPC."
  type        = string
}

variable "vpc_isolated_subnet_tag_value" {
  description = "The value of the tag to be used for searching for isolated subnets for the VPC."
  type        = string
}
