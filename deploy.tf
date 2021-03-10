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
  name          = "${var.prefix}-events"
  tags          = var.tags
}

#resource "aws_sns_topic" "commit" {
#  name = "${prefix}-commit"
#  tags = var.tag
#}
#resource "aws_cloudwatch_event_target" "deploy" {
#  arn  = aws_sns_topic.container_status.arn
#  rule = aws_cloudwatch_event_rule.commit.name
#
#}
resource "aws_cloudwatch_event_target" "deploy" {
  #arn  = aws_sns_topic.container_status.arn
  arn  = aws_lambda_function.lambda_container_status.arn
  rule = aws_cloudwatch_event_rule.commit.name

}
#resource "aws_sns_topic_policy" "container_status_policy" {
#  arn = aws_sns_topic.container_status.arn
#
#  policy = data.aws_iam_policy_document.sns_topic_access_policy.json
#}

#data "aws_iam_policy_document" "sns_topic_access_policy" {
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
#      aws_sns_topic.container_status.arn,
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
#      aws_sns_topic.container_status.arn,
#
#    ]
#  }
#}
resource "aws_lambda_function" "lambda_container_status" {
  filename      = "function.zip"
  function_name = "${var.prefix}-function-name"
  role          = local.role_arn_lambda
  handler       = "lambda_function.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("function.zip")

  runtime = "python3.8"

  environment {
    variables = {
      dummy = "dummy"
      #es_alias   = var.es_alias
      #es_cluster = var.es_cluster
      #es_host    = var.es_host
      #es_secret  = var.es_secret
      #es_user    = var.es_user

    }
  }
  tags = var.tag
}

#resource "aws_sns_topic_subscription" "send_container_status" {
#  topic_arn = aws_sns_topic.container_status.arn
#  protocol  = "lambda"
#  endpoint  = aws_lambda_function.lambda_container_status.arn
#}
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_container_status.function_name}"
  retention_in_days = var.retention_in_days
  tags              = var.tag
}

#resource "aws_lambda_permission" "with_sns" {
#  statement_id  = "AllowExecutionFromSNS"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.lambda_container_status.function_name
#  principal     = "sns.amazonaws.com"
#  source_arn    = aws_sns_topic.container_status.arn
#}
