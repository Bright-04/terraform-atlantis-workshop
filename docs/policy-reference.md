# Policy Reference - Terraform Atlantis Workshop

## 🛡️ Compliance Policy Documentation

This document provides comprehensive reference documentation for all Open Policy Agent (OPA) policies used in the **Environment Provisioning Automation with Terraform and Atlantis** workshop.

## 📋 Policy Overview

The workshop implements a robust policy-as-code framework using OPA and Rego language to ensure:

-   **Security Compliance**: Enforce security best practices
-   **Cost Control**: Prevent cost overruns and optimize spending
-   **Resource Governance**: Ensure proper resource management
-   **Operational Excellence**: Maintain operational standards

## 🗂️ Policy Structure

```
policies/
├── terraform_security.rego     # Security and compliance policies
├── cost_control.rego          # Cost management policies
├── resource_governance.rego   # Resource management policies (future)
└── operational_policies.rego  # Operational excellence policies (future)
```

## 🔒 Security Policies (terraform_security.rego)

### Policy Package

```rego
package terraform.security
```

### Required Tags Policy

#### Purpose

Ensures all critical resources have mandatory tags for tracking and management.

#### Policy Definition

```rego
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

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    not resource.change.after.tags.Owner
    msg := sprintf("EC2 instance %s must have Owner tag", [resource.address])
}
```

#### Required Tags

-   **Environment**: Deployment environment (dev, staging, production)
-   **Project**: Project identifier
-   **Owner**: Resource owner or team
-   **CostCenter**: Cost allocation identifier
-   **ManagedBy**: Management system identifier

#### Affected Resources

-   `aws_instance`
-   `aws_security_group`
-   `aws_vpc`
-   `aws_subnet`
-   `aws_s3_bucket`

---

### Security Group Policies

#### Overly Permissive Rules

```rego
# Deny security groups with overly permissive rules
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    ingress := resource.change.after.ingress[_]
    ingress.from_port == 0
    ingress.to_port == 65535
    msg := sprintf("Security group %s has overly permissive ingress rule (all ports)", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    ingress := resource.change.after.ingress[_]
    "0.0.0.0/0" in ingress.cidr_blocks
    ingress.from_port != 80
    ingress.from_port != 443
    msg := sprintf("Security group %s allows access from 0.0.0.0/0 on port %d", [resource.address, ingress.from_port])
}
```

#### SSH Access Restrictions

```rego
# Restrict SSH access
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    ingress := resource.change.after.ingress[_]
    ingress.from_port <= 22
    ingress.to_port >= 22
    "0.0.0.0/0" in ingress.cidr_blocks
    msg := sprintf("Security group %s allows SSH access from anywhere", [resource.address])
}
```

#### Database Port Protection

```rego
# Protect database ports
database_ports := [3306, 5432, 1433, 1521, 27017]

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    ingress := resource.change.after.ingress[_]
    port := database_ports[_]
    ingress.from_port <= port
    ingress.to_port >= port
    "0.0.0.0/0" in ingress.cidr_blocks
    msg := sprintf("Security group %s exposes database port %d to the internet", [resource.address, port])
}
```

---

### Encryption Policies

#### EBS Volume Encryption

```rego
# Ensure EBS volumes are encrypted
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    ebs_block_device := resource.change.after.ebs_block_device[_]
    not ebs_block_device.encrypted
    msg := sprintf("EBS volume for instance %s must be encrypted", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    not resource.change.after.encrypted
    msg := sprintf("EBS volume %s must be encrypted", [resource.address])
}
```

#### S3 Bucket Encryption

```rego
# Ensure S3 buckets have encryption enabled
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.server_side_encryption_configuration
    msg := sprintf("S3 bucket %s must have server-side encryption enabled", [resource.address])
}

# Ensure S3 buckets are not publicly readable
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_acl"
    resource.change.after.acl == "public-read"
    msg := sprintf("S3 bucket ACL %s must not be public-read", [resource.address])
}
```

---

### Network Security Policies

#### VPC Configuration

```rego
# Ensure VPC uses private IP ranges
private_cidrs := ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    cidr := resource.change.after.cidr_block
    not is_private_cidr(cidr)
    msg := sprintf("VPC %s CIDR %s must use private IP ranges", [resource.address, cidr])
}

is_private_cidr(cidr) {
    private_cidr := private_cidrs[_]
    net.cidr_contains(private_cidr, cidr)
}
```

#### Subnet Configuration

```rego
# Ensure private subnets don't auto-assign public IPs
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_subnet"
    contains(resource.change.after.tags.Name, "private")
    resource.change.after.map_public_ip_on_launch == true
    msg := sprintf("Private subnet %s should not auto-assign public IPs", [resource.address])
}
```

## 💰 Cost Control Policies (cost_control.rego)

### Policy Package

```rego
package terraform.cost
```

### Instance Type Restrictions

#### Expensive Instance Types

