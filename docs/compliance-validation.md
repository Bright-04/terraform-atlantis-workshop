# Compliance Validation - Terraform Atlantis Workshop

## 🛡️ Compliance Validation System

This document provides comprehensive information about the **Compliance Validation System** implemented in the Terraform Atlantis Workshop, including policy rules, validation mechanisms, and enforcement procedures.

## 📋 Overview

The compliance validation system uses **native Terraform validation blocks** to enforce organizational policies and best practices during infrastructure deployment. This ensures that all infrastructure changes comply with security, cost, and operational requirements before deployment.

## 🏗️ System Architecture

### Validation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                Terraform Configuration                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Resource      │  │   Validation    │  │   Error     │ │
│  │   Definitions   │  │   Blocks        │  │   Messages  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                Validation Engine                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Instance      │  │   Tag           │  │   S3        │ │
│  │   Type Check    │  │   Validation    │  │   Naming    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                Output Processing                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Violation     │  │   Success       │  │   GitHub    │ │
│  │   Detection     │  │   Confirmation  │  │   Comments  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

1. **Validation Blocks**: Native Terraform `lifecycle.precondition` blocks
2. **Policy Rules**: Defined compliance requirements
3. **Error Messages**: Clear violation descriptions
4. **Integration**: Works with Atlantis GitOps workflow

## 📜 Policy Rules

### 1. Instance Type Validation

#### Policy: Cost Control

**Objective**: Ensure only cost-effective instance types are deployed

**Allowed Instance Types**:

-   `t3.micro` (2 vCPU, 1 GB RAM)
-   `t3.small` (2 vCPU, 2 GB RAM)
-   `t3.medium` (2 vCPU, 4 GB RAM)

**Implementation**:

```hcl
# terraform/compliance-validation.tf
resource "aws_instance" "web" {
  # ... other configuration ...

  lifecycle {
    precondition {
      condition = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
      error_message = "Instance type must be t3.micro, t3.small, or t3.medium for cost control. Current type: ${var.instance_type}"
    }
  }
}
```

**Violation Example**:

```
❌ VIOLATION: Instance type must be t3.micro, t3.small, or t3.medium for cost control. Current type: m5.large
```

### 2. Required Tags Validation

#### Policy: Resource Management

**Objective**: Ensure all resources are properly tagged for cost allocation and management

**Required Tags**:

-   `Environment` (e.g., production, development, staging)
-   `Project` (e.g., terraform-atlantis-workshop)
-   `CostCenter` (e.g., IT-001, DEV-002)

**Implementation**:

```hcl
# terraform/compliance-validation.tf
resource "aws_instance" "web" {
  # ... other configuration ...

  lifecycle {
    precondition {
      condition = alltrue([
        contains(keys(var.tags), "Environment"),
        contains(keys(var.tags), "Project"),
        contains(keys(var.tags), "CostCenter")
      ])
      error_message = "Required tags must be present: Environment, Project, CostCenter. Current tags: ${jsonencode(keys(var.tags))}"
    }
  }
}
```

**Violation Example**:

```
❌ VIOLATION: Required tags must be present: Environment, Project, CostCenter. Current tags: ["Name", "Owner"]
```

### 3. S3 Bucket Naming Validation

#### Policy: Naming Convention

**Objective**: Ensure consistent S3 bucket naming for organization and security

**Naming Convention**: `terraform-atlantis-workshop-*`

**Implementation**:

```hcl
# terraform/compliance-validation.tf
resource "aws_s3_bucket" "data" {
  # ... other configuration ...

  lifecycle {
    precondition {
      condition = can(regex("^terraform-atlantis-workshop-", var.bucket_name))
      error_message = "S3 bucket must follow naming convention: terraform-atlantis-workshop-*. Current name: ${var.bucket_name}"
    }
  }
}
```

**Violation Example**:

```
❌ VIOLATION: S3 bucket must follow naming convention: terraform-atlantis-workshop-*. Current name: my-data-bucket
```

## 🔧 Implementation Details

### Validation Block Structure

