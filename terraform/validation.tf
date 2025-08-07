# Terraform Built-in Validation for Compliance
# This provides compliance validation without external tools like Conftest

# Validation for cost control
locals {
  # Cost validation rules
  allowed_instance_types = ["t3.micro", "t3.small", "t3.medium"]
  required_tags = ["Environment", "Project", "CostCenter", "Backup"]
  
  # Security validation rules
  required_security_tags = ["Environment", "Project"]
  allowed_ports = [22, 80, 443]
}

# Validate instance types for cost control
resource "null_resource" "cost_validation" {
  for_each = toset([
    for instance in aws_instance.test_violation : instance.instance_type
    if !contains(local.allowed_instance_types, instance.instance_type)
  ])
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Instance type ${each.value} is not allowed. Allowed types: ${join(", ", local.allowed_instance_types)}' && exit 1"
  }
}

# Validate required tags for cost tracking
resource "null_resource" "tag_validation" {
  for_each = aws_instance.test_violation
  
  provisioner "local-exec" {
    command = <<-EOT
      missing_tags=""
      for tag in ${join(" ", local.required_tags)}; do
        if [[ -z "${each.value.tags[$tag]}" ]]; then
          missing_tags="$missing_tags $tag"
        fi
      done
      if [[ -n "$missing_tags" ]]; then
        echo "ERROR: Instance ${each.value.id} missing required tags:$missing_tags"
        exit 1
      fi
    EOT
  }
}

# Validate S3 bucket naming convention
resource "null_resource" "s3_naming_validation" {
  for_each = aws_s3_bucket.test_violation
  
  provisioner "local-exec" {
    command = "if [[ ! '${each.value.bucket}' =~ ^terraform-atlantis-workshop- ]]; then echo 'ERROR: S3 bucket ${each.value.bucket} must follow naming convention: terraform-atlantis-workshop-*' && exit 1; fi"
  }
}

# Validate security group rules
resource "null_resource" "security_validation" {
  for_each = aws_security_group.test_violation
  
  provisioner "local-exec" {
    command = <<-EOT
      for rule in ${jsonencode(each.value.ingress)}; do
        port=$(echo $rule | jq -r '.from_port')
        if [[ "$port" == "0" ]]; then
          echo "ERROR: Security group ${each.value.id} has overly permissive rule (all ports)"
          exit 1
        fi
      done
    EOT
  }
}

# Output validation results
output "compliance_validation" {
  description = "Compliance validation results"
  value = {
    cost_controls = {
      instance_types_validated = length(local.allowed_instance_types)
      required_tags_checked = length(local.required_tags)
    }
    security_controls = {
      security_tags_required = length(local.required_security_tags)
      allowed_ports_defined = length(local.allowed_ports)
    }
    validation_status = "All compliance rules configured"
  }
}
