# Cost Control and Resource Management Policies
package main

# Cost-related validations
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    expensive_types := ["m5.large", "m5.xlarge", "c5.large", "c5.xlarge"]
    expensive_types[_] == resource.change.after.instance_type
    msg := sprintf("Instance %s uses expensive instance type. Consider smaller instances for workshop environment", [resource.address])
}

# Require cost allocation tags
deny[msg] {
    resource := input.resource_changes[_]
    allowed_types := ["aws_instance", "aws_s3_bucket", "aws_ebs_volume"]
    allowed_types[_] == resource.type
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

# Prevent creation of expensive resources
deny[msg] {
    resource := input.resource_changes[_]
    expensive_resources := ["aws_rds_instance", "aws_elasticsearch_domain", "aws_redshift_cluster"]
    expensive_resources[_] == resource.type
    msg := sprintf("Resource type %s is not allowed in workshop environment for cost control", [resource.type])
}
