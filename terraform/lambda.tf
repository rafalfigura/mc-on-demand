
resource "aws_lambda_function" "autoscaler-lambda" {
  filename         = data.archive_file.autoscaler-lambda.output_path
  function_name    = random_id.autoscaler-lambda-name.dec
  handler          = "lambda_function.handler"
  provider         = aws.us-east-1
  role             = aws_iam_role.autoscaler-lambda-role.arn
  runtime          = "python3.8"
  source_code_hash = data.archive_file.autoscaler-lambda.output_base64sha256

  environment {
    variables = {
      CLUSTER = local.ecs_cluster_name
      REGION  = var.aws_region
      SERVICE = local.ecs_service_name
    }
  }
}

// missing Route53LogsToCloudWatchLogs policy in route53 hosted zonee
resource "aws_lambda_permission" "allow_cloudwatch" {
  provider      = aws.us-east-1
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.autoscaler-lambda.function_name
  principal     = "logs.us-east-1.amazonaws.com"
  source_arn    = format("%s:*", aws_cloudwatch_log_group.query-log-group.arn)
}