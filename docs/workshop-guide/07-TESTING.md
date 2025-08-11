# Testing and Validation Guide

## 🎯 Overview

This guide covers comprehensive testing strategies for your Terraform infrastructure. You'll learn how to test infrastructure components, validate policies, and ensure your deployments are reliable and secure.

## 📋 Prerequisites

Before starting this guide, ensure you have:

-   ✅ **Infrastructure deployed** to AWS (04-AWS-DEPLOYMENT.md)
-   ✅ **Compliance policies** working (05-COMPLIANCE.md)
-   ✅ **GitOps setup** with Atlantis (06-ATLANTIS.md)
-   ✅ **Understanding of testing** concepts

## 🧪 Testing Strategy Overview

### **Testing Pyramid for Infrastructure**

```
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Testing                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Unit Tests    │    │ Integration     │                │
│  │                 │    │ Tests           │                │
│  │ • Resource      │    │                 │                │
│  │ • Variables     │    │ • End-to-End    │                │
│  │ • Outputs       │    │ • Workflows     │                │
│  │ • Policies      │    │ • Dependencies  │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                        │
│           ▼                       ▼                        │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Policy Tests  │    │   Security      │                │
│  │                 │    │   Tests         │                │
│  │ • Compliance    │    │                 │                │
│  │ • Violations    │    │ • Penetration   │                │
│  │ • Enforcement   │    │ • Access        │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Unit Testing

### **1. Resource Testing**

#### **Test Individual Resources**

```bash
# Test VPC configuration
terraform plan -target=aws_vpc.main

# Test EC2 instance
terraform plan -target=aws_instance.web

# Test S3 bucket
terraform plan -target=aws_s3_bucket.workshop

# Test security groups
terraform plan -target=aws_security_group.web
```

#### **Test Resource Dependencies**

```bash
# Test dependency ordering
terraform graph

# Test specific dependency chains
terraform plan -target=aws_subnet.public -target=aws_instance.web
```

### **2. Variable Testing**

#### **Test Variable Validation**

```bash
# Test variable constraints
terraform plan -var="instance_type=invalid_type"
# Should fail with validation error

# Test environment validation
terraform plan -var="environment=invalid_env"
# Should fail with validation error
```

#### **Test Variable Combinations**

```bash
# Test different instance types
terraform plan -var="instance_type=t3.micro"
terraform plan -var="instance_type=t3.small"
terraform plan -var="instance_type=t3.medium"

# Test different environments
terraform plan -var="environment=development"
terraform plan -var="environment=staging"
terraform plan -var="environment=production"
```

### **3. Output Testing**

#### **Test Output Values**

```bash
# Check output values
terraform output

# Test specific outputs
terraform output website_url
terraform output instance_id
terraform output s3_bucket_id
```

## 🔄 Integration Testing

### **1. End-to-End Testing**

#### **Complete Infrastructure Test**

```bash
# Test complete deployment
terraform plan
terraform apply

# Verify all resources created
terraform state list

# Test outputs
terraform output
```

#### **Workflow Testing**

```bash
# Test GitOps workflow
# 1. Create feature branch
git checkout -b test-integration

# 2. Make changes
# Edit terraform files

# 3. Test locally
terraform validate
terraform plan

# 4. Push and create PR
git add .
git commit -m "Test integration changes"
git push origin test-integration

# 5. Verify Atlantis workflow
# Check PR comments for plan output
```

### **2. Dependency Testing**

#### **Test Resource Dependencies**

```bash
# Test VPC and subnet dependencies
terraform plan -target=aws_vpc.main -target=aws_subnet.public

# Test instance dependencies
terraform plan -target=aws_security_group.web -target=aws_instance.web

# Test IAM dependencies
terraform plan -target=aws_iam_role.ec2_role -target=aws_iam_instance_profile.ec2_profile
```

## 🔒 Policy Testing

### **1. Compliance Testing**

#### **Test Policy Violations**

```bash
# Test instance type violations
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

# Test that violation is caught
terraform plan
# Should show error: "Found expensive instance types"
```

#### **Test Tag Violations**

```bash
# Test missing required tags
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

