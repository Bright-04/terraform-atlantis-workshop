# Operational Procedures - Terraform Atlantis Workshop

This document contains comprehensive operational procedures for managing the Terraform Atlantis Workshop infrastructure with compliance validation.

## 🎯 Current System Status

### ✅ **Fully Operational Components**

-   **LocalStack Infrastructure**: Running on localhost:4566
-   **Atlantis GitOps**: Integrated with GitHub PR workflows
-   **Compliance Validation**: Native Terraform validation blocks active
-   **Cost Controls**: Instance type restrictions and tagging enforced
-   **Rollback Procedures**: Documented and tested

### 🔧 **System Architecture**

-   **Environment**: LocalStack (AWS simulation)
-   **Terraform Version**: v1.6.0
-   **AWS Provider**: ~5.100
-   **Compliance Engine**: Terraform `lifecycle.precondition` blocks
-   **GitOps**: Atlantis with GitHub integration

## 🔄 Rollback Procedures

### Immediate Rollback (Infrastructure Issue)

If a Terraform apply causes infrastructure issues:

1. **Stop Current Operations**

    ```bash
    # Cancel any running Atlantis operations
    # Comment "atlantis unlock" in the PR
    ```

2. **Assess the Situation**

    ```powershell
    # Check infrastructure health
    .\monitoring\health-check.ps1

    # Check recent changes
    terraform show -json | jq '.values.root_module.resources[].name'

    # Check compliance validation status
    terraform output compliance_validation_status
    ```

3. **Rollback to Previous State**

    ```powershell
    cd terraform

    # Option A: Revert to previous commit
    git checkout HEAD~1 -- .
    terraform plan
    terraform apply -auto-approve

    # Option B: Use state backup (if available)
    cp terraform.tfstate.backup terraform.tfstate
    terraform refresh
    ```

### Rollback via GitHub PR

1. **Create rollback branch**

    ```bash
    git checkout -b rollback-$(date +%Y%m%d-%H%M)
    git revert <commit-hash>
    git push origin rollback-$(date +%Y%m%d-%H%M)
    ```

2. **Create emergency PR**
    - Title: "🚨 ROLLBACK: [description]"
    - Add `atlantis plan` comment
    - After review, add `atlantis apply` comment

### Compliance Violation Rollback

If compliance violations are detected:

1. **Identify Violations**

    ```bash
    # Check violation details in PR comments
    # Look for error messages like:
    # ❌ VIOLATION: Found expensive instance types...
    ```

2. **Fix Violations**

    ```terraform
    # Example: Change instance type from m5.large to t3.micro
    resource "aws_instance" "test_violation" {
      instance_type = "t3.micro"  # Fixed: compliant instance type
    }
    ```

3. **Re-run Validation**
    ```bash
    atlantis plan -p terraform-atlantis-workshop
    ```

### State Recovery

If Terraform state is corrupted:

1. **Backup current state**

    ```powershell
    cp terraform.tfstate terraform.tfstate.corrupted
    ```

2. **Import existing resources**

    ```powershell
    # For LocalStack
    terraform import aws_vpc.main vpc-xxxxxxxxx
    terraform import aws_instance.web i-xxxxxxxxx
    terraform import aws_s3_bucket.workshop bucket-name
    ```

3. **Validate state**
    ```powershell
    terraform plan  # Should show no changes
    ```

## 🛠️ Maintenance Procedures

### Regular Health Checks

**Daily Checks:**

```powershell
# Run comprehensive health check
.\monitoring\health-check.ps1

# Check service logs
docker-compose logs --tail=50 localstack
docker-compose logs --tail=50 atlantis

# Verify compliance validation
cd terraform
terraform output compliance_validation_status
```

**Weekly Maintenance:**

```powershell
# Update container images
docker-compose pull
docker-compose up -d

# Clean up unused Docker resources
docker system prune -f

# Backup Terraform state
cp terraform\terraform.tfstate backups\terraform.tfstate.$(Get-Date -Format "yyyyMMdd-HHmm")

# Test compliance validation
cd terraform
terraform plan  # Should pass without violations
```

### LocalStack Maintenance

**Restart LocalStack:**

```powershell
# Graceful restart
docker-compose restart localstack

# Full reset (loses all data)
docker-compose down localstack
docker-compose up -d localstack
```

**Clear LocalStack Data:**

```powershell
# Reset all LocalStack services
curl -X POST http://localhost:4566/_localstack/state/reset

# Or restart with fresh state
docker-compose down
docker volume rm terraform-atlantis-workshop-2_localstack-data 2>$null
docker-compose up -d
```

### Atlantis Maintenance

**Restart Atlantis:**

```powershell
docker-compose restart atlantis
```

**Update Atlantis Configuration:**

