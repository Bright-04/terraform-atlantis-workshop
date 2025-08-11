# Compliance and Policy Validation Guide

## 🎯 Overview

This guide covers implementing and testing compliance policies in your Terraform infrastructure. You'll learn how to enforce security, cost, and operational policies using Terraform's validation framework.

## 📋 Prerequisites

Before starting this guide, ensure you have:

-   ✅ **Infrastructure deployed** to AWS (04-AWS-DEPLOYMENT.md)
-   ✅ **Understanding of Terraform** (02-INFRASTRUCTURE.md)
-   ✅ **Basic knowledge** of compliance concepts

## 🏗️ Compliance Framework Overview

### **What is Compliance?**

Compliance ensures your infrastructure follows:

-   **Security policies** (encryption, access controls)
-   **Cost policies** (instance types, resource limits)
-   **Operational policies** (naming conventions, tagging)
-   **Regulatory requirements** (GDPR, HIPAA, etc.)

### **Compliance Framework Components**

```
┌─────────────────────────────────────────────────────────────┐
│                    Compliance Framework                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Policy Rules  │    │   Validation    │                │
│  │                 │    │   Engine        │                │
│  │ • Cost Control  │───▶│                 │                │
│  │ • Security      │    │ • Terraform     │                │
│  │ • Operational   │    │ • Preconditions │                │
│  │ • Regulatory    │    │ • Lifecycle     │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                        │
│           ▼                       ▼                        │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Violation     │    │   Enforcement   │                │
│  │   Detection     │    │   Actions       │                │
│  │                 │    │                 │                │
│  │ • Error Messages│    │ • Block Deploy  │                │
│  │ • Warnings      │    │ • Auto Fix      │                │
│  │ • Reports       │    │ • Notifications │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Policy Implementation

### **1. Understanding the Compliance Framework**

The workshop uses Terraform's built-in validation features:

```hcl
# Example from compliance-validation.tf
locals {
  # Compliance rules
  allowed_instance_types = ["t3.micro", "t3.small", "t3.medium"]
  required_tags = ["Environment", "Project", "CostCenter"]

  # Get all EC2 instances for validation
  ec2_instances = {
    web = aws_instance.web
    policy_test = aws_instance.policy_test
  }
}

