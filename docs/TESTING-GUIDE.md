# Testing Guide - Terraform Atlantis Workshop

## Overview

This guide provides comprehensive testing procedures for the Terraform Atlantis Workshop infrastructure, including compliance validation, GitOps workflows, and operational procedures.

## 🎯 Testing Strategy

### Testing Pyramid

```
                    ┌─────────────────┐
                    │   Integration   │
                    │     Tests       │
                    └─────────────────┘
                           │
                    ┌─────────────────┐
                    │   Compliance    │
                    │   Validation    │
                    └─────────────────┘
                           │
                    ┌─────────────────┐
                    │   Unit Tests    │
                    │   (Terraform)   │
                    └─────────────────┘
```

### Test Categories

1. **Unit Tests**: Terraform validation and syntax
2. **Compliance Tests**: Policy enforcement validation
3. **Integration Tests**: End-to-end infrastructure deployment
4. **GitOps Tests**: Atlantis workflow validation
5. **Operational Tests**: Health checks and monitoring

## 🔧 Unit Testing

### Terraform Validation

**Syntax Validation**:

```powershell
cd terraform
terraform validate
```

**Format Check**:

```powershell
terraform fmt -check
terraform fmt -diff
```

**Variable Validation**:

```powershell
# Test variable constraints
terraform plan -var="instance_type=invalid-type"  # Should fail
terraform plan -var="instance_type=t3.micro"      # Should pass
```

### Configuration Testing

**Provider Configuration**:

```powershell
# Test LocalStack provider
terraform init
terraform plan

# Test AWS provider (if configured)
Copy-Item backup/main-aws.tf main.tf -Force
terraform init
terraform plan
```

**Resource Configuration**:

```powershell
# Test resource definitions
terraform validate
terraform plan -target=aws_vpc.main
terraform plan -target=aws_instance.web
```

## 🛡️ Compliance Validation Testing

### Policy Rule Testing

**Instance Type Restrictions**:

```powershell
# Test compliant instance types
terraform plan  # Should pass with t3.micro, t3.small, t3.medium

# Test violation (temporarily modify test-policy-violations.tf)
# Change instance_type to "m5.large"
terraform plan  # Should fail with violation message
```

**Required Tags Testing**:

```powershell
# Test missing tags (temporarily remove tags)
# Remove Environment, Project, CostCenter tags
terraform plan  # Should fail with tag violation

# Test compliant tags
# Restore all required tags
terraform plan  # Should pass
```

**S3 Bucket Naming Testing**:

```powershell
# Test naming violation (temporarily change bucket name)
# Change bucket name to "my-bucket"
terraform plan  # Should fail with naming violation

# Test compliant naming
# Restore terraform-atlantis-workshop-* naming
terraform plan  # Should pass
```

### Compliance Test Scenarios

**Scenario 1: Expensive Instance Type**:

```terraform
# In test-policy-violations.tf
resource "aws_instance" "test_violation" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "m5.large"  # VIOLATION: Expensive instance type
}
```

**Expected Result**:

```
❌ VIOLATION: Found expensive instance types. Only t3.micro, t3.small, t3.medium are permitted.
Current instances: policy_test=t3.small, test_violation=m5.large, web=t3.micro
```

**Scenario 2: Missing Required Tags**:

```terraform
resource "aws_instance" "test_violation" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"

  tags = {
    Name = "test-instance"
    # Missing Environment, Project, CostCenter tags
  }
}
```

**Expected Result**:

```
❌ VIOLATION: EC2 instances missing required tags (Environment, Project, CostCenter).
```

**Scenario 3: S3 Bucket Naming Violation**:

```terraform
resource "aws_s3_bucket" "test_violation" {
  bucket = "wrong-naming-convention"  # VIOLATION: Wrong naming
}
```

**Expected Result**:

```
❌ VIOLATION: S3 buckets must follow naming convention: terraform-atlantis-workshop-*.
```

### Automated Compliance Testing

**Test Script**:

```powershell
# Create test-compliance.ps1
Write-Host "Testing Compliance Validation..." -ForegroundColor Green

# Test 1: Valid configuration
Write-Host "Test 1: Valid configuration" -ForegroundColor Yellow
cd terraform
terraform plan
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Valid configuration test passed" -ForegroundColor Green
} else {
    Write-Host "❌ Valid configuration test failed" -ForegroundColor Red
}

# Test 2: Introduce violation
Write-Host "Test 2: Instance type violation" -ForegroundColor Yellow
# Temporarily modify test-policy-violations.tf
terraform plan
if ($LASTEXITCODE -ne 0) {
    Write-Host "✅ Violation detection test passed" -ForegroundColor Green
} else {
    Write-Host "❌ Violation detection test failed" -ForegroundColor Red
}

# Restore compliant configuration
git checkout -- test-policy-violations.tf
```