```hcl
lifecycle {
  precondition {
    condition = <boolean_expression>
    error_message = "<clear_error_message>"
  }
}
```

### Key Features

1. **Native Terraform**: Uses built-in validation capabilities
2. **Real-time Detection**: Violations caught during `terraform plan`
3. **Clear Messages**: Specific error descriptions
4. **Prevention**: Stops deployment when violations exist
5. **Integration**: Works seamlessly with Atlantis

### File Organization

```
terraform/
├── compliance-validation.tf    # Main validation rules
├── test-policy-violations.tf   # Test resources for validation
├── main-aws.tf                # Infrastructure with validation
└── variables.tf               # Variables used in validation
```

## 🧪 Testing Compliance Validation

### Test Setup

#### Step 1: Introduce Violations

```hcl
# terraform/test-policy-violations.tf
resource "aws_instance" "test_violation" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "m5.large"  # VIOLATION: Expensive instance type

  tags = {
    Name = "test-violation"
    # VIOLATION: Missing required tags
  }
}

resource "aws_s3_bucket" "test_violation" {
  bucket = "my-violating-bucket"  # VIOLATION: Wrong naming convention
}
```

#### Step 2: Run Validation

```powershell
# Navigate to terraform directory
cd terraform

# Run terraform plan to trigger validation
terraform plan
```

#### Step 3: Review Violations

Expected output will show violations:

```
❌ VIOLATION: Instance type must be t3.micro, t3.small, or t3.medium for cost control. Current type: m5.large
❌ VIOLATION: Required tags must be present: Environment, Project, CostCenter. Current tags: ["Name"]
❌ VIOLATION: S3 bucket must follow naming convention: terraform-atlantis-workshop-*. Current name: my-violating-bucket
```

### Test Cleanup

```powershell
# Remove test violations
Remove-Item test-policy-violations.tf

# Run plan again to verify no violations
terraform plan
```

## 🔄 Integration with Atlantis

### GitOps Workflow Integration

1. **Pull Request Creation**: Developer creates PR with infrastructure changes
2. **Automatic Planning**: Atlantis runs `terraform plan`
3. **Validation Execution**: Compliance rules are checked
4. **Violation Detection**: Any violations are reported in PR comments
5. **Approval Process**: PR cannot be approved with violations
6. **Clean Deployment**: Only compliant changes are applied

### Atlantis Configuration

```yaml
# atlantis.yaml
version: 3
projects:
    - name: terraform-atlantis-workshop
      dir: terraform
      workspace: default
      terraform_version: v1.6.0
      autoplan:
          when_modified: ["*.tf", "../.gitmodules"]
          enabled: true
      apply_requirements: [approved]
```

### GitHub Integration

```bash
# Example PR comment for Atlantis
atlantis plan -p terraform-atlantis-workshop
```

## 📊 Compliance Monitoring

### Validation Status Tracking

#### Success Indicators

-   ✅ **No Violations**: All resources comply with policies
-   ✅ **Clear Output**: Validation passes without errors
-   ✅ **Deployment Ready**: Infrastructure can be deployed

#### Violation Indicators

-   ❌ **Policy Violations**: Resources don't meet requirements
-   ❌ **Error Messages**: Clear descriptions of violations
-   ❌ **Deployment Blocked**: Cannot proceed until violations fixed

### Monitoring Scripts

#### Health Check Integration

```powershell
# scripts/04-health-monitoring.ps1
Write-Host "🔍 Checking compliance validation..."

# Run compliance check
cd terraform
terraform plan -detailed-exitcode

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compliance validation passed"
} else {
    Write-Host "❌ Compliance validation failed"
    exit 1
}
```

#### Cost Monitoring Integration

```powershell
# scripts/05-cost-monitoring.ps1
Write-Host "💰 Checking cost compliance..."

# Verify instance types
$instances = aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceType' --output text
$compliant_types = @("t3.micro", "t3.small", "t3.medium")

foreach ($instance in $instances) {
    if ($instance -notin $compliant_types) {
        Write-Host "❌ Non-compliant instance type found: $instance"
    }
}
```

