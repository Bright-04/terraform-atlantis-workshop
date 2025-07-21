# Test Case: Expensive instance type (should violate cost_control.rego) - REPO CONFIG TEST
resource "aws_instance" "test_expensive" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "m5.large"  # This should trigger cost control policy
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name       = "test-expensive-instance"
    Environment = "test"
    Project    = "terraform-atlantis-workshop"
    CostCenter = "workshop"
  }
}
