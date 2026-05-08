output "floci_endpoint" {
  description = "Floci endpoint URL"
  value       = "http://${var.floci_host}:${var.floci_port}"
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.processor.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.processor.arn
}

output "raw_bucket_name" {
  description = "Raw data S3 bucket name"
  value       = aws_s3_bucket.raw_bucket.id
}

output "processed_bucket_name" {
  description = "Processed data S3 bucket name"
  value       = aws_s3_bucket.processed_bucket.id
}

output "dbt_artifacts_bucket_name" {
  description = "DBT artifacts S3 bucket name"
  value       = aws_s3_bucket.dbt_artifacts_bucket.id
}

output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_layer_arn" {
  description = "Lambda layer ARN"
  value       = aws_lambda_layer_version.dependencies.arn
}

output "aws_cli_commands" {
  description = "Useful AWS CLI commands for Floci testing"
  value = {
    list_buckets = "aws --endpoint-url=http://${var.floci_host}:${var.floci_port} s3 ls"
    invoke_lambda = "aws --endpoint-url=http://${var.floci_host}:${var.floci_port} lambda invoke --function-name ${aws_lambda_function.processor.function_name} output.json"
    view_logs = "aws --endpoint-url=http://${var.floci_host}:${var.floci_port} logs tail /aws/lambda/${aws_lambda_function.processor.function_name} --follow"
  }
}