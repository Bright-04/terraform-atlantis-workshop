variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "terraform-atlantis-workshop-v2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "Name of AWS key pair for EC2 access"
  type        = string
  default     = ""
}

variable "s3_bucket_suffix" {
  description = "Optional suffix for S3 bucket name to ensure uniqueness"
  type        = string
  default     = "workshop-bucket"
}
# Testing GitHub Actions - 08/11/2025 23:23:42
# Testing enhanced technical comments - changed instance_type from t3.micro to t3.small
# Testing enhanced technical comments - changed environment from workshop to production
# Testing enhanced technical comments - changed project_name to v2 for PR testing
