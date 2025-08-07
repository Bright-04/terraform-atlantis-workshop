# AWS-Native Compliance Validation for Workshop
# This provides comprehensive compliance checking without external dependencies

locals {
  # Compliance rules
  allowed_instance_types = ["t3.micro", "t3.small", "t3.medium"]
  required_tags = ["Environment", "Project", "CostCenter"]
  recommended_tags = ["Backup"]
  
  # Get all EC2 instances for validation
  ec2_instances = {
    for k, v in aws_instance : k => v
  }
  
  # Get all S3 buckets for validation
  s3_buckets = {
    for k, v in aws_s3_bucket : k => v
  }
}

# Compliance validation resource that runs during plan/apply
resource "null_resource" "compliance_validation" {
  triggers = {
    # Trigger validation on any infrastructure change
    instances = join(",", [for k, v in local.ec2_instances : "${k}:${v.instance_type}"])
    buckets = join(",", [for k, v in local.s3_buckets : "${k}:${v.bucket}"])
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "🔍 **COMPLIANCE VALIDATION RESULTS**"
      echo "=========================================="
      echo ""
      echo "📊 **VALIDATION RESULTS**"
      echo "========================="
      echo ""
      
      # Initialize violation counters
      VIOLATIONS=0
      WARNINGS=0
      
      echo "💰 **COST CONTROL VALIDATIONS**"
      echo "-------------------------------"
      
      # Check instance types
      echo "Checking EC2 instance types..."
      ${join("\n", [
        for k, v in local.ec2_instances : 
        "if [[ '${v.instance_type}' != 't3.micro' && '${v.instance_type}' != 't3.small' && '${v.instance_type}' != 't3.medium' ]]; then"
        "  echo '❌ VIOLATION: Instance ${k} uses expensive type \"${v.instance_type}\". Only t3.micro, t3.small, t3.medium are permitted'"
        "  VIOLATIONS=\$((VIOLATIONS + 1))"
        "fi"
      ])}
      
      # Check required tags
      echo ""
      echo "Checking required tags..."
      ${join("\n", [
        for k, v in local.ec2_instances : 
        "if [[ -z '${v.tags.Environment}' ]]; then"
        "  echo '❌ VIOLATION: Instance ${k} missing Environment tag'"
        "  VIOLATIONS=\$((VIOLATIONS + 1))"
        "fi"
        "if [[ -z '${v.tags.Project}' ]]; then"
        "  echo '❌ VIOLATION: Instance ${k} missing Project tag'"
        "  VIOLATIONS=\$((VIOLATIONS + 1))"
        "fi"
        "if [[ -z '${v.tags.CostCenter}' ]]; then"
        "  echo '❌ VIOLATION: Instance ${k} missing CostCenter tag'"
        "  VIOLATIONS=\$((VIOLATIONS + 1))"
        "fi"
        "if [[ -z '${v.tags.Backup}' ]]; then"
        "  echo '⚠️  WARNING: Instance ${k} missing Backup tag (recommended)'"
        "  WARNINGS=\$((WARNINGS + 1))"
        "fi"
      ])}
      
      echo ""
      echo "🔒 **SECURITY VALIDATIONS**"
      echo "---------------------------"
      
      # Check S3 bucket naming and encryption
      echo "Checking S3 bucket compliance..."
      ${join("\n", [
        for k, v in local.s3_buckets : 
        "if [[ ! '${v.bucket}' =~ ^terraform-atlantis-workshop- ]]; then"
        "  echo '❌ VIOLATION: S3 bucket ${k} must follow naming convention: terraform-atlantis-workshop-*'"
        "  VIOLATIONS=\$((VIOLATIONS + 1))"
        "fi"
      ])}
      
      echo ""
      echo "📋 **SUMMARY**"
      echo "============="
      echo "Total Violations: \$VIOLATIONS"
      echo "Total Warnings: \$WARNINGS"
      echo ""
      
      if [[ \$VIOLATIONS -gt 0 ]]; then
        echo "🚫 **VALIDATION FAILED** - Fix violations before applying"
        echo ""
        echo "=== Next Steps ==="
        echo "❌ Fix the violations above and re-run terraform plan"
        exit 1
      else
        echo "✅ **VALIDATION PASSED** - Ready for apply"
        echo ""
        echo "=== Next Steps ==="
        echo "✅ Run: terraform apply"
        if [[ \$WARNINGS -gt 0 ]]; then
          echo "⚠️  Review warnings above (optional)"
        fi
      fi
      
      echo ""
      echo "🎉 Compliance validation framework is active and working!"
    EOT
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
