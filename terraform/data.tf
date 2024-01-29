

data "aws_caller_identity" "current" {}

data "aws_iam_policy" "autoscaler-lambda-basic-execution-policy" {
  name     = "AWSLambdaBasicExecutionRole"
  provider = aws.us-east-1
}


data "aws_iam_policy" "task-execution-policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "autoscaler-lambda-policy-document" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "file-system-policy-document" {
  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:DescribeFileSystems",
    ]
    effect    = "Allow"
    resources = [aws_efs_file_system.file-system.arn]

    condition {
      test     = "StringEquals"
      values   = [aws_efs_access_point.file-system-access-point.arn]
      variable = "elasticfilesystem:AccessPointArn"
    }
  }
}

data "aws_iam_policy_document" "hosted-zone-policy-document" {
  statement {
    actions = [
      "route53:GetHostedZone",
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    effect    = "Allow"
    //noinspection HILUnresolvedReference
    resources = [aws_route53_zone.hosted-zone.arn]
  }

  statement {
    actions = ["logs:*"]
    effect  = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "query-log-group-policy-document" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.query-log-group.arn}/*",
      "*"
    ]

    principals {
      type        = "Service"
      identifiers = ["route53.amazonaws.com"]
    }
  }

}


data "aws_iam_policy_document" "server-notifications-policy-document" {
  statement {
    actions   = ["sns:Publish"]
    effect    = "Allow"
    resources = [aws_sns_topic.server-notifications.arn]
  }
}

data "aws_iam_policy_document" "server-notifications-topic-policy-document" {
  statement {
    actions = ["sns:Publish"]
    effect  = "Allow"

    resources = [aws_sns_topic.server-notifications.arn]

    principals {
      identifiers = [aws_iam_role.task-definition-role.arn]
      type        = "AWS"
    }
  }
}

data "aws_iam_policy_document" "service-policy-document" {
  statement {
    actions   = ["ecs:*"]
    effect    = "Allow"
    resources = [
      "arn:aws:ecs:${var.aws_region}:${local.aws_account_id}:service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service.name}",
      "arn:aws:ecs:${var.aws_region}:${local.aws_account_id}:task/${aws_ecs_cluster.cluster.name}/*"
    ]
  }

  statement {
    actions   = ["ec2:DescribeNetworkInterfaces"]
    effect    = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "task-definition-assume-role-policy-document" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}
