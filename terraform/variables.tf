variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "terraform-atlantis-workshop-rds"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16" # Changed to avoid conflicts with existing resources
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.1.1.0/24" # Changed to avoid conflicts with existing resources
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.1.2.0/24" # Changed to avoid conflicts with existing resources
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
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

# New variables for RDS database
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "workshopdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "workshop_admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  default     = "WorkshopPassword123!"
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "14.12"
}

# Testing GitHub Actions - 08/11/2025 23:23:42
# Testing enhanced technical comments - changed instance_type from t3.micro to t3.small
# Testing enhanced technical comments - changed environment from workshop to production
# Testing enhanced technical comments - reverted project_name to avoid resource conflicts
# Testing enhanced technical comments - changed instance_type from t3.small to t3.medium for workflow testing
# Testing enhanced technical comments - fixed region to ap-southeast-1 to resolve S3 bucket creation issues
# Testing enhanced technical comments - added Redis port, new S3 bucket, and enhanced tags for workflow testing
# Testing enhanced technical comments - added RDS database variables for workflow testing
