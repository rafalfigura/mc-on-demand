variable "aws_region" {
  default     = "us-east-1"
  description = "The AWS region."
  nullable    = false
  type        = string
}

variable "domain_name" {
  description = "The domain name."
  type        = string
}

variable "name" {
    default     = "minecraft"
    description = "The name of the Minecraft On Demand server"
    type        = string
}

# Budget variables
variable "budget_enabled" {
    default     = false
    description = "Enable budget for the Minecraft server."
    type        = bool
}

variable "budget_amount" {
    default     = 5
    description = "The amount of the budget in $USD."
    type        = number
}
variable "budget_notification_emails" {
    default     = []
    description = "The email addresses to send budget notifications to."
    type        = list(string)
}


// TO BE REMOVED (or not)
variable "fargate_spot_pricing" {
  default     = false
  description = "Use Fargate Spot pricing if set to true."
  type        = bool
}

variable "minecraft_edition" {
  default = "java"
  type    = string

  validation {
    condition     = contains(["java", "bedrock"], var.minecraft_edition)
    error_message = "Valid values for `minecraft_edition`: `java`, `bedrock`"
  }
}

variable "minecraft_image_bedrock" {
  default = "itzg/minecraft-bedrock-server"
  type    = string
}

variable "minecraft_image_java" {
  default = "itzg/minecraft-server"
  type    = string
}

variable "server_debug" {
  default     = false
  description = "Setting to `true` enables debug mode, which enables cloudwatch logs for the server containers."
  type        = bool
}

variable "server_cpu_units" {
  default     = 1024
  description = "The number of cpu units used by the task running the Minecraft server."
  type        = number
}

variable "server_environment_variables" {
  default     = []
  description = "A list of environment variable keys and values passed on to the server container. e.g. [{ name = ..., value = ... }]"
  nullable    = false
  type        = list(map(string))
}

variable "server_memory" {
  default     = 2048
  description = "The amount (in MiB) of memory used by the task running the Minecraft server."
  type        = number
}

variable "server_shutdown_time" {
  default     = 20
  description = "Number of minutes to wait after the last client disconnects before terminating."
  type        = number
}

variable "server_startup_time" {
  default     = 10
  description = "Number of minutes to wait for a connection after starting before terminating."
  type        = number
}

variable "server_notifications_email_addresses" {
  default     = []
  description = "Email addresses to send server notifications to."
  type        = list(string)
}


variable "tags" {
  default     = {}
  description = "The resource tags."
  nullable    = false
  type        = map(string)
}

variable "vpc_id" {
  default     = null
  description = "The VPC id."
  type        = string
}

variable "vpc_public_subnet_tag_name" {
  default     = "tier"
  description = "The name/key of the tag to be used for searching for public subnets for the VPC."
  type        = string
}

variable "vpc_public_subnet_tag_value" {
  default     = "public"
  description = "The value of the tag to be used for searching for public subnets for the VPC."
  type        = string
}

variable "vpc_isolated_subnet_tag_name" {
  default     = "tier"
  description = "The name/key of the tag to be used for searching for isolated subnets for the VPC."
  type        = string
}

variable "vpc_isolated_subnet_tag_value" {
  default     = "isolated"
  description = "The value of the tag to be used for searching for isolated subnets for the VPC."
  type        = string
}
