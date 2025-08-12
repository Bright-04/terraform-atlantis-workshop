# Rollback Procedures - Terraform Atlantis Workshop

## 🔄 Emergency Rollback Instructions

This document provides comprehensive rollback procedures for the **Environment Provisioning Automation with Terraform and Atlantis** workshop, ensuring you can quickly recover from failed deployments or unexpected issues.

## 🚨 Emergency Response Plan

### Immediate Response Checklist

1. **⏹️ Stop Current Operations**

    - Cancel any running Atlantis operations
    - Stop ongoing deployments
    - Alert team members

2. **📊 Assess Impact**

    - Identify affected resources
    - Determine scope of failure
    - Check application availability

3. **🔄 Execute Rollback**

    - Choose appropriate rollback method
    - Execute rollback procedure
    - Verify system recovery

4. **📝 Document Incident**
    - Record what happened
    - Document actions taken
    - Plan preventive measures

## 🔧 Rollback Methods

### Method 1: Automated Script Rollback (Recommended)

#### Quick Rollback

```powershell
# Execute automated rollback script
.\scripts\06-rollback-procedures.ps1

# Verify rollback success
.\scripts\01-validate-environment.ps1
```

#### Script Features

-   **Automatic state detection**
-   **Safe rollback to last known good state**
-   **Validation checks**
-   **Backup creation**

### Method 2: Terraform State Rollback

#### Manual State Rollback

```powershell
# Navigate to terraform directory
cd terraform

# List available state backups
terraform state list
ls terraform.tfstate.backup*

# Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# Verify state
terraform plan
```

#### Using Terraform Workspace

```powershell
# If using workspaces
terraform workspace list
terraform workspace select production

# Restore specific workspace state
terraform state pull > current-state.json
# Manually edit or replace with backup
terraform state push backup-state.json
```

### Method 3: AWS Console Emergency Stop

#### Stop EC2 Instances

```powershell
# Stop all workshop instances
aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "Reservations[].Instances[].InstanceId" --output text | ForEach-Object {
    aws ec2 stop-instances --instance-ids $_
    Write-Host "Stopped instance: $_"
}
```

#### Remove Security Groups

```powershell
# List workshop security groups
aws ec2 describe-security-groups --filters "Name=tag:Workshop,Values=terraform-atlantis"

# Remove custom rules (keep default)
aws ec2 revoke-security-group-ingress --group-id sg-xxxxxxxxx --ip-permissions file://emergency-revoke.json
```

### Method 4: Complete Infrastructure Destruction

#### Emergency Cleanup

```powershell
# WARNING: This will destroy ALL workshop infrastructure
cd terraform

# Force destroy (bypass protection)
terraform destroy -auto-approve -lock=false

# If destruction fails, force remove from state
terraform state list | ForEach-Object {
    terraform state rm $_
}
```

## 📋 Specific Rollback Scenarios

### Scenario 1: Failed Terraform Apply

#### Symptoms

-   Terraform apply command failed
-   Resources partially created
-   Infrastructure in inconsistent state

#### Resolution Steps

```powershell
# 1. Check current state
terraform show

# 2. Attempt to fix inconsistencies
terraform refresh

# 3. If refresh fails, rollback to last good state
cp terraform.tfstate.backup terraform.tfstate

# 4. Destroy problematic resources
terraform destroy -target=aws_instance.problem_instance

# 5. Re-apply clean configuration
terraform apply
```

### Scenario 2: Atlantis Server Issues

#### Symptoms

-   Atlantis webhooks not responding
-   Pull request comments not triggering plans
-   Atlantis server errors

#### Resolution Steps

```powershell
# 1. Check Atlantis server status
docker ps | grep atlantis

# 2. Restart Atlantis container
docker-compose down
docker-compose up -d

# 3. If restart fails, rebuild
docker-compose down --volumes
docker-compose build --no-cache
docker-compose up -d

# 4. Verify webhook connectivity
curl -X POST http://localhost:4141/events
```

### Scenario 3: Security Group Lockout

#### Symptoms

-   Cannot access EC2 instances
-   SSH/RDP connections blocked
-   Security groups misconfigured

#### Resolution Steps

```powershell
# 1. Emergency access via AWS Console
# Navigate to EC2 > Security Groups

# 2. Create emergency access rule
aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxxxxxx \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# 3. Access instance and fix configuration
ssh -i key.pem ec2-user@instance-ip

# 4. Restore proper security group rules
terraform apply -replace=aws_security_group.workshop_sg
```

### Scenario 4: Cost Runaway

#### Symptoms

-   Unexpected high AWS costs
-   Resources not properly sized
-   Auto-scaling out of control

#### Immediate Actions

```powershell
# 1. Stop all EC2 instances immediately
aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "Reservations[].Instances[].InstanceId" --output text | ForEach-Object {
    aws ec2 stop-instances --instance-ids $_
}

# 2. Disable auto-scaling
aws autoscaling suspend-processes --auto-scaling-group-name workshop-asg

# 3. Check and adjust instance types
terraform plan -var="instance_type=t3.micro"
terraform apply -auto-approve
```

### Scenario 5: Data Loss Prevention

#### Symptoms

-   Risk of data loss during rollback
-   Important state information at risk

#### Protection Steps

