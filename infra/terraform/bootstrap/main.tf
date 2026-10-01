# Run ONCE, before everything else (stage 4, step 1).
# Creates the S3 bucket that stores Terraform state for every other env, plus
# a billing alert so a forgotten cluster doesn't surprise you.
#
#   cd infra/terraform/bootstrap
#   terraform init && terraform apply -var="alert_email=you@example.com"
#
# This config's own state stays local (terraform.tfstate here, git-ignored) -
# the classic chicken-and-egg of remote state. Keep a backup of that file.

terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "eu-west-2" # London
}

variable "alert_email" {
  type        = string
  description = "Where to send billing alerts"
}

variable "monthly_budget_usd" {
  type    = number
  default = 30
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tf_state" {
  # Bucket names are global, so include the account ID to make it unique.
  bucket = "job-tracker-tfstate-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }
}

# Versioning lets you recover a previous state file if one gets corrupted.
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_budgets_budget" "monthly" {
  name         = "job-tracker-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

output "state_bucket" {
  value = aws_s3_bucket.tf_state.bucket
}