```rego
# Prevent expensive instance types in workshop environment
expensive_instance_types := [
    "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
    "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge",
    "r5.large", "r5.xlarge", "r5.2xlarge", "r5.4xlarge"
]

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance_type := resource.change.after.instance_type
    instance_type in expensive_instance_types
    msg := sprintf("Instance %s uses expensive instance type %s. Consider t3.micro, t3.small, or t3.medium for workshop", [resource.address, instance_type])
}
```

#### Allowed Instance Types

```rego
# Define allowed instance types for cost control
allowed_instance_types := [
    "t3.micro", "t3.small", "t3.medium",
    "t3a.micro", "t3a.small", "t3a.medium",
    "t2.micro", "t2.small", "t2.medium"
]

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance_type := resource.change.after.instance_type
    not instance_type in allowed_instance_types
    msg := sprintf("Instance %s uses instance type %s which is not in the approved list: %v", [resource.address, instance_type, allowed_instance_types])
}
```

---

### Cost Allocation and Tracking

#### Required Cost Tags

```rego
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
    msg := sprintf("S3 bucket %s must have CostCenter tag for cost tracking", [resource.address])
}

# Require AutoShutdown tag for cost optimization
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    not resource.change.after.tags.AutoShutdown
    msg := sprintf("Instance %s must have AutoShutdown tag for cost control", [resource.address])
}
```

---

### Resource Limits

#### Instance Count Limits

```rego
# Limit number of EC2 instances to prevent cost runaway
max_instances := 5

deny[msg] {
    instance_count := count([resource |
        resource := input.resource_changes[_]
        resource.type == "aws_instance"
        resource.change.actions[_] == "create"
    ])
    instance_count > max_instances
    msg := sprintf("Cannot create %d instances. Maximum allowed is %d instances.", [instance_count, max_instances])
}
```

#### Volume Size Limits

```rego
# Limit EBS volume sizes
max_volume_size := 100  # GB

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    size := resource.change.after.size
    size > max_volume_size
    msg := sprintf("EBS volume %s size %dGB exceeds maximum allowed size of %dGB", [resource.address, size, max_volume_size])
}
```

---

### Cost Estimation

#### Monthly Cost Calculation

```rego
# Calculate estimated monthly costs
instance_costs := {
    "t3.micro": 8.76,
    "t3.small": 17.52,
    "t3.medium": 35.04,
    "t3.large": 70.08,
    "t3a.micro": 7.88,
    "t3a.small": 15.77,
    "t3a.medium": 31.54
}

monthly_cost_estimate[cost] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    resource.change.actions[_] == "create"
    instance_type := resource.change.after.instance_type
    cost := instance_costs[instance_type]
}

# Deny if total estimated cost exceeds budget
deny[msg] {
    total_cost := sum(monthly_cost_estimate)
    budget_limit := 100  # USD per month
    total_cost > budget_limit
    msg := sprintf("Estimated monthly cost $%.2f exceeds budget limit of $%.2f", [total_cost, budget_limit])
}

# Warn about high-cost deployments
warn[msg] {
    total_cost := sum(monthly_cost_estimate)
    warning_threshold := 75  # USD per month
    total_cost > warning_threshold
    total_cost <= 100  # Below deny threshold
    msg := sprintf("High estimated monthly cost: $%.2f (Warning threshold: $%.2f)", [total_cost, warning_threshold])
}
```

## 🔧 Resource Governance Policies

### Naming Conventions

#### Resource Naming Standards

```rego
package terraform.governance

# Enforce naming conventions
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    name := resource.change.after.tags.Name
    not regex.match("^[a-z0-9-]+$", name)
    msg := sprintf("Instance %s name must use lowercase letters, numbers, and hyphens only", [resource.address])
}

# Ensure resource names include environment
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_instance", "aws_security_group", "aws_vpc"]
    name := resource.change.after.tags.Name
    environment := resource.change.after.tags.Environment
    not contains(name, environment)
    msg := sprintf("Resource %s name should include environment %s", [resource.address, environment])
}
```

---

### Lifecycle Management

#### Termination Protection

```rego
# Require termination protection for production resources
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    environment := resource.change.after.tags.Environment
    environment == "production"
    not resource.change.after.disable_api_termination
    msg := sprintf("Production instance %s must have termination protection enabled", [resource.address])
}
```

#### Backup Requirements

```rego
# Require backup configuration for persistent storage
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    environment := resource.change.after.tags.Environment
    environment in ["staging", "production"]
    not resource.change.after.tags.BackupSchedule
    msg := sprintf("EBS volume %s in %s environment must have BackupSchedule tag", [resource.address, environment])
}
```

## 🏃‍♂️ Operational Excellence Policies

### Monitoring Requirements

#### CloudWatch Integration

```rego
package terraform.operations

# Require detailed monitoring for production instances
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    environment := resource.change.after.tags.Environment
    environment == "production"
    not resource.change.after.monitoring
    msg := sprintf("Production instance %s must have detailed monitoring enabled", [resource.address])
}
```

#### Log Configuration