```powershell
# 1. Backup current state immediately
cp terraform.tfstate "terraform.tfstate.emergency.$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# 2. Export important data
terraform output -json > emergency-outputs.json

# 3. Backup any persistent storage
aws s3 sync s3://workshop-bucket ./emergency-backup/

# 4. Document current resource IDs
aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" > emergency-instances.json
```

## 🔍 Post-Rollback Verification

### Verification Checklist

#### 1. Infrastructure Status

```powershell
# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis"

# Verify security groups
aws ec2 describe-security-groups --filters "Name=tag:Workshop,Values=terraform-atlantis"

# Check S3 buckets
aws s3 ls
```

#### 2. Application Health

```powershell
# Test web application access
curl -I http://workshop-alb-xxxx.us-west-2.elb.amazonaws.com

# Check application logs
aws logs describe-log-groups --log-group-name-prefix /aws/ec2/workshop
```

#### 3. Terraform State Integrity

```powershell
# Validate terraform state
terraform validate

# Plan should show no changes
terraform plan

# Refresh state to match reality
terraform refresh
```

#### 4. Atlantis Functionality

```powershell
# Test Atlantis webhook
curl -X POST http://localhost:4141/events

# Check Atlantis logs
docker logs atlantis_atlantis_1

# Verify GitHub webhook connectivity
# (Check GitHub repository webhook settings)
```

## 📝 Documentation Requirements

### Incident Report Template

```markdown
# Rollback Incident Report

**Date/Time**: [Timestamp]
**Severity**: [Low/Medium/High/Critical]
**Duration**: [Time to resolve]

## Incident Description

[What happened?]

## Root Cause

[Why did it happen?]

## Actions Taken

[What rollback procedures were used?]

## Resolution

[How was it resolved?]

## Lessons Learned

[What can be improved?]

## Preventive Measures

[How to prevent recurrence?]
```

### Post-Rollback Checklist

-   [ ] All services restored to working state
-   [ ] No data loss occurred
-   [ ] Infrastructure costs under control
-   [ ] Security posture maintained
-   [ ] Incident documented
-   [ ] Team notified of resolution
-   [ ] Preventive measures identified
-   [ ] Process improvements planned

## 🛡️ Prevention Strategies

### Proactive Measures

#### 1. Regular Backups

```powershell
# Automated backup script (run daily)
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
cp terraform.tfstate "backups/terraform.tfstate.$timestamp"

# Keep only last 7 days of backups
Get-ChildItem "backups/terraform.tfstate.*" | Sort-Object CreationTime -Descending | Select-Object -Skip 7 | Remove-Item
```

#### 2. State Locking

```hcl
# terraform/backend.tf
terraform {
  backend "s3" {
    bucket         = "workshop-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

#### 3. Testing in Staging

```powershell
# Always test changes in staging first
terraform workspace select staging
terraform plan
terraform apply

# After validation, apply to production
terraform workspace select production
terraform apply
```

#### 4. Gradual Rollouts

```hcl
# Use terraform's create_before_destroy
resource "aws_instance" "app" {
  lifecycle {
    create_before_destroy = true
  }
}

# Blue-green deployment pattern
resource "aws_launch_template" "app_v2" {
  name_prefix = "app-v2-"
  # ... configuration
}
```

## 📞 Emergency Contacts

### Escalation Path

1. **Workshop Participant** → Self-resolution using this guide
2. **Workshop Facilitator** → Technical assistance and guidance
3. **AWS Support** → Infrastructure-level issues
4. **HashiCorp Support** → Terraform-specific problems

### Contact Information

-   **Workshop Support**: Available during workshop hours
-   **AWS Support**: 24/7 for production issues
-   **Community Forums**: Terraform and Atlantis communities

## 🔧 Tools and Resources

### Useful Commands

```powershell
# Quick status check
terraform state list | Measure-Object -Line

# Resource dependency graph
terraform graph | Out-File -Encoding utf8 graph.dot

# Cost estimation
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan | jq '.resource_changes[].change.actions'
```

### Emergency Scripts

```powershell
# Emergency stop script
function Stop-WorkshopResources {
    Write-Host "🚨 EMERGENCY STOP - Stopping all workshop resources..."

    # Stop EC2 instances
    $instances = aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "Reservations[].Instances[].InstanceId" --output text
    if ($instances) {
        aws ec2 stop-instances --instance-ids $instances.Split(' ')
        Write-Host "✅ Stopped EC2 instances"
    }

    # Disable auto-scaling
    $asgs = aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(Tags[?Key=='Workshop'].Value, 'terraform-atlantis')].AutoScalingGroupName" --output text
    foreach ($asg in $asgs.Split(' ')) {
        aws autoscaling suspend-processes --auto-scaling-group-name $asg
        Write-Host "✅ Suspended auto-scaling group: $asg"
    }

    Write-Host "🔄 Emergency stop completed. Resources are stopped but not destroyed."
}
```

---

**⚠️ Important Notes:**

-   Always backup before executing rollback procedures
-   Test rollback procedures in non-production environments
-   Document all actions taken during emergencies
-   Review and improve procedures after each incident

**Last Updated**: August 2025  
**Version**: 1.0  
**Author**: Nguyen Nhat Quang (Bright-04)
