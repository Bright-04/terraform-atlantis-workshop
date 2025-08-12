# Terraform configuration for AWS Production Deployment
# This file uses real AWS infrastructure instead of LocalStack

# AWS Provider configuration for Production
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Provider    = "AWS"
      CostCenter  = "production"
    }
  }
}

# Data source for availability zones (AWS)
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for existing internet gateway to avoid limit exceeded
data "aws_internet_gateway" "existing" {
  count = 1
  filter {
    name   = "attachment.vpc-id"
    values = [aws_vpc.main.id]
  }
}

# Data source for Amazon Linux 2 AMI (AWS)
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

# Internet Gateway - Create only if none exists
resource "aws_internet_gateway" "main" {
  count  = length(data.aws_internet_gateway.existing) == 0 ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Use existing internet gateway if available
locals {
  internet_gateway_id = length(data.aws_internet_gateway.existing) > 0 ? data.aws_internet_gateway.existing[0].id : aws_internet_gateway.main[0].id
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
    gateway_id = local.internet_gateway_id
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

  ingress {
    description = "Custom Application Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Redis Cache Port"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
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
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name # Fixed: Added IAM profile

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from ${var.project_name} on AWS!</h1>" > /var/www/html/index.html
    echo "<p>This instance was created with Terraform on AWS Production.</p>" >> /var/www/html/index.html
    echo "<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" >> /var/www/html/index.html
    echo "<p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>" >> /var/www/html/index.html
  EOF
  )

  tags = {
    Name         = "${var.project_name}-web-server"
    Environment  = var.environment
    Project      = var.project_name
    Owner        = "workshop-participant"
    TestTag      = "workflow-enhancement-test"
    Timestamp    = formatdate("YYYY-MM-DD-hhmm", timestamp())
    CostCenter   = "production"
    Backup       = "daily"
    InstanceType = var.instance_type
    WorkflowTest = "enhanced-comments"
    LastModified = formatdate("YYYY-MM-DD", timestamp())
  }
}

# S3 Bucket for production data
resource "aws_s3_bucket" "workshop" {
  bucket = "${var.project_name}-${var.s3_bucket_suffix}-${random_string.bucket_suffix.result}"

  tags = {
    Name       = "${var.project_name}-${var.s3_bucket_suffix}"
    CostCenter = "production"
  }
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "workshop" {
  bucket = aws_s3_bucket.workshop.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "workshop" {
  bucket = aws_s3_bucket.workshop.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "workshop" {
  bucket = aws_s3_bucket.workshop.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for application logs
resource "aws_s3_bucket" "application_logs" {
  bucket = "${var.project_name}-application-logs-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-application-logs"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "production"
    Purpose     = "application-logs"
  }
}

# S3 Bucket encryption for application logs
resource "aws_s3_bucket_server_side_encryption_configuration" "application_logs" {
  bucket = aws_s3_bucket.application_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket public access block for application logs
resource "aws_s3_bucket_public_access_block" "application_logs" {
  bucket = aws_s3_bucket.application_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Test EC2 instance with policy compliance
resource "aws_instance" "policy_test" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small" # Compliant instance type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.policy_test.id]

  tags = {
    Name        = "test-instance-compliant"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "production"
    Backup      = "daily"
  }
}

# Security group with restricted access
resource "aws_security_group" "policy_test" {
  name        = "${var.project_name}-policy-test-sg"
  description = "Security group with restricted access for compliance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH access only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "policy-test-sg"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "production"
  }
}

# S3 bucket with encryption - compliant configuration
resource "aws_s3_bucket" "encrypted_test" {
  bucket = "terraform-atlantis-workshop-encrypted-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "encrypted-test-bucket"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "production"
  }
}

# S3 Bucket encryption for test bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypted_test" {
  bucket = aws_s3_bucket.encrypted_test.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket public access block for test bucket
resource "aws_s3_bucket_public_access_block" "encrypted_test" {
  bucket = aws_s3_bucket.encrypted_test.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket versioning for encrypted test bucket
resource "aws_s3_bucket_versioning" "encrypted_test" {
  bucket = aws_s3_bucket.encrypted_test.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Random string for bucket suffix
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-application-logs"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "production"
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "production"
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.project_name}-cloudwatch-logs"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# RDS Database Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.public.id]

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "production"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres14"
  name   = "${var.project_name}-db-params"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = {
    Name        = "${var.project_name}-db-params"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "production"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-db-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from web servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "production"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db-${random_string.bucket_suffix.result}"

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "${var.project_name}-db"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "production"
    Backup      = "daily"
    Engine      = "postgres"
    Version     = var.db_engine_version
  }
}