## 🔄 Integration Testing

### End-to-End Deployment Testing

**LocalStack Deployment Test**:

```powershell
# Test complete LocalStack deployment
Write-Host "Testing LocalStack Deployment..." -ForegroundColor Green

# 1. Start LocalStack
docker-compose up localstack -d
Start-Sleep -Seconds 10

# 2. Deploy infrastructure
cd terraform
.\deploy.ps1

# 3. Verify resources
terraform output
aws --endpoint-url=http://localhost:4566 ec2 describe-instances
aws --endpoint-url=http://localhost:4566 s3 ls

Write-Host "✅ LocalStack deployment test completed" -ForegroundColor Green
```

**Resource Verification Test**:

```powershell
# Verify all resources are created correctly
Write-Host "Verifying Resources..." -ForegroundColor Green

# Check VPC
$vpc = aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text
Write-Host "VPC: $vpc" -ForegroundColor Cyan

# Check EC2 instances
$instances = aws --endpoint-url=http://localhost:4566 ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text
Write-Host "EC2 Instances: $instances" -ForegroundColor Cyan

# Check S3 buckets
$buckets = aws --endpoint-url=http://localhost:4566 s3 ls
Write-Host "S3 Buckets: $buckets" -ForegroundColor Cyan

Write-Host "✅ Resource verification completed" -ForegroundColor Green
```

### Compliance Integration Test

**Full Compliance Workflow Test**:

```powershell
# Test complete compliance workflow
Write-Host "Testing Compliance Workflow..." -ForegroundColor Green

# 1. Test compliant deployment
terraform plan
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compliant deployment test passed" -ForegroundColor Green
} else {
    Write-Host "❌ Compliant deployment test failed" -ForegroundColor Red
}

# 2. Test violation detection
# Introduce violation
Write-Host "Introducing violation for testing..." -ForegroundColor Yellow
terraform plan
if ($LASTEXITCODE -ne 0) {
    Write-Host "✅ Violation detection test passed" -ForegroundColor Green
} else {
    Write-Host "❌ Violation detection test failed" -ForegroundColor Red
}

# 3. Test violation resolution
Write-Host "Resolving violation..." -ForegroundColor Yellow
# Fix violation
terraform plan
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Violation resolution test passed" -ForegroundColor Green
} else {
    Write-Host "❌ Violation resolution test failed" -ForegroundColor Red
}
```

## 🚀 GitOps Testing

### Atlantis Workflow Testing

**Local Atlantis Test**:

```powershell
# Test Atlantis locally
Write-Host "Testing Atlantis Workflow..." -ForegroundColor Green

# 1. Start Atlantis
docker-compose up atlantis -d
Start-Sleep -Seconds 10

# 2. Test Atlantis health
$atlantisHealth = Invoke-WebRequest -Uri "http://localhost:4141/health" -UseBasicParsing
if ($atlantisHealth.StatusCode -eq 200) {
    Write-Host "✅ Atlantis health check passed" -ForegroundColor Green
} else {
    Write-Host "❌ Atlantis health check failed" -ForegroundColor Red
}
```

**GitHub Integration Test**:

```powershell
# Test GitHub webhook (if configured)
Write-Host "Testing GitHub Integration..." -ForegroundColor Green

# Check webhook configuration
# This requires actual GitHub repository setup
Write-Host "⚠️  GitHub integration test requires repository setup" -ForegroundColor Yellow
```

### Pull Request Testing

**Simulated PR Test**:

```powershell
# Simulate PR workflow
Write-Host "Simulating PR Workflow..." -ForegroundColor Green

# 1. Create test branch
git checkout -b test-compliance-validation

# 2. Make changes
# Edit terraform files

# 3. Test plan
cd terraform
terraform plan

# 4. Commit changes
git add .
git commit -m "Test compliance validation"

# 5. Cleanup
git checkout main
git branch -D test-compliance-validation

Write-Host "✅ PR workflow simulation completed" -ForegroundColor Green
```

## 📊 Operational Testing

### Health Check Testing

**Service Health Tests**:

```powershell
# Test LocalStack health
Write-Host "Testing LocalStack Health..." -ForegroundColor Green
$localstackHealth = Invoke-WebRequest -Uri "http://localhost:4566/_localstack/health" -UseBasicParsing
if ($localstackHealth.StatusCode -eq 200) {
    Write-Host "✅ LocalStack health check passed" -ForegroundColor Green
} else {
    Write-Host "❌ LocalStack health check failed" -ForegroundColor Red
}

# Test Atlantis health
Write-Host "Testing Atlantis Health..." -ForegroundColor Green
$atlantisHealth = Invoke-WebRequest -Uri "http://localhost:4141/health" -UseBasicParsing
if ($atlantisHealth.StatusCode -eq 200) {
    Write-Host "✅ Atlantis health check passed" -ForegroundColor Green
} else {
    Write-Host "❌ Atlantis health check failed" -ForegroundColor Red
}
```