```powershell
# After updating atlantis.yaml
docker-compose restart atlantis

# Check configuration
docker-compose exec atlantis atlantis version
```

### Compliance Validation Maintenance

**Test Validation Rules:**

```powershell
# Test with violations
cd terraform
# Temporarily change instance type to m5.large in test-policy-violations.tf
terraform plan  # Should fail with violation message

# Restore compliant configuration
git checkout -- test-policy-violations.tf
terraform plan  # Should pass
```

**Update Validation Rules:**

```powershell
# Edit compliance-validation.tf
# Add new validation rules as needed
# Test with terraform plan
```

## 📊 Monitoring & Alerting

### Key Metrics to Monitor

1. **Service Health**

    - LocalStack: `/_localstack/health`
    - Atlantis: Port 4141 availability
    - Docker containers: Up/down status

2. **Resource Status**

    - Terraform state consistency
    - AWS resources in LocalStack
    - S3 bucket accessibility
    - Compliance validation status

3. **Operation Success**

    - Terraform plan/apply success rate
    - Atlantis webhook response times
    - GitHub integration functionality
    - Compliance validation pass rate

4. **Compliance Metrics**
    - Violation detection rate
    - Policy enforcement effectiveness
    - Resource compliance percentage

### Alerting Setup

Create monitoring alerts for:

-   Service downtime > 5 minutes
-   Failed terraform operations
-   State file corruption
-   GitHub webhook failures
-   Compliance validation failures
-   Policy violations detected

## 🚨 Incident Response

### Severity Levels

**P1 - Critical (Complete outage)**

-   LocalStack completely down
-   Atlantis cannot process PRs
-   State file corrupted
-   Compliance validation system down

_Response: Immediate action required_

**P2 - High (Partial outage)**

-   Some AWS services in LocalStack failing
-   Intermittent Atlantis issues
-   Single resource deployment failures
-   Compliance validation not working

_Response: Fix within 2 hours_

**P3 - Medium (Degraded performance)**

-   Slow response times
-   Non-critical feature issues
-   Warning alerts
-   Minor compliance violations

_Response: Fix within 24 hours_

### Incident Response Steps

1. **Assess Impact**

    ```powershell
    .\monitoring\health-check.ps1
    cd terraform
    terraform output compliance_validation_status
    ```

2. **Implement Immediate Fix**

    - Restart services if needed
    - Apply emergency rollback
    - Use backup state if required
    - Fix compliance violations

3. **Document Incident**
    - Record root cause
    - Document resolution steps
    - Update procedures if needed

## 🔐 Security Procedures

### Access Control

-   GitHub webhooks use secret token
-   LocalStack uses test credentials only
-   No real AWS credentials in LocalStack mode
-   Compliance validation prevents unauthorized resource types

### Secret Management

```powershell
# Rotate webhook secret
.\setup-github-integration.ps1
# Follow prompts to update .env file
```

### Security Audits

**Monthly Security Review:**

-   Review security group rules
-   Check for exposed services
-   Audit Terraform state for sensitive data
-   Update container images
-   Review compliance validation rules
-   Test policy enforcement

### Compliance Security

**Policy Enforcement:**

```powershell
# Test policy enforcement
cd terraform
# Introduce violations and verify they're caught
terraform plan  # Should fail with clear violation messages
```

## 📝 Documentation Updates

Keep these documents current:

-   This operational procedures guide
-   README.md status updates
-   Monitoring configurations
-   Incident response logs
-   Compliance validation rules
-   Policy documentation

## 🎯 Workshop Completion Checklist

-   [x] Rollback procedures tested
-   [x] Health monitoring working
-   [x] Incident response plan ready
-   [x] Security audit completed
-   [x] Documentation updated
-   [x] Team trained on procedures
-   [x] Compliance validation active
-   [x] Policy enforcement working
-   [x] Cost controls implemented
-   [x] GitOps workflow operational

## 🔧 Troubleshooting Guide

### Common Issues

**Compliance Validation Issues:**

```powershell
# Violations not detected
cd terraform
terraform plan  # Check if compliance-validation.tf is loaded

# False positives
# Review validation rules in compliance-validation.tf
```

**LocalStack Issues:**

```powershell
# Service not responding
docker-compose restart localstack
curl http://localhost:4566/_localstack/health
```

**Atlantis Issues:**

```powershell
# Webhook failures
docker-compose logs atlantis
# Check GitHub webhook configuration
```

### Emergency Procedures

**Complete System Reset:**

```powershell
# Stop all services
docker-compose down

# Clear all data
docker volume rm terraform-atlantis-workshop-2_localstack-data 2>$null

# Restart fresh
docker-compose up -d
cd terraform
.\deploy.ps1
```

**Compliance System Reset:**

```powershell
cd terraform
# Restore compliant configuration
git checkout -- .
terraform plan  # Should pass without violations
```
