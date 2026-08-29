variable "aws_region" {
  description = "AWS Region used for the lab."
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Short environment name used in resource names and tags."
  type        = string
  default     = "lab"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "The environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block assigned to the lab VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block assigned to the public subnet."
  type        = string
  default     = "10.20.10.0/24"
}

variable "allowed_http_cidr" {
  description = "IPv4 range allowed to reach the demonstration web page."
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type. Confirm current Free Tier eligibility before deployment."
  type        = string
  default     = "t3.micro"
}

variable "notification_email" {
  description = "Optional email endpoint for SNS alarm notifications. The recipient must confirm the subscription."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.notification_email == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.notification_email))
    error_message = "Provide a valid email address or leave notification_email as null."
  }
}
