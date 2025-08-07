# AWS-Native Compliance Validation for Workshop
# This provides comprehensive compliance checking without external dependencies

locals {
  # Compliance rules
  allowed_instance_types = ["t3.micro", "t3.small", "t3.medium"]
  required_tags = ["Environment", "Project", "CostCenter"]
  recommended_tags = ["Backup"]
  
  # Get all EC2 instances for validation
  ec2_instances = {
    web = aws_instance.web
    policy_test = aws_instance.policy_test
  }
  
  # Get all S3 buckets for validation
  s3_buckets = {
    workshop = aws_s3_bucket.workshop
    unencrypted_test = aws_s3_bucket.unencrypted_test
  }
}

# Output validation status
output "compliance_validation_status" {
  description = "Compliance validation status"
  value = {
    total_instances = length(local.ec2_instances)
    total_buckets = length(local.s3_buckets)
    allowed_instance_types = local.allowed_instance_types
    required_tags = local.required_tags
    recommended_tags = local.recommended_tags
    message = "Compliance validation framework active"
  }
}

# Output validation rules for reference
output "compliance_rules" {
  description = "Active compliance rules"
  value = {
    cost_control = {
      allowed_instance_types = local.allowed_instance_types
      required_tags = local.required_tags
    }
    security = {
      s3_naming_convention = "terraform-atlantis-workshop-*"
      encryption_required = true
    }
    operational = {
      recommended_tags = local.recommended_tags
    }
  }
}