# Test that violation is caught
terraform plan
# Should show error: "EC2 instances missing required tags"
```

#### **Test Naming Violations**

```bash
# Test S3 naming convention violations
# Temporarily modify test-policy-violations.tf
resource "aws_s3_bucket" "test_violation" {
  bucket = "my-non-compliant-bucket"  # Doesn't follow naming convention

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}

# Test that violation is caught
terraform plan
# Should show error: "S3 buckets must follow naming convention"
```

### **2. Policy Enforcement Testing**

#### **Test GitOps Policy Enforcement**

```bash
# Create policy violation PR
git checkout -b test-policy-enforcement

# Add non-compliant resources
# Push and create PR

# Verify Atlantis blocks deployment
# Check PR comments for policy violations
```

## 🛡️ Security Testing

### **1. Access Control Testing**

#### **Test Security Groups**

```bash
# Test security group rules
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw security_group_id)

# Test port accessibility
telnet $(terraform output -raw instance_public_ip) 80
telnet $(terraform output -raw instance_public_ip) 443
telnet $(terraform output -raw instance_public_ip) 22
```

#### **Test IAM Permissions**

```bash
# Test IAM role permissions
aws iam get-role-policy \
  --role-name terraform-atlantis-workshop-ec2-role \
  --policy-name terraform-atlantis-workshop-cloudwatch-logs

# Test instance profile
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[].Instances[].IamInstanceProfile'
```

### **2. Encryption Testing**

#### **Test S3 Encryption**

```bash
# Verify S3 bucket encryption
aws s3api get-bucket-encryption \
  --bucket $(terraform output -raw s3_bucket_id)

# Test encryption configuration
aws s3api get-bucket-encryption \
  --bucket $(terraform output -raw s3_bucket_id) \
  --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault'
```

#### **Test Public Access Blocking**

```bash
# Verify S3 public access blocking
aws s3api get-public-access-block \
  --bucket $(terraform output -raw s3_bucket_id)
```

## 📊 Performance Testing

### **1. Infrastructure Performance**

#### **Test Instance Performance**

#### **Windows (PowerShell)**

```powershell
# Test web server response time
$websiteUrl = terraform output -raw website_url
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
    Invoke-WebRequest -Uri $websiteUrl -UseBasicParsing | Out-Null
    $stopwatch.Stop()
    Write-Host "Response time: $($stopwatch.ElapsedMilliseconds)ms"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}

# Test multiple concurrent requests
$jobs = @()
for ($i = 1; $i -le 10; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($url)
        try {
            Invoke-WebRequest -Uri $url -UseBasicParsing | Out-Null
            return "Success"
        } catch {
            return "Failed"
        }
    } -ArgumentList $websiteUrl
}
$jobs | Wait-Job | Receive-Job
$jobs | Remove-Job
```

#### **Linux/macOS**

```bash
# Test web server response time
time curl -s $(terraform output -raw website_url) > /dev/null

# Test multiple concurrent requests
for i in {1..10}; do
  curl -s $(terraform output -raw website_url) > /dev/null &
done
wait
```

#### **Test S3 Performance**

```bash
# Test S3 upload performance
dd if=/dev/zero bs=1M count=100 | aws s3 cp - \
  s3://$(terraform output -raw s3_bucket_id)/test-file

