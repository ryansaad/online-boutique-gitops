# Backend configuration — stores Terraform state in S3
# This means your infrastructure state is saved remotely
# so it doesn't get lost if you switch machines
#
# IMPORTANT: Create this S3 bucket manually in AWS console first
# before running terraform init
# Bucket name must be globally unique — change YOUR_BUCKET_NAME below

terraform {
  backend "s3" {
    bucket = "ryansaad-online-boutique-tfstate"
    key    = "online-boutique/terraform.tfstate"
    region = "us-east-1"
  }
}