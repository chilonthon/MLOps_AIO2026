terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region      = var.aws_region
  
  # Floci endpoints - all services route through the same endpoint
  endpoints {
    s3           = "http://${var.floci_host}:${var.floci_port}"
    lambda       = "http://${var.floci_host}:${var.floci_port}"
    iam          = "http://${var.floci_host}:${var.floci_port}"
    cloudwatch   = "http://${var.floci_host}:${var.floci_port}"
    logs         = "http://${var.floci_host}:${var.floci_port}"
    dynamodb     = "http://${var.floci_host}:${var.floci_port}"
    sqs          = "http://${var.floci_host}:${var.floci_port}"
    sns          = "http://${var.floci_host}:${var.floci_port}"
  }

  # Floci dummy credentials
  access_key                  = var.aws_access_key_id
  secret_key                  = var.aws_secret_access_key
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Platform    = "Floci"
    }
  }
}

locals {
  lambda_function_name  = "${var.project_name}-data-processor"
  lambda_role_name      = "${var.project_name}-lambda-role"
  lambda_layer_name     = "${var.project_name}-dependencies"
  raw_bucket_name       = "${var.project_name}-raw-bucket"
  processed_bucket_name = "${var.project_name}-processed-bucket"
  dbt_artifacts_bucket  = "${var.project_name}-dbt-artifacts"
}

# Floci connectivity verification
resource "null_resource" "floci_check" {
  provisioner "local-exec" {
    command = "Write-Host 'Floci endpoint: http://${var.floci_host}:${var.floci_port}'"
  }
}