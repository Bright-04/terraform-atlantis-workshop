# Cost Control and Resource Management Policies
package terraform.cost

# Cost-related validations
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    resource.change.after.instance_type == "m5.large"
    msg := sprintf("Instance %s uses expensive instance type. Consider smaller instances for workshop environment", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    resource.change.after.instance_type == "m5.xlarge"
    msg := sprintf("Instance %s uses expensive instance type. Consider smaller instances for workshop environment", [resource.address])
}

# Require cost allocation tags for instances
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    not resource.change.after.tags.CostCenter
    msg := sprintf("Resource %s must have CostCenter tag for cost tracking", [resource.address])
}

# Require cost allocation tags for S3 buckets
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.tags.CostCenter
    msg := sprintf("Resource %s must have CostCenter tag for cost tracking", [resource.address])
}

# Validate resource naming conventions
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not startswith(resource.change.after.bucket, "terraform-atlantis-workshop")
    msg := sprintf("S3 bucket %s must follow naming convention: terraform-atlantis-workshop-*", [resource.address])
}
