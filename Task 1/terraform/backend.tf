# Uncomment to use S3 remote backend
# terraform {
#   backend "s3" {
#     bucket         = "my-terraform-state-bucket"
#     key            = "garbo/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-locks"
#   }
# }