# Terraform Infrastructure for 5G Network Quality Pipeline

## ⚠️ IMPORTANT: Floci Environment (NOT Production AWS)

**This Terraform configuration is designed for Floci, a local AWS simulator, NOT for real AWS production environments.**

All endpoints, credentials, and settings are configured to work with a local Floci instance running at `100.89.222.12:4566` (or `aws.home:4566`).

---

## Overview

This Terraform setup automates the deployment of the 5G network quality data processing pipeline, including:

- **S3 Buckets**: Raw data input, processed output, and dbt artifacts storage
- **Lambda Function**: Processes CSV uploads with Pydantic validation and dbt transformations
- **Lambda Layer**: Python dependencies (pydantic, dbt-duckdb, pandas, boto3)
- **IAM Roles & Policies**: Least-privilege access for Lambda to S3
- **CloudWatch Logs & Alarms**: Monitoring and error detection
- **S3 Event Triggers**: Automatic Lambda invocation on file uploads

---

## Quick Start (Floci)

### Prerequisites

1. **Floci Running**: Ensure Floci is accessible at `100.89.222.12:4566` (or `aws.home:4566`)
2. **Terraform Installed**: Version >= 1.0
3. **AWS CLI Installed**: For validation and testing
4. **Lambda Code Ready**:
   - `garbo-lambda.zip` - Lambda function code
   - `lambda-layer.zip` - Python dependencies layer

### Deployment Steps

```bash
# 1. Initialize Terraform with local backend
terraform init

# 2. Review planned changes
terraform plan

# 3. Apply configuration to Floci
terraform apply

# 4. View outputs
terraform output
```

### Verify Deployment

```bash
# List created S3 buckets (Floci endpoint)
aws --endpoint-url=http://100.89.222.12:4566 s3 ls

# List Lambda functions
aws --endpoint-url=http://100.89.222.12:4566 lambda list-functions

# Invoke Lambda manually
aws --endpoint-url=http://100.89.222.12:4566 lambda invoke \
  --function-name garbo-data-processor \
  output.json
```

---

## Configuration Files

| File | Purpose |
|------|---------|
| `main.tf` | Provider setup with Floci endpoints & dummy credentials |
| `variables.tf` | Input variables (Floci host, port, Lambda config) |
| `terraform.tfvars` | Variable values (Floci: 100.89.222.12:4566) |
| `s3.tf` | S3 bucket definitions (raw, processed, dbt artifacts) |
| `iam.tf` | IAM roles and S3/Lambda permissions |
| `lambda.tf` | Lambda function & layer definitions |
| `cloudwatch.tf` | CloudWatch alarms (errors, duration) |
| `outputs.tf` | Terraform outputs (function name, bucket names, CLI commands) |
| `backend.tf` | State file storage (local or remote) |
| `.gitignore` | Files to exclude from version control |

---

## Floci-Specific Settings

### Provider Configuration

```hcl
provider "aws" {
  endpoints {
    s3       = "http://100.89.222.12:4566"
    lambda   = "http://100.89.222.12:4566"
    iam      = "http://100.89.222.12:4566"
    logs     = "http://100.89.222.12:4566"
    # ... other services
  }
  
  access_key                  = "test"  # Dummy credentials
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}
```

### Variables Override (terraform.tfvars)

```hcl
floci_host = "100.89.222.12"
floci_port = 4566
environment = "floci"
```

### Bucket Naming

- Floci uses account ID `000000000000`
- Bucket names: `garbo-raw-bucket`, `garbo-processed-bucket`, `garbo-dbt-artifacts`
- **No account ID suffix** (unlike production AWS)

---

## ⚠️ DEPLOYING TO REAL AWS: Required Changes

When you're ready to deploy to **actual AWS production**, you must change the following:

### 1. **Provider Configuration** (main.tf)

**Current (Floci):**
```hcl
provider "aws" {
  region = var.aws_region
  
  endpoints {
    s3 = "http://100.89.222.12:4566"
    # ... all Floci endpoints
  }
  
  access_key = "test"
  skip_credentials_validation = true
}
```

**Production AWS:**
```hcl
provider "aws" {
  region = var.aws_region
  # REMOVE all endpoints block
  # REMOVE skip_credentials_validation
  # Use real AWS credentials (via IAM role or environment variables)
}
```

### 2. **Variables** (variables.tf / terraform.tfvars)

**Current (Floci):**
```hcl
floci_host = "100.89.222.12"
floci_port = 4566
aws_access_key_id = "test"
aws_secret_access_key = "test"
environment = "floci"
```

**Production AWS:**
```hcl
# Remove floci_host and floci_port variables
# Use REAL AWS credentials (IAM role preferred)
# environment = "prod" or "staging"
# Add variables for actual AWS account ID, VPC, security groups
```

