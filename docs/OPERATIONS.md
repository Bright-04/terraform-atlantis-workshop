# Operational Procedures - Terraform Atlantis Workshop

This document contains comprehensive operational procedures for managing the Terraform Atlantis Workshop infrastructure.

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

3. **Operation Success**
    - Terraform plan/apply success rate
    - Atlantis webhook response times
    - GitHub integration functionality

### Alerting Setup

Create monitoring alerts for:

-   Service downtime > 5 minutes
-   Failed terraform operations
-   State file corruption
-   GitHub webhook failures

## 🚨 Incident Response

### Severity Levels

**P1 - Critical (Complete outage)**

-   LocalStack completely down
-   Atlantis cannot process PRs
-   State file corrupted

_Response: Immediate action required_

**P2 - High (Partial outage)**

-   Some AWS services in LocalStack failing
-   Intermittent Atlantis issues
-   Single resource deployment failures

_Response: Fix within 2 hours_

**P3 - Medium (Degraded performance)**

-   Slow response times
-   Non-critical feature issues
-   Warning alerts

_Response: Fix within 24 hours_

### Incident Response Steps

1. **Assess Impact**

    ```powershell
    .\monitoring\health-check.ps1
    ```

2. **Implement Immediate Fix**

    - Restart services if needed
    - Apply emergency rollback
    - Use backup state if required

3. **Document Incident**
    - Record root cause
    - Document resolution steps
    - Update procedures if needed

## 🔐 Security Procedures

### Access Control

-   GitHub webhooks use secret token
-   LocalStack uses test credentials only
-   No real AWS credentials in LocalStack mode

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

## 📝 Documentation Updates

Keep these documents current:

-   This operational procedures guide
-   README.md status updates
-   Monitoring configurations
-   Incident response logs

## 🎯 Workshop Completion Checklist

-   [ ] Rollback procedures tested
-   [ ] Health monitoring working
-   [ ] Incident response plan ready
-   [ ] Security audit completed
-   [ ] Documentation updated
-   [ ] Team trained on procedures
