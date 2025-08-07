# Test resources with intentional policy violations
# These are designed to trigger compliance validation failures

# Violation: Expensive instance type (should be t3.micro, t3.small, or t3.medium)
resource "aws_instance" "test_violation" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "m5.large"  # VIOLATION: Expensive instance type

  tags = {
    Name        = "test-violation-instance"
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}

# Violation: Wrong naming convention (should start with terraform-atlantis-workshop-)
resource "aws_s3_bucket" "test_violation" {
  bucket = "wrong-naming-convention"  # VIOLATION: Doesn't follow naming convention

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}

# Violation: Missing required tags (missing CostCenter)
resource "aws_security_group" "test_violation" {
  name_prefix = "test-violation-sg"
  description = "Security group with policy violations"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    # VIOLATION: Missing CostCenter tag
  }
}

# Violation: Missing required tags (missing CostCenter)
resource "aws_ebs_volume" "test_violation" {
  availability_zone = "us-west-2a"
  size              = 20

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    # VIOLATION: Missing CostCenter tag
  }
}