### 3. **S3 Bucket Naming** (s3.tf)

**Current (Floci):**
```hcl
bucket = local.raw_bucket_name  # "garbo-raw-bucket"
```

**Production AWS:**
```hcl
bucket = local.raw_bucket_name  # "garbo-raw-bucket-${data.aws_caller_identity.current.account_id}"
# Add bucket = "${var.project_name}-${var.environment}-bucket-${data.aws_caller_identity.current.account_id}"
# Name must be globally unique
```

### 4. **Security Groups & Network** (Add to production)

**Floci:** No network isolation needed

**Production AWS:** Add
```hcl
resource "aws_security_group" "lambda_sg" {
  # Define egress rules for S3 access
}

resource "aws_vpc_endpoint" "s3" {
  # Use VPC endpoints for S3 (no internet gateway needed)
}
```

### 5. **IAM Roles & Policies** (iam.tf)

**Current (Floci):** Simplified policies

**Production AWS:** Add
```hcl
# Add KMS encryption permissions
# Add VPC execution role
# Add resource-based policies for cross-account access
# Implement MFA requirements
# Add IP restrictions
```

### 6. **CloudWatch & Monitoring** (cloudwatch.tf)

**Current (Floci):**
```hcl
lifecycle {
  ignore_changes = [alarm_actions]
}
```

**Production AWS:** Remove ignore_changes and add:
```hcl
alarm_actions = [aws_sns_topic.alerts.arn]
# Configure SNS for real alerts
# Add email/Slack notifications
# Add custom metrics
```

### 7. **Lambda Configuration** (lambda.tf)

**Current (Floci):**
```hcl
timeout = 600
memory_size = 1024
lifecycle {
  ignore_changes = [source_code_hash]
}
```

**Production AWS:** Add
```hcl
# Use Secrets Manager for sensitive data
# Enable X-Ray tracing
# Add reserved concurrency limits
# Enable function URL if needed
# Add environment encryption
```

### 8. **State Management** (backend.tf)

**Current (Floci):**
```hcl
# Local backend (terraform.tfstate in repo)
```

**Production AWS:** Change to
```hcl
terraform {
  backend "s3" {
    bucket         = "your-org-terraform-state"
    key            = "5g-pipeline/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

### 9. **Variables & Outputs**

**Production AWS:** Add new variables
```hcl
variable "vpc_id" {}
variable "subnet_ids" {}
variable "kms_key_arn" {}
variable "notification_email" {}
variable "reserved_concurrency" {}
variable "log_retention_days" {}
```

---

## Testing Workflow (Floci)

1. **Create Lambda ZIP files:**
   ```bash
   # Create garbo-lambda.zip
   # Create lambda-layer.zip with dependencies
   ```

2. **Deploy to Floci:**
   ```bash
   terraform apply
   ```

3. **Upload sample CSV:**
   ```bash
   aws --endpoint-url=http://100.89.222.12:4566 s3 cp sample.csv s3://garbo-raw-bucket/
   ```

4. **Check Lambda logs:**
   ```bash
   aws --endpoint-url=http://100.89.222.12:4566 logs tail /aws/lambda/garbo-data-processor --follow
   ```

5. **Verify output:**
   ```bash
   aws --endpoint-url=http://100.89.222.12:4566 s3 ls s3://garbo-processed-bucket/
   ```

---

## Troubleshooting

### "Cannot connect to Floci"
```bash
# Verify Floci is running
curl http://100.89.222.12:4566

# Check firewall/network access
ping 100.89.222.12
```

### "Bucket already exists"
```bash
# Floci may retain buckets from previous runs
aws --endpoint-url=http://100.89.222.12:4566 s3 rm s3://garbo-raw-bucket --recursive
aws --endpoint-url=http://100.89.222.12:4566 s3 rb s3://garbo-raw-bucket
```

### Lambda invocation fails
```bash
# Check Lambda logs
terraform output | grep logs-command

# Verify Lambda has S3 permissions
terraform output lambda_role_arn
```

---

## Cleanup (Floci)

To remove all resources from Floci:

```bash
terraform destroy
```

---

## Migration from Floci to AWS

When ready for production:

1. **Create new Terraform workspace** for AWS:
   ```bash
   terraform workspace new aws-prod
   ```

2. **Update provider configuration** (remove Floci endpoints)

3. **Update terraform.tfvars** for real AWS account

4. **Add VPC, security groups, KMS encryption**

5. **Import existing resources** (if any):
   ```bash
   terraform import aws_s3_bucket.raw_bucket my-actual-bucket-name
   ```

6. **Plan and review**:
   ```bash
   terraform plan
   ```

7. **Deploy to AWS**:
   ```bash
   terraform apply
   ```

---

## References

- [Floci Documentation](https://github.com/localstack/localstack)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [dbt Documentation](https://docs.getdbt.com/)
