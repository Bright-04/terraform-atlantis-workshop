# Compliance Validation System Documentation

## Overview

The compliance validation system uses **native Terraform validation blocks** to enforce infrastructure policies and prevent violations before deployment. This system is built into the Terraform configuration and works seamlessly with both LocalStack and real AWS environments.

## 🎯 How It Works

### Core Components

1. **Validation Blocks**: Uses `lifecycle.precondition` blocks in `null_resource`
2. **Policy Rules**: Defined in `terraform/compliance-validation.tf`
3. **Real-time Detection**: Violations caught during `terraform plan`
4. **Clear Error Messages**: Specific violation details in PR comments
5. **Prevention**: Stops deployment when violations exist

### Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Terraform     │    │   Compliance     │    │   GitHub PR     │
│   Configuration │───▶│   Validation     │───▶│   Comments      │
│                 │    │   Engine         │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Resource      │    │   Policy Rules   │    │   Violation     │
│   Definitions   │    │   Enforcement    │    │   Messages      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📋 Current Policy Rules

### 1. Instance Type Restrictions

**Policy**: Only allow cost-effective instance types
**Allowed Types**: `t3.micro`, `t3.small`, `t3.medium`
**Prevents**: Expensive instance types like `m5.large`, `c5.xlarge`

```terraform
# Example violation
resource "aws_instance" "test" {
  instance_type = "m5.large"  # ❌ VIOLATION: Expensive instance type
}

# Compliant configuration
resource "aws_instance" "test" {
  instance_type = "t3.micro"  # ✅ COMPLIANT: Cost-effective instance type
}
```

### 2. Required Tags

**Policy**: All EC2 instances must have required tags
**Required Tags**: `Environment`, `Project`, `CostCenter`
**Prevents**: Untagged resources that can't be tracked

```terraform
# Example violation
resource "aws_instance" "test" {
  tags = {
    Name = "test-instance"
    # ❌ VIOLATION: Missing Environment, Project, CostCenter tags
  }
}

# Compliant configuration
resource "aws_instance" "test" {
  tags = {
    Name        = "test-instance"
    Environment = "workshop"           # ✅ COMPLIANT
    Project     = "terraform-atlantis-workshop"  # ✅ COMPLIANT
    CostCenter  = "workshop-training"  # ✅ COMPLIANT
  }
}
```

### 3. S3 Bucket Naming Convention

**Policy**: S3 buckets must follow naming convention
**Convention**: `terraform-atlantis-workshop-*`
**Prevents**: Inconsistent bucket naming

```terraform
# Example violation
resource "aws_s3_bucket" "test" {
  bucket = "my-bucket"  # ❌ VIOLATION: Doesn't follow naming convention
}

# Compliant configuration
resource "aws_s3_bucket" "test" {
  bucket = "terraform-atlantis-workshop-test"  # ✅ COMPLIANT: Follows convention
}
```

## 🔧 Implementation Details

### Validation Block Structure

```terraform
# Example validation block
resource "null_resource" "instance_type_validation" {
  triggers = {
    instances = join(",", [for k, v in local.ec2_instances : "${k}:${v.instance_type}"])
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for k, v in local.ec2_instances : contains(local.allowed_instance_types, v.instance_type)
      ])
      error_message = "❌ VIOLATION: Found expensive instance types. Only t3.micro, t3.small, t3.medium are permitted."
    }
  }
}
```

### Key Components

1. **Triggers**: Define when validation runs
2. **Condition**: Boolean expression that must be true
3. **Error Message**: Clear violation description
4. **Local Variables**: Define policy rules and resource collections

## 🚀 Usage Guide

### Testing Compliance Validation

1. **Introduce Violations** (for testing):

    ```terraform
    # In terraform/test-policy-violations.tf
    resource "aws_instance" "test_violation" {
      ami           = "ami-0abcdef1234567890"
      instance_type = "m5.large"  # VIOLATION: Expensive instance type
    }
    ```

2. **Run Plan**:

    ```bash
    cd terraform
    terraform plan
    ```

3. **See Violations**:

    ```
    ❌ VIOLATION: Found expensive instance types. Only t3.micro, t3.small, t3.medium are permitted.
    Current instances: policy_test=t3.small, test_violation=m5.large, web=t3.micro
    ```

4. **Fix Violations**:
    ```terraform
    resource "aws_instance" "test_violation" {
      ami           = "ami-0abcdef1234567890"
      instance_type = "t3.micro"  # Fixed: Compliant instance type
    }
    ```

### Testing in GitHub PR

1. **Create PR** with violations
2. **Comment**: `atlantis plan -p terraform-atlantis-workshop`
3. **Review** violation messages in PR comments
4. **Fix** violations and re-run plan