# Test S3 download performance
time aws s3 cp s3://$(terraform output -raw s3_bucket_id)/test-file /tmp/
```

### **2. Monitoring Performance**

#### **Test CloudWatch Metrics**

#### **Windows (PowerShell)**

```powershell
# Get CPU utilization metrics
$instanceId = terraform output -raw instance_id
$startTime = (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ss")
$endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")

aws cloudwatch get-metric-statistics `
  --namespace AWS/EC2 `
  --metric-name CPUUtilization `
  --dimensions Name=InstanceId,Value=$instanceId `
  --start-time $startTime `
  --end-time $endTime `
  --period 300 `
  --statistics Average
```

#### **Linux/macOS**

```bash
# Get CPU utilization metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## 🔄 Automated Testing

### **1. CI/CD Pipeline Testing**

#### **GitHub Actions Workflow**

```yaml
# .github/workflows/terraform-test.yml
name: Terraform Testing

on:
    pull_request:
        paths:
            - "terraform/**"

jobs:
    test:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v2

            - name: Setup Terraform
              uses: hashicorp/setup-terraform@v1

            - name: Terraform Init
              run: |
                  cd terraform
                  terraform init

            - name: Terraform Validate
              run: |
                  cd terraform
                  terraform validate

            - name: Terraform Plan
              run: |
                  cd terraform
                  terraform plan -out=plan.tfplan

            - name: Terraform Format Check
              run: |
                  cd terraform
                  terraform fmt -check
```

### **2. Automated Policy Testing**

#### **Policy Test Script**

#### **Windows (PowerShell)**

```powershell
# test-policies.ps1
Write-Host "Testing compliance policies..."

# Test instance type policies
$planOutput = terraform plan -var="instance_type=t3.micro" 2>&1
if ($planOutput -match "VIOLATION") {
    Write-Host "❌ Instance type violation found"
} else {
    Write-Host "✅ Instance type policy passed"
}

# Test tag policies
$planOutput = terraform plan 2>&1
if ($planOutput -match "missing required tags") {
    Write-Host "❌ Tag violation found"
} else {
    Write-Host "✅ Tag policy passed"
}

# Test naming policies
if ($planOutput -match "naming convention") {
    Write-Host "❌ Naming violation found"
} else {
    Write-Host "✅ Naming policy passed"
}

Write-Host "Policy testing completed!"
```

#### **Linux/macOS**

```bash
#!/bin/bash
# test-policies.sh

echo "Testing compliance policies..."

# Test instance type policies
terraform plan -var="instance_type=t3.micro" | grep -q "VIOLATION" && echo "❌ Instance type violation found" || echo "✅ Instance type policy passed"

# Test tag policies
terraform plan | grep -q "missing required tags" && echo "❌ Tag violation found" || echo "✅ Tag policy passed"

# Test naming policies
terraform plan | grep -q "naming convention" && echo "❌ Naming violation found" || echo "✅ Naming policy passed"

echo "Policy testing completed!"
```

## 📋 Testing Checklist

Before considering testing complete, verify:

-   [ ] **Unit tests** pass for all resources
-   [ ] **Integration tests** validate workflows
-   [ ] **Policy tests** catch violations
-   [ ] **Security tests** verify access controls
-   [ ] **Performance tests** meet requirements
-   [ ] **Automated tests** run in CI/CD
-   [ ] **Documentation** covers test procedures

## 🎯 Best Practices

### **1. Testing Strategy**

-   **Test early and often** during development
-   **Automate repetitive tests** in CI/CD
-   **Test policy violations** to ensure enforcement
-   **Validate security** configurations

### **2. Test Organization**

-   **Group related tests** by functionality
-   **Use descriptive test names** and descriptions
-   **Maintain test data** and fixtures
-   **Document test procedures** clearly

### **3. Test Maintenance**

-   **Update tests** when infrastructure changes
-   **Review test coverage** regularly
-   **Refactor tests** for maintainability
-   **Monitor test performance** and reliability

## 🚨 Troubleshooting

### **1. Common Testing Issues**

#### **Test Failures**

```bash
# Check Terraform state
terraform state list
terraform show

# Check AWS resources
aws ec2 describe-instances --filters "Name=tag:Project,Values=terraform-atlantis-workshop"

# Check CloudWatch logs
aws logs filter-log-events --log-group-name "/aws/ec2/terraform-atlantis-workshop"
```

#### **Policy Test Issues**

```bash
# Check policy configuration
terraform output compliance_validation_status

# Verify policy rules
cat terraform/compliance-validation.tf

# Test individual policies
terraform plan -target=null_resource.instance_type_validation
```

### **2. Debugging Commands**

```bash
# Debug Terraform plan
terraform plan -detailed-exitcode

# Debug specific resources
terraform state show aws_instance.web

# Debug variables
terraform console
> var.instance_type
> var.environment
```

## 📞 Support

If you encounter testing issues:

1. **Check the troubleshooting guide** (09-TROUBLESHOOTING.md)
2. **Verify test prerequisites** are met
3. **Review test configuration** and setup
4. **Check AWS permissions** for testing
5. **Monitor CloudWatch logs** for errors

---

**Testing completed?** Continue to [08-MONITORING.md](08-MONITORING.md) to set up monitoring!
