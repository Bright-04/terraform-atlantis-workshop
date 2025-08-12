# Terraform configuration for AWS Workshop - Minimal Version
# Focused on core workshop components without RDS and CloudFront

# AWS Provider configuration
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

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for Amazon Linux 2 AMI
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

# Random string for unique resource names
resource "random_string" "bucket_suffix" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false
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

  timeouts {
    delete = "10m"
  }

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

# Security group with restricted access for compliance testing
resource "aws_security_group" "policy_test" {
  name        = "${var.project_name}-policy-test-sg"
  description = "Security group with restricted access for compliance"
  vpc_id      = aws_vpc.main.id

  timeouts {
    delete = "10m"
  }

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
    CostCenter  = "production"
    Environment = "workshop"
  }
}

# Security group with policy violations for testing
resource "aws_security_group" "test_violation" {
  name_prefix = "test-violation-sg"
  description = "Security group with policy violations"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH access"
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
    CostCenter  = "workshop-training"
    Environment = "test"
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role-${random_string.bucket_suffix.result}"

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
}

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-s3-access-policy"
  description = "Policy for S3 bucket access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.workshop.arn,
          "${aws_s3_bucket.workshop.arn}/*"
        ]
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile-${random_string.bucket_suffix.result}"
  role = aws_iam_role.ec2_role.name
}

# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/ec2/${var.project_name}-${random_string.bucket_suffix.result}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-application-logs"
  }
}

# Main S3 Bucket for workshop
resource "aws_s3_bucket" "workshop" {
  bucket = "${var.project_name}-workshop-${random_string.bucket_suffix.result}"

  tags = {
    Name       = "${var.project_name}-workshop-bucket"
    CostCenter = "production"
  }
}

# S3 Bucket for application logs
resource "aws_s3_bucket" "application_logs" {
  bucket = "${var.project_name}-application-logs-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-application-logs"
    CostCenter  = "production"
    Environment = "workshop"
    Purpose     = "application-logs"
  }
}

# S3 Bucket for encrypted test
resource "aws_s3_bucket" "encrypted_test" {
  bucket = "${var.project_name}-encrypted-test-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "encrypted-test-bucket"
    CostCenter  = "production"
    Environment = "workshop"
  }
}

# S3 Bucket for test violations
resource "aws_s3_bucket" "test_violation" {
  bucket = "${var.project_name}-test-violation-${random_string.bucket_suffix.result}"

  tags = {
    CostCenter  = "workshop-training"
    Environment = "test"
  }
}

# S3 Bucket Public Access Block for all buckets
resource "aws_s3_bucket_public_access_block" "workshop" {
  bucket = aws_s3_bucket.workshop.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "application_logs" {
  bucket = aws_s3_bucket.application_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "encrypted_test" {
  bucket = aws_s3_bucket.encrypted_test.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "test_violation" {
  bucket = aws_s3_bucket.test_violation.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Server Side Encryption for all buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "workshop" {
  bucket = aws_s3_bucket.workshop.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "application_logs" {
  bucket = aws_s3_bucket.application_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypted_test" {
  bucket = aws_s3_bucket.encrypted_test.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test_violation" {
  bucket = aws_s3_bucket.test_violation.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Versioning for compliance
resource "aws_s3_bucket_versioning" "workshop" {
  bucket = aws_s3_bucket.workshop.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "encrypted_test" {
  bucket = aws_s3_bucket.encrypted_test.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "test_violation" {
  bucket = aws_s3_bucket.test_violation.id
  versioning_configuration {
    status = "Enabled"
  }
}

# EC2 Instance - Web Server
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    bucket_name  = aws_s3_bucket.workshop.bucket
  }))

  tags = {
    Name = "${var.project_name}-web-server"
  }
}

# EC2 Instance - Policy Test
resource "aws_instance" "policy_test" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.policy_test.id]
  subnet_id              = aws_subnet.private.id

  tags = {
    Name        = "policy-test-instance"
    CostCenter  = "production"
    Environment = "workshop"
  }
}

# EC2 Instance - Test Violation
resource "aws_instance" "test_violation" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.test_violation.id]
  subnet_id              = aws_subnet.public.id

  tags = {
    Name        = "test-violation-instance"
    CostCenter  = "workshop-training"
    Environment = "test"
  }
}

# Compliance validation resources
resource "null_resource" "instance_type_validation" {
  triggers = {
    instances = "policy_test:${aws_instance.policy_test.instance_type},test_violation:${aws_instance.test_violation.instance_type},web:${aws_instance.web.instance_type}"
  }
}

resource "null_resource" "required_tags_validation" {
  triggers = {
    instances = "policy_test:${aws_instance.policy_test.instance_type},test_violation:${aws_instance.test_violation.instance_type},web:${aws_instance.web.instance_type}"
  }
}

resource "null_resource" "s3_naming_validation" {
  triggers = {
    buckets = "${aws_s3_bucket.workshop.bucket},${aws_s3_bucket.application_logs.bucket},${aws_s3_bucket.encrypted_test.bucket},${aws_s3_bucket.test_violation.bucket}"
  }
}
