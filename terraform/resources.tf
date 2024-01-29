resource "aws_cloudwatch_log_group" "server-log-group" {
  name       = "${local.name_prefix}-server"
  retention_in_days = local.log_retention_in_days
}

resource "aws_cloudwatch_log_group" "watchdog-log-group" {
  name = "${local.name_prefix}-watchdog"
  retention_in_days = local.log_retention_in_days
}

resource "aws_cloudwatch_log_resource_policy" "query-log-resource-policy" {
  provider        = aws.us-east-1
  policy_document = data.aws_iam_policy_document.query-log-group-policy-document.json
  policy_name     = local.name_prefix
}

resource "aws_cloudwatch_log_subscription_filter" "query-log-subscription-filter" {
  provider        = aws.us-east-1
  depends_on      = [aws_lambda_permission.allow_cloudwatch]
  destination_arn = aws_lambda_function.autoscaler_lambda.arn
  filter_pattern  = local.subdomain
  log_group_name  = aws_cloudwatch_log_group.query-log-group.name
  name = "${local.name_prefix}-subscription-filter"
}


resource "aws_iam_policy" "service-policy" {
  name       = "${local.name_prefix}-service-policy"
  policy      = data.aws_iam_policy_document.service-policy-document.json
}

resource "aws_iam_policy" "file-system-policy" {
  name       = "${local.name_prefix}-file-system-policy"
  policy      = data.aws_iam_policy_document.file-system-policy-document.json
}

resource "aws_iam_policy" "hosted-zone-policy" {
    name       = "${local.name_prefix}-hosted-zone-policy"
  policy      = data.aws_iam_policy_document.hosted-zone-policy-document.json
}

resource "aws_iam_policy" "server-notifications-policy" {
    name       = "${local.name_prefix}-server-notifications-policy"
  policy      = data.aws_iam_policy_document.server-notifications-policy-document.json
}

resource "aws_iam_role" "autoscaler-lambda-role" {
  provider           = aws.us-east-1
  assume_role_policy = data.aws_iam_policy_document.autoscaler-lambda-policy-document.json
  name = "${local.name_prefix}-autoscaler-lambda-role"
}

resource "aws_iam_role" "task-definition-role" {
  assume_role_policy = data.aws_iam_policy_document.task-definition-assume-role-policy-document.json
    name = "${local.name_prefix}-task-definition-role"
}

resource "aws_iam_role" "task-execution-role" {
  assume_role_policy = data.aws_iam_policy_document.task-definition-assume-role-policy-document.json
  name = "${local.name_prefix}-task-execution-role"
}

resource "aws_iam_role_policy_attachment" "autoscaler-lambda-basic-execution-policy-attachment" {
  provider   = aws.us-east-1
  policy_arn = data.aws_iam_policy.autoscaler-lambda-basic-execution-policy.arn
  role       = aws_iam_role.autoscaler-lambda-role.name
}

resource "aws_iam_role_policy_attachment" "autoscaler-lambda-cluster-policy-attachment" {
  provider   = aws.us-east-1
  policy_arn = aws_iam_policy.service-policy.arn
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

resource "aws_sns_topic" "server-notifications" {
  name ="${local.name_prefix}-server-notifications"
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

