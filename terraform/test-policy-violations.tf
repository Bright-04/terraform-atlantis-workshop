# Test resources with compliance validation
# These resources are now compliant with all policies

# Compliant: Using approved instance type
resource "aws_instance" "test_violation" {
  ami                    = data.aws_ami.amazon_linux.id           # Fixed: Use data source for valid AMI
  instance_type          = "t3.micro"                             # Fixed: Changed from m5.large to t3.micro
  subnet_id              = aws_subnet.public.id                   # Fixed: Added subnet assignment
  vpc_security_group_ids = [aws_security_group.test_violation.id] # Fixed: Added security group

  tags = {
    Name        = "test-violation-instance"
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}

# Compliant: Following naming convention
resource "aws_s3_bucket" "test_violation" {
  bucket = "terraform-atlantis-workshop-test-violation-${random_string.bucket_suffix.result}" # Fixed: Using existing random string resource

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}

# S3 Bucket encryption for test bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "test_violation" {
  bucket = aws_s3_bucket.test_violation.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket public access block for test bucket
resource "aws_s3_bucket_public_access_block" "test_violation" {
  bucket = aws_s3_bucket.test_violation.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket versioning for test violation bucket
resource "aws_s3_bucket_versioning" "test_violation" {
  bucket = aws_s3_bucket.test_violation.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Compliant: All required tags present
resource "aws_security_group" "test_violation" {
  name_prefix = "test-violation-sg"
  description = "Security group with policy violations"
  vpc_id      = aws_vpc.main.id # Fixed: Added missing VPC reference

  ingress {
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
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training" # Fixed: Added missing CostCenter tag
  }
}

# Compliant: All required tags present
resource "aws_ebs_volume" "test_violation" {
  availability_zone = data.aws_availability_zones.available.names[0] # Fixed: Use data source for valid AZ
  size              = 20

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training" # Fixed: Added missing CostCenter tag
  }
}
