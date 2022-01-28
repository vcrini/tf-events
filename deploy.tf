resource "aws_cloudwatch_event_rule" "commit" {
  description   = "Launch a build on a commit"
  event_pattern = <<PATTERN
  {
  "source": [
    "aws.codecommit"
  ],
  "detail-type": [
    "CodeCommit Repository State Change"
  ],
  "detail": {
    "event": [
      "referenceCreated",
      "referenceUpdated"
    ],
    "repositoryName": [{
      "prefix" : "${var.prefix}"
    }
    ],
    "referenceType": [
      "branch"
    ]
  }
}
PATTERN
  name          = "${var.prefix}-${var.deploy_environment}-events"
  tags          = var.tag
}

resource "aws_sns_topic" "commit" {
  name = "${var.prefix}-${var.deploy_environment}-commit"
  tags = var.tag
}
resource "aws_cloudwatch_event_target" "deploy" {
  arn  = aws_sns_topic.commit.arn
  rule = aws_cloudwatch_event_rule.commit.name

}
resource "aws_sns_topic_policy" "container_status_policy" {
  arn = aws_sns_topic.commit.arn

  policy = data.aws_iam_policy_document.sns_topic_access_policy.json
}

data "aws_iam_policy_document" "sns_topic_access_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        local.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.commit.arn,

    ]

    sid = "__default_statement_ID"
  }
  statement {
    actions = [
      "sns:Publish",
    ]
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.commit.arn,

    ]
  }
}
resource "aws_lambda_function" "lambda_commit" {

  environment {
    variables = {
      cluster_dev   = var.cluster_dev
      cluster_prod  = var.cluster_prod
      test_role_arn = var.test_role_arn

    }
  }

  filename      = "function.zip"
  function_name = "${var.prefix}-${var.deploy_environment}-pipeline-launcher"
  handler       = "lambda_function.handler"
  # 0 disables
  reserved_concurrent_executions = 1
  role                           = local.role_arn_lambda
  runtime                        = "python3.8"
  source_code_hash               = filebase64sha256("function.zip")
  tags                           = var.tag
}

resource "aws_sns_topic_subscription" "send_container_status" {
  topic_arn = aws_sns_topic.commit.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_commit.arn
}
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_commit.function_name}"
  retention_in_days = var.retention_in_days
  tags              = var.tag
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_commit.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.commit.arn
}

resource "aws_cloudwatch_metric_alarm" "lambda_error" {
  alarm_name          = "${var.prefix}-events-error"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  # metric_name               = "Invocations"
  namespace                 = "AWS/Lambda"
  period                    = "60"
  threshold                 = "1"
  unit                      = "Count"
  alarm_description         = "Raised when lambda fails with error"
  insufficient_data_actions = []
  statistic                 = "Maximum"
  dimensions = {
    FunctionName = aws_lambda_function.lambda_commit.function_name
  }
  alarm_actions = [aws_sns_topic.lambda_error.arn]
}
resource "aws_sns_topic" "lambda_error" {
  name = "${var.prefix}-events-error"
  tags = var.tag
}
resource "aws_sns_topic_policy" "lambda_error_policy" {
  arn = aws_sns_topic.lambda_error.arn

  policy = data.aws_iam_policy_document.sns_lambda_error_access_policy.json
}

#data "aws_iam_policy_document" "sns_lambda_error_access_policy" {
#  policy_id = "__default_policy_ID"
#
#  statement {
#    actions = [
#      "SNS:GetTopicAttributes",
#      "SNS:SetTopicAttributes",
#      "SNS:AddPermission",
#      "SNS:RemovePermission",
#      "SNS:DeleteTopic",
#      "SNS:Subscribe",
#      "SNS:ListSubscriptionsByTopic",
#      "SNS:Publish",
#      "SNS:Receive"
#    ]
#
#    condition {
#      test     = "StringEquals"
#      variable = "AWS:SourceOwner"
#
#      values = [
#        local.account_id,
#      ]
#    }
#
#    effect = "Allow"
#
#    principals {
#      type        = "AWS"
#      identifiers = ["*"]
#    }
#
#    resources = [
#      aws_cloudwatch_metric_alarm.lambda_error.arn,
#
#    ]
#
#    sid = "__default_statement_ID"
#  }
#  statement {
#    actions = [
#      "sns:Publish",
#    ]
#    effect = "Allow"
#
#    principals {
#      type        = "Service"
#      identifiers = ["events.amazonaws.com"]
#    }
#
#    resources = [
#      aws_cloudwatch_metric_alarm.lambda_error.arn,
#    ]
#  }
#}
data "aws_iam_policy_document" "sns_lambda_error_access_policy" {
  policy_id = "__default_policy_ID"

  statement {
    sid    = "Allow_Publish_Alarms"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    resources = [
      aws_sns_topic.lambda_error.arn
    ]
    actions = [
      "sns:Publish",
    ]


  }
}
resource "aws_lambda_function" "error_parser" {
  environment {
    variables = {
      snsARN = aws_sns_topic.lambda_error.arn
    }
  }
  filename      = "error_parser.zip"
  function_name = "${var.prefix}-${var.deploy_environment}-deploy-error-parser"
  handler       = "lambda_function.handler"
  # 0 disables
  reserved_concurrent_executions = 1
  role                           = local.role_arn_lambda
  runtime                        = "python3.8"
  source_code_hash               = filebase64sha256("error_parser.zip")
  tags                           = var.tag
}

resource "aws_cloudwatch_log_subscription_filter" "error_parser_logfilter" {
  name            = "${var.prefix}-${var.deploy_environment}-error-parser-logfilter"
  log_group_name  = "/aws/lambda/${aws_lambda_function.lambda_commit.function_name}"
  filter_pattern  = "ERROR"
  destination_arn = aws_lambda_function.error_parser.arn
  depends_on = [
    aws_lambda_permission.allow_cloudwatch_for_error_parser
  ]
}

resource "aws_lambda_permission" "allow_cloudwatch_for_error_parser" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.error_parser.function_name
  principal     = "logs.${local.region}.amazonaws.com"
}
