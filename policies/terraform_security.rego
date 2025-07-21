# Terraform Security and Compliance Policies
# These policies validate infrastructure configurations before deployment

package main

# Deny resources without proper tags
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    not resource.change.after.tags.Environment
    msg := sprintf("EC2 instance %s must have Environment tag", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    not resource.change.after.tags.Project
    msg := sprintf("EC2 instance %s must have Project tag", [resource.address])
}

# Deny security groups with overly permissive rules
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    ingress := resource.change.after.ingress[_]
    ingress.from_port == 0
    ingress.to_port == 65535
    msg := sprintf("Security group %s has overly permissive ingress rule (all ports)", [resource.address])
}

# Deny unencrypted S3 buckets
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.server_side_encryption_configuration
    msg := sprintf("S3 bucket %s must have server-side encryption enabled", [resource.address])
}

# Warn about missing backup tags
warn[msg] {
    resource := input.resource_changes[_]
    backup_types := ["aws_instance", "aws_ebs_volume"]
    backup_types[_] == resource.type
    not resource.change.after.tags.Backup
    msg := sprintf("Resource %s should have Backup tag for operational procedures", [resource.address])
}

# Validate instance types (cost control)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    allowed_types := ["t3.micro", "t3.small", "t3.medium"]
    count([x | allowed_types[x] == resource.change.after.instance_type]) == 0
    msg := sprintf("Instance %s uses disallowed instance type. Only t3.micro, t3.small, t3.medium are permitted", [resource.address])
}
