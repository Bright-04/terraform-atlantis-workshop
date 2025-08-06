# Test configuration to trigger policy violations
# This file intentionally violates policies for testing

# EC2 instance without required tags (violates security policies)
resource "aws_instance" "test_violation" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "m5.large"  # Violates cost policy - expensive instance type

  # Missing required tags: Environment, Project, CostCenter
  tags = {
    Name = "test-violation-instance"
  }
}

# S3 bucket with incorrect naming (violates cost policy)
resource "aws_s3_bucket" "test_violation" {
  bucket = "wrong-naming-convention"  # Should start with "terraform-atlantis-workshop"

  # Missing CostCenter tag (violates cost policy)
  tags = {
    Environment = "test"
  }
}

# Security group with overly permissive rules (violates security policy)
resource "aws_security_group" "test_violation" {
  name_prefix = "test-violation-sg"
  description = "Security group with policy violations"

  ingress {
    from_port   = 0      # Violates security policy - all ports
    to_port     = 65535  # Violates security policy - all ports
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
  }
}

# EBS volume without CostCenter tag (violates cost policy)
resource "aws_ebs_volume" "test_violation" {
  availability_zone = "us-west-2a"
  size              = 20

  # Missing CostCenter tag
  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
  }
}
