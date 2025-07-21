# Test Case: Unencrypted S3 bucket (should violate terraform_security.rego)
resource "aws_s3_bucket" "test_unencrypted" {
  bucket = "terraform-atlantis-workshop-test-unencrypted"
  
  tags = {
    Name       = "test-unencrypted-bucket"
    Environment = "test"
    Project    = "terraform-atlantis-workshop"
    CostCenter = "workshop"
  }
  
  # No server_side_encryption_configuration - should trigger security policy
}
