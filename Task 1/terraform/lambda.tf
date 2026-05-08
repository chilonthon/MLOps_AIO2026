# Lambda layer for dependencies
resource "aws_lambda_layer_version" "dependencies" {
  filename            = var.lambda_layer_zip_path
  layer_name          = local.lambda_layer_name
  compatible_runtimes = [var.lambda_runtime]

  source_code_hash = filebase64sha256(var.lambda_layer_zip_path)

  lifecycle {
    ignore_changes = [source_code_hash]
  }
}

# Lambda function
resource "aws_lambda_function" "processor" {
  filename      = var.lambda_zip_path
  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  source_code_hash = filebase64sha256(var.lambda_zip_path)

  layers = [aws_lambda_layer_version.dependencies.arn]

  environment {
    variables = {
      RAW_BUCKET       = aws_s3_bucket.raw_bucket.id
      PROCESSED_BUCKET = aws_s3_bucket.processed_bucket.id
      DBT_ARTIFACTS    = aws_s3_bucket.dbt_artifacts_bucket.id
      FLOCI_HOST       = var.floci_host
      FLOCI_PORT       = var.floci_port
      DEBUG            = var.enable_logging ? "true" : "false"
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_logs_policy,
    aws_iam_role_policy.lambda_s3_policy
  ]

  lifecycle {
    ignore_changes = [source_code_hash]
  }

  # Timeout for Floci (can be slow)
  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

# Lambda log group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.processor.function_name}"
  retention_in_days = 1

  depends_on = [aws_lambda_function.processor]
}

# Lambda permission for manual invocation
resource "aws_lambda_permission" "allow_manual_invoke" {
  statement_id  = "AllowManualInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "*"
}