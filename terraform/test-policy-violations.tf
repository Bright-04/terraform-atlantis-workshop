# Test configuration to trigger policy violations
# This file intentionally violates policies for testing

# EC2 instance without required tags (violates security policies)
resource "aws_instance" "test_violation" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"  # Fixed: Changed from m5.large to t3.micro

  # Fixed: Added required tags
  tags = {
    Name        = "test-violation-instance"
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}

# S3 bucket with incorrect naming (violates cost policy)
resource "aws_s3_bucket" "test_violation" {
  bucket = "terraform-atlantis-workshop-test-violation"  # Fixed: Changed to follow naming convention

  # Fixed: Added CostCenter tag
  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}

# Security group with overly permissive rules (violates security policy)
resource "aws_security_group" "test_violation" {
  name_prefix = "test-violation-sg"
  description = "Security group with policy violations"

  # Fixed: Changed from overly permissive to specific ports
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}

# EBS volume without CostCenter tag (violates cost policy)
resource "aws_ebs_volume" "test_violation" {
  availability_zone = "us-west-2a"
  size              = 20

  # Fixed: Added CostCenter tag
  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}