```rego
# Require log group configuration
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    environment := resource.change.after.tags.Environment
    environment in ["staging", "production"]
    not resource.change.after.tags.LogGroup
    msg := sprintf("Instance %s in %s environment must have LogGroup tag specified", [resource.address, environment])
}
```

## 🧪 Policy Testing

### Test Framework

#### Policy Test Structure

```rego
package terraform.security

test_instance_requires_environment_tag {
    deny[_] with input as {
        "resource_changes": [{
            "type": "aws_instance",
            "address": "aws_instance.test",
            "change": {
                "after": {
                    "tags": {}
                }
            }
        }]
    }
}

test_instance_with_environment_tag_passes {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "type": "aws_instance",
            "address": "aws_instance.test",
            "change": {
                "after": {
                    "tags": {
                        "Environment": "production",
                        "Project": "workshop",
                        "Owner": "devops"
                    }
                }
            }
        }]
    }
}
```

#### Running Tests

```bash
# Test all policies
opa test policies/ --verbose

# Test specific policy
opa test policies/terraform_security.rego --verbose

# Test with coverage
opa test --coverage policies/
```

## 📊 Policy Metrics and Reporting

### Policy Violation Tracking

#### Violation Categories

-   **Security**: Critical security violations
-   **Cost**: Cost control violations
-   **Governance**: Resource governance violations
-   **Operations**: Operational excellence violations

#### Metrics Collection

```rego
# Count policy violations by type
violation_count[violation_type] = count {
    violation_type := "security"
    deny[_] with input as security_test_input
}

violation_count[violation_type] = count {
    violation_type := "cost"
    deny[_] with input as cost_test_input
}
```

### Reporting Integration

#### Atlantis Integration

Policies are automatically executed during Atlantis plan operations:

1. **Plan Phase**: Policies evaluated against planned changes
2. **Policy Check**: Pass/fail determination
3. **Comment Generation**: Violation details posted to PR
4. **Apply Blocking**: Failed policies prevent apply

#### CI/CD Integration

```yaml
# GitHub Actions workflow
- name: Policy Validation
  run: |
      terraform plan -out=tfplan
      terraform show -json tfplan | opa eval --data policies/ --input - "data.terraform.security.deny[x]"
```

## 🔧 Policy Configuration

### OPA Server Configuration

#### Server Configuration

```yaml
# opa-server.yaml
services:
    authz:
        url: http://opa-server:8181

bundles:
    terraform:
        resource: "/v1/bundles/terraform"
        persist: true
        polling:
            min_delay_seconds: 10
            max_delay_seconds: 20
```

#### Policy Bundle

```json
{
	"bundles": {
		"terraform": {
			"resource": "/bundles/terraform.tar.gz"
		}
	}
}
```

### Atlantis Policy Configuration

#### Policy Check Configuration

```yaml
# atlantis.yaml
version: 3
projects:
    - name: terraform-atlantis-workshop
      policy_check: true

workflows:
    aws-production:
        policy_check:
            steps:
                - run: |
                      echo "🛡️ Running security policy validation..."
                      opa test policies/ --verbose
                      if [ $? -ne 0 ]; then
                          echo "❌ Security policy validation failed"
                          exit 1
                      fi
                      echo "✅ Security policies validated"
```

## 📋 Policy Best Practices

### Writing Effective Policies

1. **Clear Messaging**: Provide clear, actionable error messages
2. **Specific Rules**: Write specific, testable rules
3. **Performance**: Optimize for policy evaluation performance
4. **Maintainability**: Keep policies modular and well-documented
5. **Testing**: Include comprehensive test coverage

### Policy Lifecycle

1. **Development**: Write and test policies locally
2. **Testing**: Validate with test data and scenarios
3. **Staging**: Deploy to staging environment
4. **Production**: Deploy to production with monitoring
5. **Monitoring**: Track policy effectiveness and violations
6. **Updates**: Regular review and updates

### Common Patterns

#### Conditional Policies

```rego
# Apply policy only to specific environments
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    environment := resource.change.after.tags.Environment
    environment == "production"
    # Production-specific rules here
}
```

#### Helper Functions

```rego
# Reusable helper functions
is_public_subnet(subnet) {
    subnet.map_public_ip_on_launch == true
}

has_required_tags(resource, required_tags) {
    required_tag := required_tags[_]
    resource.change.after.tags[required_tag]
}
```

---

**🔒 Security Note:**
Policies are enforced automatically during Terraform plan operations. All policy violations must be resolved before infrastructure changes can be applied.

**📚 Additional Resources:**

-   [Open Policy Agent Documentation](https://www.openpolicyagent.org/docs/)
-   [Rego Language Reference](https://www.openpolicyagent.org/docs/latest/policy-language/)
-   [Terraform JSON Output Format](https://www.terraform.io/docs/internals/json-format.html)
-   [Atlantis Policy Checks](https://www.runatlantis.io/docs/policy-checking.html)

**Last Updated**: August 2025  
**Version**: 1.0  
**Author**: Nguyen Nhat Quang (Bright-04)
