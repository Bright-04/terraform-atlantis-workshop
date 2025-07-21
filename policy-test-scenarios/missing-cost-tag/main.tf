# Test Case: Missing CostCenter tag (should violate cost_control.rego)
resource "aws_instance" "test_no_cost_tag" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name        = "test-no-cost-tag"
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    # Missing CostCenter tag - should trigger policy violation
  }
}