## 🛠️ Customizing Validation Rules

### Adding New Policies

#### Step 1: Define Policy

```hcl
# Example: Security Group Validation
resource "aws_security_group" "web" {
  # ... configuration ...

  lifecycle {
    precondition {
      condition = length(var.allowed_ports) <= 5
      error_message = "Maximum 5 ports allowed for security. Current: ${length(var.allowed_ports)}"
    }
  }
}
```

#### Step 2: Test Policy

```powershell
# Test new validation rule
terraform plan

# Verify policy enforcement
# Check error messages are clear
```

#### Step 3: Document Policy

```markdown
## Security Group Policy

-   **Objective**: Limit number of open ports
-   **Rule**: Maximum 5 ports per security group
-   **Implementation**: Validation block in security group resource
```

### Modifying Existing Policies

#### Instance Type Policy Update

```hcl
# Add new allowed instance type
condition = contains(["t3.micro", "t3.small", "t3.medium", "t3.large"], var.instance_type)
```

#### Tag Policy Update

```hcl
# Add new required tag
condition = alltrue([
  contains(keys(var.tags), "Environment"),
  contains(keys(var.tags), "Project"),
  contains(keys(var.tags), "CostCenter"),
  contains(keys(var.tags), "Owner")  # New required tag
])
```

## 🚨 Troubleshooting Validation Issues

### Common Issues

#### Issue: Validation Not Triggered

```powershell
# Solution: Check file inclusion
# Ensure compliance-validation.tf is included in main configuration
# Verify terraform plan is running
```

#### Issue: False Positives

```powershell
# Solution: Review validation logic
# Check variable values and conditions
# Test with different scenarios
```

#### Issue: Unclear Error Messages

```powershell
# Solution: Improve error messages
# Add more context to error_message
# Include current values in messages
```

### Debugging Validation

#### Enable Debug Output

```powershell
# Run with debug information
terraform plan -var-file=terraform.tfvars -detailed-exitcode

# Check specific resources
terraform plan -target=aws_instance.web
```

#### Review Validation Logic

```hcl
# Add debug output
output "validation_debug" {
  value = {
    instance_type = var.instance_type
    allowed_types = ["t3.micro", "t3.small", "t3.medium"]
    is_compliant  = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
  }
}
```

## 📈 Best Practices

### Policy Design

1. **Clear Objectives**: Define specific policy goals
2. **Measurable Rules**: Use quantifiable validation criteria
3. **User-Friendly Messages**: Provide clear error descriptions
4. **Consistent Enforcement**: Apply rules uniformly across resources

### Implementation

1. **Modular Design**: Separate validation logic from resource definitions
2. **Comprehensive Testing**: Test all validation scenarios
3. **Documentation**: Document all policies and their purposes
4. **Version Control**: Track policy changes over time

### Maintenance

1. **Regular Review**: Periodically review and update policies
2. **Performance Monitoring**: Ensure validation doesn't impact deployment speed
3. **User Feedback**: Collect feedback on policy effectiveness
4. **Continuous Improvement**: Refine policies based on operational experience

## 📞 Support and Resources

### Getting Help

-   **Documentation**: Check [Troubleshooting Guide](troubleshooting-guide.md)
-   **FAQ**: Review [FAQ](faq.md)
-   **Issues**: Create GitHub issue with validation details
-   **Contact**: cbl.nguyennhatquang2809@gmail.com

### Additional Resources

-   **Terraform Documentation**: https://www.terraform.io/docs
-   **Terraform Validation**: https://www.terraform.io/docs/language/expressions/custom-conditions.html
-   **AWS Best Practices**: https://aws.amazon.com/architecture/well-architected/

---

**📚 Related Documentation**

-   [Quick Start Guide](quick-start-guide.md)
-   [Architecture Overview](architecture-overview.md)
-   [Deployment Procedures](deployment-procedures.md)
-   [Troubleshooting Guide](troubleshooting-guide.md)
