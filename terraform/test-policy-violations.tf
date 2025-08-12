# =============================================================================
# Test Policy Violations
# =============================================================================
# This file contains resources specifically for testing compliance validation
# 
# WARNING: This file is for testing purposes only. In production, these
# resources would violate compliance policies and should not be deployed.
# 
# To test compliance validation:
# 1. Temporarily modify instance types to expensive ones (e.g., m5.large)
# 2. Remove required tags
# 3. Use non-compliant S3 bucket names
# 4. Run terraform plan to see violations
# 5. Revert changes to restore compliance
# =============================================================================

# =============================================================================
# Test Instance with Policy Violations (for testing only)
# =============================================================================
# This instance is configured to test compliance validation
# In production, this would violate cost control policies
# =============================================================================

# Uncomment and modify the lines below to test compliance violations:

# resource "aws_instance" "test_violation" {
#   ami                    = data.aws_ami.amazon_linux.id
#   instance_type          = "m5.large"  # VIOLATION: Expensive instance type
#   key_name               = var.key_pair_name != "" ? var.key_pair_name : null
#   vpc_security_group_ids = [aws_security_group.test_violation.id]
#   subnet_id              = aws_subnet.public.id
# 
#   # VIOLATION: Missing required tags
#   tags = {
#     Name = "test-violation-instance"
#     # Missing: Environment, Project, CostCenter tags
#   }
# }

# =============================================================================
# Test S3 Bucket with Policy Violations (for testing only)
# =============================================================================
# This bucket is configured to test compliance validation
# In production, this would violate naming and security policies
# =============================================================================

# Uncomment and modify the lines below to test compliance violations:

# resource "aws_s3_bucket" "test_violation" {
#   bucket = "non-compliant-bucket-name"  # VIOLATION: Doesn't follow naming convention
# 
#   # VIOLATION: Missing required tags
#   tags = {
#     Name = "test-violation-bucket"
#     # Missing: Environment, Project, CostCenter tags
#   }
# }

# resource "aws_s3_bucket_public_access_block" "test_violation" {
#   bucket = aws_s3_bucket.test_violation.id
# 
#   # VIOLATION: Public access not fully blocked
#   block_public_acls       = false  # Should be true
#   block_public_policy     = false  # Should be true
#   ignore_public_acls      = false  # Should be true
#   restrict_public_buckets = false  # Should be true
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "test_violation" {
#   bucket = aws_s3_bucket.test_violation.id
# 
#   # VIOLATION: No encryption configured
#   # rule {
#   #   apply_server_side_encryption_by_default {
#   #     sse_algorithm = "AES256"
#   #   }
#   # }
# }

# =============================================================================
# Test Security Group with Policy Violations (for testing only)
# =============================================================================
# This security group is configured to test compliance validation
# In production, this would violate security policies
# =============================================================================

# Uncomment and modify the lines below to test compliance violations:

# resource "aws_security_group" "test_violation" {
#   name_prefix = "test-violation-sg"
#   description = "Security group with policy violations"
#   vpc_id      = aws_vpc.main.id
# 
#   # VIOLATION: Overly permissive ingress rules
#   ingress {
#     description = "All traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]  # Should be restricted
#   }
# 
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# 
#   # VIOLATION: Missing required tags
#   tags = {
#     Name = "test-violation-sg"
#     # Missing: Environment, Project, CostCenter tags
#   }
# }

# =============================================================================
# Compliance Testing Instructions
# =============================================================================
# 
# To test compliance validation:
# 
# 1. Instance Type Violation:
#    - Change instance_type from "t3.micro" to "m5.large" in the test_violation resource
#    - Run: terraform plan
#    - Expected: Error about expensive instance types
# 
# 2. Required Tags Violation:
#    - Remove Environment, Project, or CostCenter tags from any resource
#    - Run: terraform plan
#    - Expected: Error about missing required tags
# 
# 3. S3 Naming Violation:
#    - Change bucket name to not start with "terraform-atlantis-workshop-"
#    - Run: terraform plan
#    - Expected: Error about naming convention
# 
# 4. Security Violation:
#    - Uncomment the overly permissive security group rules
#    - Run: terraform plan
#    - Expected: Error about security group configuration
# 
# 5. Encryption Violation:
#    - Remove encryption configuration from S3 buckets
#    - Run: terraform plan
#    - Expected: Error about encryption requirements
# 
# 6. Public Access Violation:
#    - Set public access block settings to false
#    - Run: terraform plan
#    - Expected: Error about public access requirements
# 
# After testing, revert all changes to restore compliance:
# git checkout -- terraform/test-policy-violations.tf
# 
# =============================================================================

# =============================================================================
# Example Test Commands
# =============================================================================
# 
# # Test instance type violation
# sed -i 's/t3.micro/m5.large/' terraform/test-policy-violations.tf
# terraform plan
# 
# # Test missing tags violation
# sed -i '/Environment =/d' terraform/test-policy-violations.tf
# terraform plan
# 
# # Test S3 naming violation
# sed -i 's/terraform-atlantis-workshop-/non-compliant-/' terraform/test-policy-violations.tf
# terraform plan
# 
# # Revert all changes
# git checkout -- terraform/test-policy-violations.tf
# 
# =============================================================================
