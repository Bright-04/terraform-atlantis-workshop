# Cost Control and Resource Management Policies
package terraform.cost

import rego.v1

# Cost-related validations
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    resource.change.after.instance_type in ["m5.large", "m5.xlarge", "c5.large", "c5.xlarge"]
    msg := sprintf("Instance %s uses expensive instance type. Consider smaller instances for workshop environment", [resource.address])
}

# Require cost allocation tags
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type in ["aws_instance", "aws_s3_bucket", "aws_ebs_volume"]
    not resource.change.after.tags.CostCenter
    msg := sprintf("Resource %s must have CostCenter tag for cost tracking", [resource.address])
}

# Validate resource naming conventions
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not startswith(resource.change.after.bucket, "terraform-atlantis-workshop")
    msg := sprintf("S3 bucket %s must follow naming convention: terraform-atlantis-workshop-*", [resource.address])
}

# Prevent creation of expensive resources
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type in ["aws_rds_instance", "aws_elasticsearch_domain", "aws_redshift_cluster"]
    msg := sprintf("Resource type %s is not allowed in workshop environment for cost control", [resource.type])
}
