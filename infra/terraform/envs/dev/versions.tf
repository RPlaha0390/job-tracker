terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }

  # Remote state in the bucket created by ../../bootstrap.
  # use_lockfile gives S3-native locking (Terraform 1.10+), so two applies
  # can't run at once - no DynamoDB table needed any more.
  backend "s3" {
    bucket       = "job-tracker-tfstate-ACCOUNT_ID" # TODO: bootstrap output
    key          = "envs/dev/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "job-tracker"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
