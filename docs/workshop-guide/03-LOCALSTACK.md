# Local Development Guide

## 🎯 Overview

This guide covers local development practices for your Terraform infrastructure. You'll learn how to test and validate your configurations locally before deploying to AWS.

## 📋 Prerequisites

Before starting this guide, ensure you have:

- ✅ **Environment set up** (01-SETUP.md)
- ✅ **Terraform installed** and working
- ✅ **Understanding of infrastructure** (02-INFRASTRUCTURE.md)

## 🏠 Local Development Workflow

### **1. Local Testing Strategy**

Instead of using LocalStack, we'll focus on:
- **Terraform validation** and syntax checking
- **Configuration testing** with dry-run plans
- **Policy validation** testing
- **Code quality** checks

### **2. Terraform Validation**

```bash
# Navigate to terraform directory
cd terraform

# Validate configuration syntax
terraform validate

# Format code for consistency
terraform fmt

# Check for security issues
terraform fmt -check
```

### **3. Configuration Testing**

```bash
# Test with different variable values
terraform plan -var="instance_type=t3.small"
terraform plan -var="environment=development"

# Test with custom variable file
terraform plan -var-file="test.tfvars"
```

### **4. Policy Validation Testing**

```bash
# Test compliance policies locally
terraform plan

# Look for compliance validation outputs
terraform output compliance_validation_status

# Test policy violations
# Modify test-policy-violations.tf to create violations
```

## 🔧 Local Development Best Practices

### **1. Code Organization**

```bash
# Use consistent file structure
terraform/
├── main.tf                 # Main configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output values
├── compliance-validation.tf # Compliance policies
├── test-policy-violations.tf # Test resources
└── terraform.tfvars        # Variable values
```

### **2. Version Control**

```bash
# Use .gitignore for sensitive files
echo "*.tfstate" >> .gitignore
echo "*.tfstate.*" >> .gitignore
echo ".terraform/" >> .gitignore
echo "terraform.tfvars" >> .gitignore

# Commit your changes
git add .
git commit -m "Add Terraform configuration"
```

### **3. Testing Strategies**

#### **Unit Testing**
```bash
# Test individual resources
terraform plan -target=aws_vpc.main
terraform plan -target=aws_instance.web
terraform plan -target=aws_s3_bucket.workshop
```

#### **Integration Testing**
```bash
# Test complete infrastructure
terraform plan
terraform validate
```

#### **Policy Testing**
```bash
# Test compliance policies
# Create intentional violations in test files
# Verify policies catch violations
```

## 🧪 Testing Scenarios

### **1. Test Different Environments**

```bash
# Create environment-specific variable files
cp terraform.tfvars terraform.tfvars.development
cp terraform.tfvars terraform.tfvars.staging
cp terraform.tfvars terraform.tfvars.production

# Test each environment
terraform plan -var-file="terraform.tfvars.development"
terraform plan -var-file="terraform.tfvars.staging"
terraform plan -var-file="terraform.tfvars.production"
```

### **2. Test Policy Violations**

```bash
# Temporarily modify test-policy-violations.tf
# Add expensive instance types
# Remove required tags
# Use non-compliant naming

# Test that violations are caught
terraform plan
```

### **3. Test Resource Dependencies**

```bash
# Test dependency ordering
terraform graph
terraform plan -target=aws_vpc.main
terraform plan -target=aws_subnet.public
terraform plan -target=aws_instance.web
```

## 📊 Local Validation Tools

### **1. Terraform Commands**

```bash
# Validate configuration
terraform validate

# Check formatting
terraform fmt -check

# Show execution plan
terraform plan -out=plan.tfplan

# Show plan details
terraform show plan.tfplan
```

### **2. Code Quality Checks**

```bash
# Install tflint for additional validation
# https://github.com/terraform-linters/tflint

# Run tflint
tflint

# Check for security issues
tflint --enable-rule=aws_instance_invalid_type
```

### **3. Policy Testing**

```bash
# Test Open Policy Agent policies
# Install OPA: https://www.openpolicyagent.org/docs/latest/#running-opa

# Test policies locally
opa test policies/
```

## 🔄 Development Workflow

### **1. Feature Development**

```bash
# Create feature branch
git checkout -b feature/new-resource

# Make changes to Terraform files
# Test locally
terraform validate
terraform plan

# Commit changes
git add .
git commit -m "Add new infrastructure resource"

# Push to repository
git push origin feature/new-resource
```

### **2. Testing Before Deployment**

```bash
# Always test locally before AWS deployment
terraform validate
terraform plan
terraform fmt -check

# Check for policy violations
# Verify resource dependencies
# Test variable configurations
```

### **3. Code Review Process**

```bash
# Create pull request
# Include terraform plan output
# Document any policy exceptions
# Review security implications
```

## 🚨 Common Local Issues

### **1. Configuration Errors**

```bash
# Syntax errors
terraform validate

# Variable errors
terraform plan -var="variable_name=value"

# Provider errors
terraform init -upgrade
```

### **2. State Issues**

```bash
# State file conflicts
terraform state list
terraform state show resource_name

# Import existing resources
terraform import aws_instance.web i-1234567890abcdef0
```

### **3. Policy Violations**

```bash
# Check policy requirements
terraform output compliance_validation_status

# Fix violations
# Update resource configurations
# Re-test policies
```

## 📋 Local Development Checklist

Before proceeding to AWS deployment, verify:

- [ ] **Terraform validate** passes
- [ ] **Terraform plan** shows expected changes
- [ ] **Compliance policies** pass validation
- [ ] **Code formatting** is consistent
- [ ] **Variable values** are appropriate
- [ ] **Resource dependencies** are correct
- [ ] **Security configurations** are reviewed

## 🎯 Best Practices

### **1. Development Workflow**

- **Test locally** before deploying
- **Use version control** for all changes
- **Review configurations** before committing
- **Document changes** and decisions

### **2. Testing Strategy**

- **Validate syntax** before planning
- **Test policies** with violations
- **Check dependencies** and ordering
- **Verify outputs** and values

### **3. Code Quality**

- **Use consistent formatting**
- **Follow naming conventions**
- **Document complex configurations**
- **Review security implications**

## 📞 Support

If you encounter local development issues:

1. **Check Terraform documentation** for syntax
2. **Validate configuration** with terraform validate
3. **Review error messages** carefully
4. **Test with minimal configuration**
5. **Check troubleshooting guide** (09-TROUBLESHOOTING.md)

---

**Local development ready?** Continue to [04-AWS-DEPLOYMENT.md](04-AWS-DEPLOYMENT.md) to deploy to AWS!
