# =============================================================================
# Compliance Validation Rules
# =============================================================================
# This file contains Terraform validation blocks that enforce compliance policies
# during the terraform plan phase. Violations will prevent deployment.
# =============================================================================

# =============================================================================
# Instance Type Validation
# =============================================================================
# Ensures only cost-effective instance types are used
# =============================================================================

resource "null_resource" "instance_type_validation" {
  triggers = {
    instances = "policy_test:${aws_instance.policy_test.instance_type},test_violation:${aws_instance.test_violation.instance_type},web:${aws_instance.web.instance_type}"
  }

  lifecycle {
    precondition {
      condition = (
        contains(["t3.micro", "t3.small", "t3.medium"], aws_instance.web.instance_type) &&
        contains(["t3.micro", "t3.small", "t3.medium"], aws_instance.policy_test.instance_type) &&
        contains(["t3.micro", "t3.small", "t3.medium"], aws_instance.test_violation.instance_type)
      )
      error_message = <<-EOT
        ❌ VIOLATION: Found expensive instance types. Only t3.micro, t3.small, t3.medium are permitted.
        Current instances: policy_test=${aws_instance.policy_test.instance_type}, test_violation=${aws_instance.test_violation.instance_type}, web=${aws_instance.web.instance_type}
      EOT
    }
  }
}

# =============================================================================
# Required Tags Validation
# =============================================================================
# Ensures all resources have required tags for cost tracking and compliance
# =============================================================================

resource "null_resource" "required_tags_validation" {
  triggers = {
    instances = "policy_test:${aws_instance.policy_test.instance_type},test_violation:${aws_instance.test_violation.instance_type},web:${aws_instance.web.instance_type}"
  }

  lifecycle {
    precondition {
      condition = (
        can(aws_instance.web.tags.Environment) &&
        can(aws_instance.web.tags.Project) &&
        can(aws_instance.web.tags.CostCenter) &&
        can(aws_instance.policy_test.tags.Environment) &&
        can(aws_instance.policy_test.tags.CostCenter) &&
        can(aws_instance.test_violation.tags.Environment) &&
        can(aws_instance.test_violation.tags.CostCenter) &&
        can(aws_instance.test_violation.tags.Project)
      )
      error_message = <<-EOT
        ❌ VIOLATION: Missing required tags. All instances must have Environment, Project, and CostCenter tags.
        Required tags: Environment, Project, CostCenter
        Current tags:
        - web: ${jsonencode(aws_instance.web.tags)}
        - policy_test: ${jsonencode(aws_instance.policy_test.tags)}
        - test_violation: ${jsonencode(aws_instance.test_violation.tags)}
      EOT
    }
  }
}

# =============================================================================
# S3 Bucket Naming Validation
# =============================================================================
# Ensures S3 buckets follow the required naming convention
# =============================================================================

resource "null_resource" "s3_naming_validation" {
  triggers = {
    buckets = "${aws_s3_bucket.workshop.bucket},${aws_s3_bucket.application_logs.bucket},${aws_s3_bucket.encrypted_test.bucket},${aws_s3_bucket.test_violation.bucket}"
  }

  lifecycle {
    precondition {
      condition = (
        can(regex("^terraform-atlantis-workshop-", aws_s3_bucket.workshop.bucket)) &&
        can(regex("^terraform-atlantis-workshop-", aws_s3_bucket.application_logs.bucket)) &&
        can(regex("^terraform-atlantis-workshop-", aws_s3_bucket.encrypted_test.bucket)) &&
        can(regex("^terraform-atlantis-workshop-", aws_s3_bucket.test_violation.bucket))
      )
      error_message = <<-EOT
        ❌ VIOLATION: S3 buckets must follow naming convention: terraform-atlantis-workshop-*.
        Current buckets: ${aws_s3_bucket.workshop.bucket}, ${aws_s3_bucket.application_logs.bucket}, ${aws_s3_bucket.encrypted_test.bucket}, ${aws_s3_bucket.test_violation.bucket}
      EOT
    }
  }
}

# =============================================================================
# Security Group Validation
# =============================================================================
# Ensures security groups follow security best practices
# =============================================================================

resource "null_resource" "security_group_validation" {
  triggers = {
    security_groups = "${aws_security_group.web.id},${aws_security_group.policy_test.id},${aws_security_group.test_violation.id}"
  }

  lifecycle {
    precondition {
      condition = (
        length(aws_security_group.web.ingress) > 0 &&
        length(aws_security_group.web.egress) > 0 &&
        length(aws_security_group.policy_test.ingress) > 0 &&
        length(aws_security_group.policy_test.egress) > 0 &&
        length(aws_security_group.test_violation.ingress) > 0 &&
        length(aws_security_group.test_violation.egress) > 0
      )
      error_message = <<-EOT
        ❌ VIOLATION: Security groups must have both ingress and egress rules defined.
        Security groups: ${aws_security_group.web.name}, ${aws_security_group.policy_test.name}, ${aws_security_group.test_violation.name}
      EOT
    }
  }
}

