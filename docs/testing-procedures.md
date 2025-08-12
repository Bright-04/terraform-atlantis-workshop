# Testing Procedures Guide

## 🧪 Overview

Comprehensive testing strategies for the Terraform Atlantis workshop infrastructure.

## 🔧 Unit Testing

### Terraform Configuration Testing

```hcl
# Test file: test/main.tf
resource "test_assertions" "vpc" {
  component = "VPC Configuration"

  equal "vpc_cidr" {
    description = "VPC CIDR block should be correct"
    got         = module.vpc.vpc_cidr_block
    want        = "10.0.0.0/16"
  }

  check "vpc_tags" {
    description = "VPC should have required tags"
    condition   = can(module.vpc.vpc_tags["Environment"])
  }
}
```

### Compliance Policy Testing

```hcl
resource "test_assertions" "compliance" {
  component = "Compliance Policies"

  check "instance_type" {
    description = "EC2 instances should use approved types"
    condition   = can([for instance in module.ec2.instances : instance if contains(["t3.micro", "t3.small"], instance.instance_type)])
  }

  check "required_tags" {
    description = "All resources should have required tags"
    condition   = alltrue([for resource in local.all_resources : can(resource.tags["Environment"])])
  }
}
```

## 🔗 Integration Testing

### End-to-End Infrastructure Testing

```hcl
resource "test_assertions" "infrastructure" {
  component = "Infrastructure Integration"

  check "vpc_connectivity" {
    description = "VPC should have internet connectivity"
    condition   = module.vpc.internet_gateway_id != null
  }

  check "alb_health" {
    description = "Application Load Balancer should be healthy"
    condition   = module.alb.alb_arn != null
  }
}
```

## 🚨 Compliance Validation Testing

### Policy Violation Testing

```hcl
resource "test_assertions" "policy_violations" {
  component = "Policy Violations"

  check "invalid_instance_type" {
    description = "Should reject invalid instance types"
    condition   = can(module.compliance.invalid_instance_type_error)
  }

  check "missing_tags" {
    description = "Should reject resources without required tags"
    condition   = can(module.compliance.missing_tags_error)
  }
}
```

## 📊 Monitoring Testing

### Alert Testing

```hcl
resource "test_assertions" "monitoring" {
  component = "Monitoring and Alerting"

  check "cloudwatch_alarms" {
    description = "CloudWatch alarms should be configured"
    condition   = length(module.monitoring.alarms) >= 3
  }

  check "sns_topics" {
    description = "SNS topics should be configured for alerts"
    condition   = module.monitoring.sns_topic_arn != null
  }
}
```

## 🔄 Operational Testing

### Deployment Testing

```powershell
# Test deployment procedures
Describe "Infrastructure Deployment" {
    Context "Terraform Plan" {
        It "Should generate a valid plan" {
            $planOutput = terraform plan -out=tfplan
            $LASTEXITCODE | Should Be 0
        }
    }

    Context "Terraform Apply" {
        It "Should apply successfully" {
            terraform apply tfplan
            $LASTEXITCODE | Should Be 0
        }
    }
}
```

### Rollback Testing

```powershell
Describe "Rollback Procedures" {
    Context "Infrastructure Rollback" {
        It "Should be able to rollback to previous state" {
            Copy-Item terraform.tfstate terraform.tfstate.backup
            Copy-Item terraform.tfstate.backup terraform.tfstate
            terraform apply
            $LASTEXITCODE | Should Be 0
        }
    }
}
```

## 🧪 Test Automation

### GitHub Actions Testing Workflow

```yaml
name: Infrastructure Testing

on:
    pull_request:
        branches: [main]

jobs:
    test:
        runs-on: ubuntu-latest

        steps:
            - uses: actions/checkout@v3

            - name: Setup Terraform
              uses: hashicorp/setup-terraform@v2

            - name: Terraform Validate
              run: terraform validate

            - name: Terraform Plan
              run: terraform plan -out=tfplan

            - name: Run Compliance Tests
              run: terraform test

            - name: Security Scan
              run: tfsec tfplan
```

### PowerShell Testing Script

```powershell
# scripts/test-infrastructure.ps1
Write-Host "🧪 Starting Infrastructure Testing..." -ForegroundColor Green

# Test 1: Terraform Validation
terraform validate
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform validation failed" -ForegroundColor Red
    exit 1
}

# Test 2: Terraform Plan
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform plan failed" -ForegroundColor Red
    exit 1
}

# Test 3: Compliance Validation
terraform test
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Compliance tests failed" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 All tests completed successfully!" -ForegroundColor Green
```

## 📋 Testing Checklist

### Pre-Deployment Testing

-   [ ] Terraform configuration validation
-   [ ] Syntax and formatting checks
-   [ ] Variable validation
-   [ ] Policy compliance tests

### Integration Testing

-   [ ] End-to-end deployment test
-   [ ] Resource dependency tests
-   [ ] Network connectivity tests
-   [ ] Atlantis workflow tests

### Operational Testing

-   [ ] Monitoring and alerting tests
-   [ ] Backup and restore tests
-   [ ] Rollback procedure tests
-   [ ] Performance tests

## 🎯 Expected Outcomes

-   **Reliability**: Consistent and reliable deployments
-   **Compliance**: All resources meet policy requirements
-   **Security**: Validated security configurations
-   **Performance**: Infrastructure meets requirements
-   **Operational Excellence**: Monitoring and alerting work correctly
