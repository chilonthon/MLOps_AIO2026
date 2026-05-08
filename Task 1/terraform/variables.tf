# Floci Configuration
variable "floci_host" {
  description = "Floci hostname or IP address"
  type        = string
  default     = "100.89.222.12"
}

variable "floci_port" {
  description = "Floci port"
  type        = number
  default     = 4566
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region (Floci default)"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key_id" {
  description = "AWS Access Key (dummy for Floci)"
  type        = string
  default     = "test"
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Key (dummy for Floci)"
  type        = string
  default     = "test"
  sensitive   = true
}

# Project Configuration
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "garbo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "floci"
}

# Lambda Configuration
variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 600
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 1024
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

# Lambda Code Paths
variable "lambda_zip_path" {
  description = "Path to Lambda function ZIP file"
  type        = string
  default     = "garbo-lambda.zip"
}

variable "lambda_layer_zip_path" {
  description = "Path to Lambda layer ZIP file"
  type        = string
  default     = "lambda-layer.zip"
}

# Feature Flags
variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable detailed logging"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}