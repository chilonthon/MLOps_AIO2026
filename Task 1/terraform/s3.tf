# Raw data bucket (for CSV uploads)
resource "aws_s3_bucket" "raw_bucket" {
  bucket = local.raw_bucket_name
}

resource "aws_s3_bucket_versioning" "raw_bucket_versioning" {
  bucket = aws_s3_bucket.raw_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

# Processed data bucket (for Lambda output JSON)
resource "aws_s3_bucket" "processed_bucket" {
  bucket = local.processed_bucket_name
}

resource "aws_s3_bucket_versioning" "processed_bucket_versioning" {
  bucket = aws_s3_bucket.processed_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

# DBT artifacts bucket (for dbt manifest/logs)
resource "aws_s3_bucket" "dbt_artifacts_bucket" {
  bucket = local.dbt_artifacts_bucket
}

resource "aws_s3_bucket_versioning" "dbt_artifacts_versioning" {
  bucket = aws_s3_bucket.dbt_artifacts_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

# S3 event notification for Lambda trigger
resource "aws_s3_bucket_notification" "raw_bucket_notification" {
  bucket      = aws_s3_bucket.raw_bucket.id
  depends_on  = [aws_lambda_permission.s3_invoke]

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# Lambda permission for S3
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw_bucket.arn

  # Floci specific: Allow source account
  source_account = "000000000000"
}