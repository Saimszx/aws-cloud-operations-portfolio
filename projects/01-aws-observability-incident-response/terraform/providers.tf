provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

data "aws_caller_identity" "current" {}

locals {
  project_name = "aws-observability-incident-response"
  name_prefix  = "${local.project_name}-${var.environment}"

  common_tags = {
    Project     = local.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Saimszx"
    Purpose     = "PortfolioLearning"
  }
}