## 🔧 Extending the System

### Adding New Validation Rules

1. **Define Policy in Locals**:

    ```terraform
    locals {
      # Add new policy rules
      allowed_regions = ["us-east-1", "us-west-2"]
      max_volume_size = 100
    }
    ```

2. **Create Validation Block**:

    ```terraform
    resource "null_resource" "region_validation" {
      triggers = {
        regions = join(",", [for k, v in local.resources : "${k}:${v.region}"])
      }

      lifecycle {
        precondition {
          condition = alltrue([
            for k, v in local.resources : contains(local.allowed_regions, v.region)
          ])
          error_message = "❌ VIOLATION: Found resources in unauthorized regions. Only us-east-1, us-west-2 are permitted."
        }
      }
    }
    ```

3. **Test the Rule**:
    ```bash
    terraform plan  # Should fail if violations exist
    ```

### Adding Resource Types

1. **Update Locals**:

    ```terraform
    locals {
      # Add new resource type
      all_resources = {
        instances = local.ec2_instances
        buckets  = local.s3_buckets
        volumes  = local.ebs_volumes  # New resource type
      }
    }
    ```

2. **Create Resource Collection**:

    ```terraform
    locals {
      ebs_volumes = {
        data = aws_ebs_volume.data
        backup = aws_ebs_volume.backup
      }
    }
    ```

3. **Apply Validation Rules**:

    ```terraform
    # Add volume-specific validation
    resource "null_resource" "volume_size_validation" {
      triggers = {
        volumes = join(",", [for k, v in local.ebs_volumes : "${k}:${v.size}"])
      }

      lifecycle {
        precondition {
          condition = alltrue([
            for k, v in local.ebs_volumes : v.size <= local.max_volume_size
          ])
          error_message = "❌ VIOLATION: Found volumes larger than ${local.max_volume_size}GB."
        }
      }
    }
    ```

## 📊 Monitoring and Metrics

### Compliance Status Output

```terraform
output "compliance_validation_status" {
  description = "Compliance validation status"
  value = {
    total_instances = length(local.ec2_instances)
    total_buckets = length(local.s3_buckets)
    allowed_instance_types = local.allowed_instance_types
    required_tags = local.required_tags
    message = "Compliance validation framework active"
  }
}
```

### Key Metrics

-   **Total Resources**: Number of resources being validated
-   **Policy Rules**: Active policy rules and their configurations
-   **Validation Status**: Whether validation framework is active
-   **Compliance Rate**: Percentage of compliant resources

## 🛠️ Troubleshooting

### Common Issues

**Violations Not Detected**:

```bash
# Check if compliance-validation.tf is loaded
terraform validate
terraform plan

# Verify validation blocks are present
grep -r "precondition" terraform/
```

**False Positives**:

```bash
# Review validation rules
cat terraform/compliance-validation.tf

# Check resource configurations
terraform show
```

**Plan Fails Unexpectedly**:

```bash
# Check for syntax errors
terraform validate

# Review error messages for specific violations
terraform plan 2>&1 | grep "VIOLATION"
```

### Debugging Validation Rules

1. **Test Individual Rules**:

    ```bash
    # Comment out other validation blocks temporarily
    # Test one rule at a time
    terraform plan
    ```

2. **Check Resource References**:

    ```bash
    # Verify resources exist
    terraform state list

    # Check resource attributes
    terraform show -json | jq '.values.root_module.resources[]'
    ```

3. **Validate Local Variables**:
    ```bash
    # Check local variable values
    terraform console
    > local.allowed_instance_types
    > local.ec2_instances
    ```

## 🎯 Best Practices

### Policy Design

1. **Clear and Specific**: Define policies that are unambiguous
2. **Measurable**: Policies should be easily testable
3. **Reasonable**: Don't over-constrain legitimate use cases
4. **Documented**: Clearly document policy intent and exceptions

### Implementation

1. **Modular**: Organize validation rules logically
2. **Testable**: Include test cases for each policy
3. **Maintainable**: Use clear variable names and comments
4. **Extensible**: Design for easy addition of new rules

### Maintenance

1. **Regular Testing**: Test validation rules regularly
2. **Policy Reviews**: Review policies for relevance and effectiveness
3. **Documentation Updates**: Keep documentation current
4. **Team Training**: Ensure team understands policies and procedures

## 📚 Related Documentation

-   [Operational Procedures](OPERATIONS.md) - Day-to-day operations
-   [README.md](../readme.md) - Project overview and setup
-   [Workshop Info](../workshop_info.md) - Workshop requirements
-   [Monitoring](../monitoring/) - Health checks and monitoring

---

_This compliance validation system provides automated policy enforcement for infrastructure deployments, ensuring cost control, security, and operational consistency._
