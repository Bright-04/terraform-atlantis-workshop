# Test Case: Missing required tags (should violate terraform_security.rego)
resource "aws_instance" "test_missing_tags" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name = "test-missing-tags"
    # Missing Environment and Project tags - should trigger security policy
    CostCenter = "workshop"
  }
}
