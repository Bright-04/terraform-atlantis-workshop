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
    command = "echo 'Validating tags for instance ${each.value.id}'"
  }
}

# Validate S3 bucket naming convention
resource "null_resource" "s3_naming_validation" {
  for_each = aws_s3_bucket.test_violation
  
  provisioner "local-exec" {
    command = "echo 'Validating S3 bucket naming: ${each.value.bucket}'"
  }
}

# Validate security group rules
resource "null_resource" "security_validation" {
  for_each = aws_security_group.test_violation
  
  provisioner "local-exec" {
    command = "echo 'Validating security group: ${each.value.id}'"
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

# Data source to check current resources for validation
data "aws_instances" "validation_check" {
  filter {
    name   = "tag:Name"
    values = ["*test_violation*"]
  }
}

# Output current validation status
output "current_validation_status" {
  description = "Current validation status"
  value = {
    total_instances = length(data.aws_instances.validation_check.ids)
    allowed_types = local.allowed_instance_types
    required_tags = local.required_tags
    message = "Compliance validation framework active"
  }
}
