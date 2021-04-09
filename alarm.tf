resource "aws_cloudwatch_metric_alarm" "lambda_error" {
  alarm_name                = "${var.prefix}-events-error"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "Errors"
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
    sid="Allow_Publish_Alarms"
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
