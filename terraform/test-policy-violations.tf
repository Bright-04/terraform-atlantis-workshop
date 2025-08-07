# Test resources with compliance validation
# These resources are now compliant with all policies

# Compliant: Using approved instance type
resource "aws_instance" "test_violation" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"  # Fixed: Changed from m5.large to t3.micro

  tags = {
    Name        = "test-violation-instance"
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}

# Compliant: Following naming convention
resource "aws_s3_bucket" "test_violation" {
  bucket = "terraform-atlantis-workshop-test-violation"  # Fixed: Changed to follow naming convention

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}

# Compliant: All required tags present
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
    CostCenter  = "workshop-training"  # Fixed: Added missing CostCenter tag
  }
}

# Compliant: All required tags present
resource "aws_ebs_volume" "test_violation" {
  availability_zone = "us-west-2a"
  size              = 20

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"  # Fixed: Added missing CostCenter tag
  }
}
