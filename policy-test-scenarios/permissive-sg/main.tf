# Test Case: Overly permissive security group (should violate terraform_security.rego)
resource "aws_security_group" "test_permissive" {
  name_prefix = "test-permissive-sg"
  vpc_id      = aws_vpc.main.id
  description = "Test overly permissive security group"

  ingress {
    description = "All ports open - BAD!"
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
    Name       = "test-permissive-sg"
    Environment = "test"
    Project    = "terraform-atlantis-workshop"
  }
}
