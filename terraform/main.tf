# Terraform configuration for local development (not for Atlantis)
# This file uses localhost endpoints for direct development work

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# AWS Provider configuration for LocalStack (local development)
provider "aws" {
  region                      = var.region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2            = "http://localstack:4566"
    s3             = "http://localstack:4566"
    rds            = "http://localstack:4566"
    iam            = "http://localstack:4566"
    cloudwatch     = "http://localstack:4566"
    logs           = "http://localstack:4566"
    sts            = "http://localstack:4566"
    lambda         = "http://localstack:4566"
    apigateway     = "http://localstack:4566"
  }

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Provider    = "LocalStack"
    }
  }
}

# Data source for availability zones (LocalStack)
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for AMI (LocalStack uses a mock AMI)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Type = "Public"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-private-subnet"
    Type = "Private"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Association for Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for Web Server
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Hello from ${var.project_name}!" > /tmp/hello.txt
    echo "This instance was created with Terraform on LocalStack." >> /tmp/hello.txt
  EOF
  )

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    Owner       = "workshop-participant"
    TestTag     = "atlantis-workflow-complete"
    Timestamp   = formatdate("YYYY-MM-DD-hhmm", timestamp())
    CostCenter  = "workshop-training"
  }
}

# S3 Bucket for testing
resource "aws_s3_bucket" "workshop" {
  bucket = "${var.project_name}-${var.s3_bucket_suffix}"

  tags = {
    Name       = "${var.project_name}-${var.s3_bucket_suffix}"
    CostCenter = "workshop-training"
  }
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "workshop" {
  bucket = aws_s3_bucket.workshop.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Test EC2 instance with policy violations
resource "aws_instance" "policy_test" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "m5.large"  # This should trigger cost control policy
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.policy_test.id]

  tags = {
    Name = "test-instance-no-required-tags"
    # Missing Environment, Project, CostCenter tags - should trigger policies
  }
}

# Security group with overly permissive rules
resource "aws_security_group" "policy_test" {
  name        = "policy-test-sg"
  description = "Security group that should trigger policy violations"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "All ports open - policy violation"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "policy-test-sg"
  }
}

# S3 bucket without encryption - policy violation  
resource "aws_s3_bucket" "unencrypted_test" {
  bucket = "test-unencrypted-bucket-${random_string.bucket_suffix.result}"

  tags = {
    Name = "unencrypted-test-bucket"
    # Missing CostCenter tag
  }
}

# Random string for bucket suffix
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