# Validation block for instance types
resource "null_resource" "instance_type_validation" {
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

### **2. Policy Categories**

#### **Cost Control Policies**

```hcl
# Instance type restrictions
allowed_instance_types = ["t3.micro", "t3.small", "t3.medium"]

# Storage size limits
max_ebs_size = 100  # GB

# Resource count limits
max_instances = 5
```

#### **Security Policies**

```hcl
# Required encryption
encryption_required = true

# Security group restrictions
allowed_ports = [22, 80, 443]

# Tag requirements
required_tags = ["Environment", "Project", "CostCenter"]
```

#### **Operational Policies**

```hcl
# Naming conventions
naming_pattern = "^terraform-atlantis-workshop-"

# Environment restrictions
allowed_environments = ["development", "staging", "production"]

# Backup requirements
backup_required = true
```

## 🧪 Testing Policy Violations

### **1. Understanding Test Violations**

The workshop includes test files that intentionally violate policies:

```hcl
# test-policy-violations.tf
resource "aws_instance" "test_violation" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"  # This is now compliant

  tags = {
    Name        = "test-violation-instance"
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"  # Added missing tag
  }
}
```

### **2. Testing Cost Violations**

#### **Create Expensive Instance Type**

```hcl
# Temporarily modify test-policy-violations.tf
resource "aws_instance" "test_violation" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "m5.large"  # Expensive instance type

  tags = {
    Name        = "test-violation-instance"
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}
```

#### **Test the Violation**

```bash
# Plan to see the violation
terraform plan

# Expected error:
# ❌ VIOLATION: Found expensive instance types. Only t3.micro, t3.small, t3.medium are permitted.
```

### **3. Testing Tag Violations**

#### **Remove Required Tags**

```hcl
# Temporarily modify main.tf
resource "aws_instance" "web" {
  # ... other configuration ...

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    # Project     = var.project_name  # Comment out this line
    Owner       = "workshop-participant"
    CostCenter  = "production"
  }
}
```

#### **Test the Violation**

```bash
# Plan to see the violation
terraform plan

# Expected error:
# ❌ VIOLATION: EC2 instances missing required tags (Environment, Project, CostCenter).
```

### **4. Testing S3 Naming Violations**

#### **Create Non-Compliant Bucket**

```hcl
# Temporarily modify test-policy-violations.tf
resource "aws_s3_bucket" "test_violation" {
  bucket = "my-non-compliant-bucket"  # Doesn't follow naming convention

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}
```

#### **Test the Violation**

```bash
# Plan to see the violation
terraform plan

# Expected error:
# ❌ VIOLATION: S3 buckets must follow naming convention: terraform-atlantis-workshop-*.
```

## 🔧 Fixing Policy Violations

### **1. Fixing Instance Type Violations**

```hcl
# Change expensive instance type to compliant one
resource "aws_instance" "test_violation" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"  # Fixed: Changed from m5.large

  tags = {
    Name        = "test-violation-instance"
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}
```

### **2. Fixing Tag Violations**

```hcl
# Add missing required tags
resource "aws_instance" "web" {
  # ... other configuration ...

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    Project     = var.project_name  # Fixed: Added missing tag
    Owner       = "workshop-participant"
    CostCenter  = "production"
  }
}
```

### **3. Fixing Naming Violations**

```hcl
# Follow naming convention
resource "aws_s3_bucket" "test_violation" {
  bucket = "terraform-atlantis-workshop-test-violation"  # Fixed: Follows naming convention

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}
```

## 📊 Compliance Monitoring

### **1. Check Compliance Status**

```bash
# View compliance validation outputs
terraform output compliance_validation_status

# Expected output:
# {
#   "total_instances" = 2
#   "total_buckets" = 2
#   "allowed_instance_types" = ["t3.micro", "t3.small", "t3.medium"]
#   "required_tags" = ["Environment", "Project", "CostCenter"]
#   "message" = "Compliance validation framework active"
# }
```

### **2. View Compliance Rules**

```bash
# View active compliance rules
terraform output compliance_rules

# Expected output:
# {
#   "cost_control" = {
#     "allowed_instance_types" = ["t3.micro", "t3.small", "t3.medium"]
#     "required_tags" = ["Environment", "Project", "CostCenter"]
#   }
#   "security" = {
#     "encryption_required" = true
#     "s3_naming_convention" = "terraform-atlantis-workshop-*"
#   }
# }
```

### **3. Compliance Reporting**

```bash
# Create compliance report
terraform plan -out=compliance-plan.tfplan

# Check for violations in plan output
terraform show compliance-plan.tfplan | grep -i violation
```

## 🔄 Compliance Workflow

### **1. Development Workflow**

```bash
# 1. Make changes to Terraform files
# 2. Run validation
terraform validate

# 3. Plan deployment
terraform plan

# 4. Fix any violations
# 5. Re-run plan until clean
terraform plan

# 6. Apply changes
terraform apply
```

### **2. GitOps Compliance Workflow**

```bash
# 1. Create feature branch
git checkout -b feature/new-resource

# 2. Make infrastructure changes
# 3. Commit changes
git add .
git commit -m "Add new infrastructure resource"

# 4. Push to repository
git push origin feature/new-resource

# 5. Create pull request
# 6. Atlantis will automatically validate compliance
# 7. Fix violations if any
# 8. Merge after approval
```

## 🚨 Advanced Compliance Features

### **1. Custom Policy Rules**

```hcl
# Add custom compliance rules
locals {
  # Custom cost control
  max_monthly_cost = 100  # USD

  # Custom security rules
  required_encryption_algorithms = ["AES256"]

  # Custom operational rules
  backup_retention_days = 30
}

# Custom validation
resource "null_resource" "custom_validation" {
  lifecycle {
    precondition {
      condition = var.environment != "production" || var.backup_enabled
      error_message = "❌ VIOLATION: Production environments must have backup enabled."
    }
  }
}
```

### **2. Policy Enforcement Levels**

```hcl
# Different enforcement levels
locals {
  enforcement_level = "strict"  # strict, warning, disabled

  # Strict enforcement - blocks deployment
  strict_policies = ["cost_control", "security"]

  # Warning enforcement - allows deployment with warnings
  warning_policies = ["operational", "naming"]
}
```

### **3. Compliance Notifications**

```bash
# Set up compliance notifications
# Example: Send violations to Slack/Teams
# Example: Create JIRA tickets for violations
# Example: Email notifications for critical violations
```

## 📋 Compliance Checklist

Before considering compliance complete, verify:

-   [ ] **All policies defined** and implemented
-   [ ] **Violations tested** and working correctly
-   [ ] **Fixes implemented** for all violations
-   [ ] **Compliance monitoring** active
-   [ ] **Documentation updated** with policies
-   [ ] **Team trained** on compliance requirements
-   [ ] **Automated validation** in CI/CD pipeline

## 🎯 Best Practices

### **1. Policy Design**

-   **Start Simple**: Begin with basic policies and expand
-   **Be Specific**: Define clear, measurable policies
-   **Consider Impact**: Balance security with usability
-   **Document Everything**: Keep policy documentation updated

### **2. Implementation**

-   **Test Thoroughly**: Test all policies before production
-   **Gradual Rollout**: Implement policies incrementally
-   **Monitor Impact**: Track policy effectiveness
-   **Regular Reviews**: Review and update policies regularly

### **3. Maintenance**

-   **Automate Validation**: Use CI/CD for automatic validation
-   **Regular Audits**: Conduct regular compliance audits
-   **Update Policies**: Keep policies current with requirements
-   **Train Team**: Ensure team understands policies

## 🚨 Troubleshooting

### **1. Common Issues**

#### **False Positives**

```bash
# If policies are too strict, adjust them
# Example: Add more allowed instance types
allowed_instance_types = ["t3.micro", "t3.small", "t3.medium", "t3.large"]
```

#### **Missing Validations**

```bash
# If violations aren't caught, check validation logic
# Example: Verify precondition conditions
terraform validate
```

#### **Performance Issues**

```bash
# If validation is slow, optimize conditions
# Example: Use more efficient data structures
```

### **2. Debugging Commands**

```bash
# Check validation logic
terraform console
> local.allowed_instance_types

# Test specific conditions
terraform plan -target=null_resource.instance_type_validation

# View detailed validation output
terraform plan -detailed-exitcode
```

## 📞 Support

If you encounter compliance issues:

1. **Review policy definitions** carefully
2. **Check validation logic** for errors
3. **Test policies individually** to isolate issues
4. **Consult documentation** for policy syntax
5. **Check troubleshooting guide** (09-TROUBLESHOOTING.md)

---

**Compliance working?** Continue to [06-ATLANTIS.md](06-ATLANTIS.md) to set up GitOps workflows!
