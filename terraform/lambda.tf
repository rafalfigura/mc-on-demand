
data "archive_file" "lambda_zip" {
  type = "zip"
  source_content = file("${path.module}/../lambda/lambda_function.py")
  source_content_filename = "lambda_function.py"
  output_path             = "${path.module}/../lambda/lambda_function.zip"
}

resource "aws_lambda_function" "autoscaler_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.name}-mc-on-demand-autoscaler-lambda"
  handler          = "lambda_function.handler"
  provider         = aws.us-east-1
  role             = aws_iam_role.autoscaler-lambda-role.arn
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

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
  function_name = aws_lambda_function.autoscaler_lambda.function_name
  principal     = "logs.us-east-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.query-log-group.arn}:*"
}