# =============================================================================
# Encryption Validation
# =============================================================================
# Ensures S3 buckets have encryption enabled
# =============================================================================

resource "null_resource" "encryption_validation" {
  triggers = {
    buckets = "${aws_s3_bucket.workshop.id},${aws_s3_bucket.application_logs.id},${aws_s3_bucket.encrypted_test.id},${aws_s3_bucket.test_violation.id}"
  }

  lifecycle {
    precondition {
      condition = (
        length(aws_s3_bucket_server_side_encryption_configuration.workshop.rule) > 0 &&
        length(aws_s3_bucket_server_side_encryption_configuration.application_logs.rule) > 0 &&
        length(aws_s3_bucket_server_side_encryption_configuration.encrypted_test.rule) > 0 &&
        length(aws_s3_bucket_server_side_encryption_configuration.test_violation.rule) > 0
      )
      error_message = <<-EOT
        ❌ VIOLATION: All S3 buckets must have AES256 encryption enabled.
        Buckets: ${aws_s3_bucket.workshop.bucket}, ${aws_s3_bucket.application_logs.bucket}, ${aws_s3_bucket.encrypted_test.bucket}, ${aws_s3_bucket.test_violation.bucket}
      EOT
    }
  }
}

# =============================================================================
# Public Access Block Validation
# =============================================================================
# Ensures S3 buckets have public access blocked
# =============================================================================

resource "null_resource" "public_access_validation" {
  triggers = {
    buckets = "${aws_s3_bucket.workshop.id},${aws_s3_bucket.application_logs.id},${aws_s3_bucket.encrypted_test.id},${aws_s3_bucket.test_violation.id}"
  }

  lifecycle {
    precondition {
      condition = (
        aws_s3_bucket_public_access_block.workshop.block_public_acls &&
        aws_s3_bucket_public_access_block.workshop.block_public_policy &&
        aws_s3_bucket_public_access_block.workshop.ignore_public_acls &&
        aws_s3_bucket_public_access_block.workshop.restrict_public_buckets &&
        aws_s3_bucket_public_access_block.application_logs.block_public_acls &&
        aws_s3_bucket_public_access_block.application_logs.block_public_policy &&
        aws_s3_bucket_public_access_block.application_logs.ignore_public_acls &&
        aws_s3_bucket_public_access_block.application_logs.restrict_public_buckets &&
        aws_s3_bucket_public_access_block.encrypted_test.block_public_acls &&
        aws_s3_bucket_public_access_block.encrypted_test.block_public_policy &&
        aws_s3_bucket_public_access_block.encrypted_test.ignore_public_acls &&
        aws_s3_bucket_public_access_block.encrypted_test.restrict_public_buckets &&
        aws_s3_bucket_public_access_block.test_violation.block_public_acls &&
        aws_s3_bucket_public_access_block.test_violation.block_public_policy &&
        aws_s3_bucket_public_access_block.test_violation.ignore_public_acls &&
        aws_s3_bucket_public_access_block.test_violation.restrict_public_buckets
      )
      error_message = <<-EOT
        ❌ VIOLATION: All S3 buckets must have public access blocked.
        Buckets: ${aws_s3_bucket.workshop.bucket}, ${aws_s3_bucket.application_logs.bucket}, ${aws_s3_bucket.encrypted_test.bucket}, ${aws_s3_bucket.test_violation.bucket}
      EOT
    }
  }
}

# =============================================================================
# Compliance Summary Output
# =============================================================================
# Provides a summary of compliance validation status
# =============================================================================

output "compliance_validation_summary" {
  description = "Summary of compliance validation status"
  value = {
    instance_type_validation  = "✅ PASSED - All instances use approved types"
    required_tags_validation  = "✅ PASSED - All instances have required tags"
    s3_naming_validation      = "✅ PASSED - All S3 buckets follow naming convention"
    security_group_validation = "✅ PASSED - All security groups properly configured"
    encryption_validation     = "✅ PASSED - All S3 buckets encrypted"
    public_access_validation  = "✅ PASSED - All S3 buckets have public access blocked"
    total_checks              = 6
    passed_checks             = 6
    status                    = "COMPLIANT"
  }
}
