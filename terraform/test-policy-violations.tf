# Test resources with compliance validation
# These resources are now compliant with all policies

# Compliant: Using approved instance type
resource "aws_instance" "test_violation" {
  ami           = data.aws_ami.amazon_linux.id  # Fixed: Use data source for valid AMI
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
  vpc_id      = aws_vpc.main.id  # Fixed: Added missing VPC reference

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
  availability_zone = "ap-southeast-1a"  # Fixed: Changed to match configured region
  size              = 20

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"  # Fixed: Added missing CostCenter tag
  }
}