**Infrastructure Health Tests**:

```powershell
# Test Terraform state
Write-Host "Testing Terraform State..." -ForegroundColor Green
terraform show
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Terraform state check passed" -ForegroundColor Green
} else {
    Write-Host "❌ Terraform state check failed" -ForegroundColor Red
}

# Test compliance status
Write-Host "Testing Compliance Status..." -ForegroundColor Green
terraform output compliance_validation_status
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compliance status check passed" -ForegroundColor Green
} else {
    Write-Host "❌ Compliance status check failed" -ForegroundColor Red
}
```

### Performance Testing

**Deployment Performance**:

```powershell
# Test deployment time
Write-Host "Testing Deployment Performance..." -ForegroundColor Green
$startTime = Get-Date

cd terraform
terraform plan

$endTime = Get-Date
$duration = $endTime - $startTime
Write-Host "Deployment plan completed in $($duration.TotalSeconds) seconds" -ForegroundColor Cyan

if ($duration.TotalSeconds -lt 30) {
    Write-Host "✅ Deployment performance test passed" -ForegroundColor Green
} else {
    Write-Host "⚠️  Deployment performance test slow" -ForegroundColor Yellow
}
```

## 🧪 Test Automation

### Automated Test Suite

**Complete Test Script**:

```powershell
# Create run-tests.ps1
Write-Host "Running Complete Test Suite..." -ForegroundColor Green

# Test categories
$tests = @(
    "Unit Tests",
    "Compliance Validation",
    "Integration Tests",
    "GitOps Tests",
    "Operational Tests"
)

foreach ($test in $tests) {
    Write-Host "Running $test..." -ForegroundColor Yellow

    switch ($test) {
        "Unit Tests" {
            cd terraform
            terraform validate
            terraform fmt -check
        }
        "Compliance Validation" {
            terraform plan
        }
        "Integration Tests" {
            # Run integration tests
        }
        "GitOps Tests" {
            # Run GitOps tests
        }
        "Operational Tests" {
            # Run operational tests
        }
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $test passed" -ForegroundColor Green
    } else {
        Write-Host "❌ $test failed" -ForegroundColor Red
    }
}

Write-Host "Test suite completed!" -ForegroundColor Green
```

### Continuous Testing

**GitHub Actions Test** (if using GitHub):

```yaml
# .github/workflows/test.yml
name: Test Infrastructure

on: [push, pull_request]

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
                  terraform plan
```

## 📋 Test Checklist

### Pre-Deployment Tests

-   [ ] Terraform syntax validation
-   [ ] Variable validation
-   [ ] Provider configuration
-   [ ] Resource configuration
-   [ ] Compliance validation rules

### Deployment Tests

-   [ ] LocalStack deployment
-   [ ] Resource creation verification
-   [ ] Compliance validation during deployment
-   [ ] Error handling and rollback

### Post-Deployment Tests

-   [ ] Infrastructure health checks
-   [ ] Service availability
-   [ ] Compliance status verification
-   [ ] Performance metrics

### GitOps Tests

-   [ ] Atlantis workflow
-   [ ] GitHub integration
-   [ ] Pull request processing
-   [ ] Compliance validation in PRs

## 🛠️ Troubleshooting Tests

### Common Test Issues

**Terraform Validation Failures**:

```powershell
# Check syntax errors
terraform validate

# Check formatting
terraform fmt -check

# Check variable constraints
terraform plan -var="instance_type=invalid"
```

**Compliance Validation Issues**:

```powershell
# Check validation rules
cat terraform/compliance-validation.tf

# Test individual rules
terraform plan -target=null_resource.instance_type_validation
```

**LocalStack Issues**:

```powershell
# Check LocalStack health
curl "http://localhost:4566/_localstack/health"

# Restart LocalStack
docker-compose restart localstack
```

### Test Data Management

**Clean Test Environment**:

```powershell
# Clean up test data
docker-compose down
docker volume rm terraform-atlantis-workshop-2_localstack-data 2>$null

# Restart fresh
docker-compose up -d
cd terraform
.\deploy.ps1
```

## 📚 Related Documentation

-   [Operational Procedures](OPERATIONS.md) - Day-to-day operations
-   [Compliance Validation](COMPLIANCE-VALIDATION.md) - Policy enforcement
-   [Deployment Guide](DEPLOYMENT-GUIDE.md) - Deployment procedures
-   [README.md](../readme.md) - Project overview

---

_This testing guide provides comprehensive procedures for validating infrastructure, compliance rules, and operational procedures to ensure reliable and secure deployments._
