

resource "aws_cloudwatch_log_group" "server-log-group" {
  name_prefix       = "${var.name}-mc-on-demand-server"
  retention_in_days = local.log_retention_in_days
}

resource "aws_cloudwatch_log_group" "watchdog-log-group" {
  name_prefix       = "${var.name}-mc-on-demand-watchdog"
  retention_in_days = local.log_retention_in_days
}

resource "aws_cloudwatch_log_resource_policy" "query-log-resource-policy" {
  policy_document = data.aws_iam_policy_document.query-log-group-policy-document.json
  policy_name     = "${var.name}-query-log-resource-policy"
  provider        = aws.us-east-1
}

resource "aws_cloudwatch_log_subscription_filter" "query-log-subscription-filter" {
  provider        = aws.us-east-1
  depends_on      = [aws_lambda_permission.allow_cloudwatch]
  destination_arn = aws_lambda_function.autoscaler_lambda.arn
  filter_pattern  = local.subdomain
  log_group_name  = aws_cloudwatch_log_group.query-log-group.name
  name            = "${var.name}-query-log-subscription-filter"
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
