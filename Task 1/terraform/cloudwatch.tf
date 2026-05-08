# Lambda errors alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.lambda_function_name}-errors"
  alarm_description   = "Alert when Lambda errors occur"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.processor.function_name
  }

  # Floci may not fully support alarms
  lifecycle {
    ignore_changes = [alarm_actions]
  }
}

# Lambda duration alarm
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.lambda_function_name}-duration"
  alarm_description   = "Alert when Lambda duration exceeds 120 seconds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 120000
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.processor.function_name
  }

  lifecycle {
    ignore_changes = [alarm_actions]
  }
}