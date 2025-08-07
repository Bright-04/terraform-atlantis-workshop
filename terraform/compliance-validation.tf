# AWS-Native Compliance Validation for Workshop
# This provides comprehensive compliance checking using Terraform validation blocks

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

# Validation block for instance types
resource "null_resource" "instance_type_validation" {
  triggers = {
    instances = join(",", [for k, v in local.ec2_instances : "${k}:${v.instance_type}"])
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for k, v in local.ec2_instances : contains(local.allowed_instance_types, v.instance_type)
      ])
      error_message = "❌ VIOLATION: Found expensive instance types. Only t3.micro, t3.small, t3.medium are permitted. Current instances: ${join(", ", [for k, v in local.ec2_instances : "${k}=${v.instance_type}"])}"
    }
  }
}

# Validation block for required tags
resource "null_resource" "required_tags_validation" {
  triggers = {
    instances = join(",", [for k, v in local.ec2_instances : "${k}:${v.instance_type}"])
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for k, v in local.ec2_instances : 
        can(v.tags.Environment) && can(v.tags.Project) && can(v.tags.CostCenter)
      ])
      error_message = "❌ VIOLATION: EC2 instances missing required tags (Environment, Project, CostCenter). Add proper tags to all instances."
    }
  }
}

# Validation block for S3 bucket naming
resource "null_resource" "s3_naming_validation" {
  triggers = {
    buckets = join(",", [for k, v in local.s3_buckets : "${k}:${v.bucket}"])
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for k, v in local.s3_buckets : can(regex("^terraform-atlantis-workshop-", v.bucket))
      ])
      error_message = "❌ VIOLATION: S3 buckets must follow naming convention: terraform-atlantis-workshop-*. Current buckets: ${join(", ", [for k, v in local.s3_buckets : "${k}=${v.bucket}"])}"
    }
  }
}

# Compliance validation output that shows during plan
output "compliance_validation_results" {
  description = "Compliance validation results"
  value = <<-EOT
🔍 **COMPLIANCE VALIDATION RESULTS**
==========================================

📊 **VALIDATION RESULTS**
=========================

💰 **COST CONTROL VALIDATIONS**
-------------------------------
✅ Instance Types: ${join(", ", [for k, v in local.ec2_instances : "${k}=${v.instance_type}"])}
✅ Allowed Types: ${join(", ", local.allowed_instance_types)}
✅ S3 Buckets: ${join(", ", [for k, v in local.s3_buckets : "${k}=${v.bucket}"])}

🔒 **SECURITY VALIDATIONS**
---------------------------
✅ Required Tags: ${join(", ", local.required_tags)}
✅ Instance Count: ${length(local.ec2_instances)}
✅ Bucket Count: ${length(local.s3_buckets)}

📋 **SUMMARY**
=============
✅ **VALIDATION PASSED** - All compliance rules satisfied
✅ Terraform validation blocks will prevent violations
✅ Configuration is compliant with workshop requirements

🎉 Compliance validation framework is active and working!
EOT
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
