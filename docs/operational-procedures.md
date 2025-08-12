# Operational Procedures - Terraform Atlantis Workshop

## 🔧 Day-to-Day Operations Guide

This document provides comprehensive operational procedures for managing the **Environment Provisioning Automation with Terraform and Atlantis** infrastructure on a daily basis.

## 📅 Daily Operations

### Morning Checklist

#### System Health Check (15 minutes)

```powershell
# 1. Check overall system status
.\scripts\04-health-monitoring.ps1

# 2. Verify AWS resource status
aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "Reservations[].Instances[].[InstanceId,State.Name,InstanceType]" --output table

# 3. Check cost status
.\scripts\05-cost-monitoring.ps1

# 4. Verify Atlantis server health
curl -s http://localhost:4141/healthz
```

#### Log Review

```powershell
# Check application logs
aws logs describe-log-groups --log-group-name-prefix /aws/ec2/workshop

# Review Atlantis logs
docker logs atlantis_atlantis_1 --tail 50

# Check system logs
Get-EventLog -LogName System -Newest 10 | Where-Object {$_.EntryType -eq "Error"}
```

### Afternoon Checklist

#### Performance Monitoring

```powershell
# Check CPU and memory usage
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value=i-xxxxxxxxx --start-time (Get-Date).AddHours(-1) --end-time (Get-Date) --period 300 --statistics Average

# Monitor network traffic
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name NetworkIn --dimensions Name=InstanceId,Value=i-xxxxxxxxx --start-time (Get-Date).AddHours(-1) --end-time (Get-Date) --period 300 --statistics Sum
```

#### Security Check

```powershell
# Verify security group configurations
aws ec2 describe-security-groups --filters "Name=tag:Workshop,Values=terraform-atlantis"

# Check for unauthorized access attempts
aws logs filter-log-events --log-group-name /aws/ec2/workshop --filter-pattern "Failed"
```

### Evening Wrap-up

#### Backup Operations

```powershell
# Create daily terraform state backup
$timestamp = Get-Date -Format "yyyyMMdd"
cp terraform/terraform.tfstate "backups/daily/terraform.tfstate.$timestamp"

# Backup important configurations
aws s3 sync ./terraform s3://workshop-backup-bucket/terraform/$timestamp/
```

#### Resource Cleanup

```powershell
# Clean up temporary files
Remove-Item -Path "terraform/*.tfplan" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "terraform/.terraform/terraform.tfstate*" -Force -ErrorAction SilentlyContinue

# Clear old log files
Get-ChildItem -Path "logs" -Name "*.log" | Where-Object {$_.CreationTime -lt (Get-Date).AddDays(-7)} | Remove-Item
```

## 🔄 Weekly Operations

### Monday: Planning and Review

#### Infrastructure Review

```powershell
# Generate infrastructure report
terraform show -json | jq '.values.root_module.resources[] | {type: .type, name: .name, values: .values}' > reports/weekly-infrastructure-$(Get-Date -Format 'yyyyMMdd').json

# Cost analysis
aws ce get-cost-and-usage --time-period Start=(Get-Date).AddDays(-7).ToString('yyyy-MM-dd'),End=(Get-Date).ToString('yyyy-MM-dd') --granularity DAILY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE
```

#### Capacity Planning

```powershell
# Analyze resource utilization trends
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --start-time (Get-Date).AddDays(-7) --end-time (Get-Date) --period 86400 --statistics Average,Maximum

# Review auto-scaling metrics
aws autoscaling describe-scaling-activities --auto-scaling-group-name workshop-asg --max-items 10
```

### Wednesday: Maintenance Window

#### System Updates

```powershell
# Update Terraform if needed
terraform version
# Download and install latest version if required

# Update Atlantis container
docker-compose pull
docker-compose up -d

# Update AWS CLI
aws --version
# Update via PowerShell or package manager
```

#### Security Updates

```powershell
# Review security groups
aws ec2 describe-security-groups --filters "Name=tag:Workshop,Values=terraform-atlantis" | jq '.SecurityGroups[] | {GroupName: .GroupName, Rules: .IpPermissions}'

# Check for unused resources
aws ec2 describe-volumes --filters "Name=status,Values=available"
aws ec2 describe-snapshots --owner-ids self --filters "Name=status,Values=completed"
```

### Friday: Reporting and Optimization

#### Performance Report

```powershell
# Generate weekly performance report
$report = @{
    Week = "$(Get-Date -Format 'yyyy-MM-dd')"
    Instances = (aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "Reservations[].Instances | length(@)")
    AvgCPU = "TBD - Get from CloudWatch"
    TotalCost = "TBD - Get from Cost Explorer"
    Incidents = "0"  # Update based on actual incidents
}
$report | ConvertTo-Json | Out-File "reports/weekly-report-$(Get-Date -Format 'yyyyMMdd').json"
```

#### Cost Optimization

```powershell
# Identify unused resources
aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" --query "Reservations[].Instances[].[InstanceId,InstanceType,LaunchTime]" --output table

# Review storage costs
aws ec2 describe-volumes --query "Volumes[].[VolumeId,Size,VolumeType,State]" --output table
```

## 🎯 Monthly Operations

### First Monday: Comprehensive Review

#### Infrastructure Audit

```powershell
# Complete infrastructure inventory
terraform state list > reports/monthly-inventory-$(Get-Date -Format 'yyyyMM').txt

# Security audit
aws iam generate-credential-report
aws iam get-credential-report --query 'Content' --output text | base64 -d > reports/iam-credential-report-$(Get-Date -Format 'yyyyMM').csv
```

#### Cost Analysis

```powershell
# Monthly cost breakdown
aws ce get-cost-and-usage --time-period Start=(Get-Date).AddDays(-30).ToString('yyyy-MM-dd'),End=(Get-Date).ToString('yyyy-MM-dd') --granularity MONTHLY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE

# Cost optimization recommendations
aws ce get-rightsizing-recommendation --service EC2-Instance
```

### Third Monday: Disaster Recovery Testing

#### Backup Verification

```powershell
# Test state backup restoration
cp terraform/terraform.tfstate terraform/terraform.tfstate.original
cp backups/terraform.tfstate.test terraform/terraform.tfstate
terraform plan  # Should show differences if backup is older
cp terraform/terraform.tfstate.original terraform/terraform.tfstate  # Restore original
```

#### Recovery Procedures Test

```powershell
# Test rollback procedures (in staging)
terraform workspace select staging
.\scripts\06-rollback-procedures.ps1
# Verify rollback success
.\scripts\01-validate-environment.ps1
```

## 🔍 Monitoring Operations

### Real-time Monitoring

#### Dashboard Checks

```powershell
# CloudWatch dashboard URLs
$dashboards = @(
    "https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#dashboards:name=WorkshopInfrastructure"
    "https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#dashboards:name=WorkshopApplications"
)

# Open dashboards for review
foreach ($dashboard in $dashboards) {
    Start-Process $dashboard
}
```

#### Alert Management

```powershell
# Check CloudWatch alarms
aws cloudwatch describe-alarms --state-value ALARM --query "MetricAlarms[].[AlarmName,StateReason]" --output table

# Review SNS topic subscriptions
aws sns list-subscriptions --query "Subscriptions[].[TopicArn,Protocol,Endpoint]" --output table
```

### Proactive Monitoring

#### Threshold Monitoring

```powershell
# CPU utilization check
$instances = aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "Reservations[].Instances[].InstanceId" --output text
foreach ($instance in $instances.Split(' ')) {
    $cpu = aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value=$instance --start-time (Get-Date).AddMinutes(-15) --end-time (Get-Date) --period 300 --statistics Average --query "Datapoints[0].Average"
    if ($cpu -gt 80) {
        Write-Warning "High CPU utilization on $instance: $cpu%"
    }
}
```

#### Predictive Analysis

```powershell
# Trend analysis for capacity planning
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --start-time (Get-Date).AddDays(-7) --end-time (Get-Date) --period 86400 --statistics Average | ConvertTo-Json | Out-File "trends/cpu-trend-$(Get-Date -Format 'yyyyMMdd').json"
```

## 🛠️ Maintenance Operations

### Routine Maintenance

#### Terraform Maintenance

```powershell
# Update provider versions
terraform init -upgrade

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Generate new plan
terraform plan -out=maintenance.tfplan
```

#### Atlantis Maintenance

```powershell
# Update Atlantis configuration
# Edit atlantis.yaml if needed

# Restart Atlantis with new configuration
docker-compose down
docker-compose up -d

# Verify configuration
curl http://localhost:4141/healthz
```

### Scheduled Maintenance

#### Patch Management

```powershell
# Check for OS updates on EC2 instances
aws ssm describe-instance-information --query "InstanceInformationList[].[InstanceId,PlatformName,PlatformVersion]" --output table

# Update EC2 instances using Systems Manager
aws ssm send-command --document-name "AWS-RunPatchBaseline" --targets "Key=tag:Workshop,Values=terraform-atlantis"
```

#### Database Maintenance (if applicable)

```powershell
# RDS maintenance (if using RDS)
aws rds describe-pending-maintenance-actions
aws rds describe-db-instances --query "DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,PreferredMaintenanceWindow]" --output table
```

## 📊 Performance Operations

### Performance Monitoring

#### Application Performance

```powershell
# Web application response time
$response = Measure-Command { curl -s http://workshop-alb-xxxx.us-west-2.elb.amazonaws.com }
Write-Host "Response time: $($response.TotalMilliseconds)ms"

# Database performance (if applicable)
aws rds describe-db-instances --query "DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,AllocatedStorage]" --output table
```

#### Infrastructure Performance

```powershell
# Disk I/O metrics
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name DiskReadOps --start-time (Get-Date).AddHours(-1) --end-time (Get-Date) --period 300 --statistics Sum

# Network performance
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name NetworkPacketsIn --start-time (Get-Date).AddHours(-1) --end-time (Get-Date) --period 300 --statistics Sum
```

### Performance Optimization

#### Resource Right-sizing

```powershell
# Analyze instance utilization
aws ce get-rightsizing-recommendation --service EC2-Instance --configuration '{
    "BenefitsConsidered": true,
    "RecommendationTarget": "SAME_INSTANCE_FAMILY"
}'

# Review auto-scaling policies
aws autoscaling describe-policies --auto-scaling-group-name workshop-asg
```

#### Cost Optimization

```powershell
# Identify idle resources
aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" --query "length(Reservations[].Instances[])"

# Review unused volumes
aws ec2 describe-volumes --filters "Name=status,Values=available" --query "length(Volumes[])"
```

## 📋 Compliance Operations

### Regular Compliance Checks

#### Security Compliance

```powershell
# Run security policy validation
cd terraform
terraform plan -var-file="compliance.tfvars"

# Check Open Policy Agent policies
opa test policies/
```

#### Cost Compliance

```powershell
# Check against budget thresholds
aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text)

# Validate cost controls
.\scripts\05-cost-monitoring.ps1
```

### Audit Operations

#### Change Auditing

```powershell
# Review Terraform state changes
git log --oneline terraform/terraform.tfstate

# Check Atlantis operation history
docker logs atlantis_atlantis_1 | grep -E "(plan|apply)" | tail -20
```

#### Access Auditing

```powershell
# Review CloudTrail logs
aws logs filter-log-events --log-group-name CloudTrail/Workshop --start-time $(([DateTimeOffset]::Now.AddHours(-24)).ToUnixTimeMilliseconds()) --filter-pattern "{ $.eventSource = ec2.amazonaws.com }"

# Check IAM access
aws iam generate-credential-report
```

## 🚨 Incident Response Operations

### Incident Detection

#### Automated Alerts

```powershell
# Check for active alarms
aws cloudwatch describe-alarms --state-value ALARM --output table

# Review recent errors
aws logs filter-log-events --log-group-name /aws/ec2/workshop --start-time $(([DateTimeOffset]::Now.AddHours(-1)).ToUnixTimeMilliseconds()) --filter-pattern "ERROR"
```

#### Manual Checks

```powershell
# Health check script
.\scripts\04-health-monitoring.ps1

# Quick status verification
terraform state list | Measure-Object -Line
aws ec2 describe-instance-status --include-all-instances
```

### Incident Response

#### Immediate Response

```powershell
# Emergency procedures
if ($criticalIssue) {
    .\scripts\06-rollback-procedures.ps1
    # Follow rollback documentation
}

# Escalation
Write-Host "Incident detected - following escalation procedures"
```

## 📈 Reporting Operations

### Daily Reports

#### Status Dashboard

```powershell
# Generate daily status report
$status = @{
    Date = Get-Date -Format 'yyyy-MM-dd'
    InstanceCount = (aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "length(Reservations[].Instances[])")
    RunningInstances = (aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" "Name=instance-state-name,Values=running" --query "length(Reservations[].Instances[])")
    HealthStatus = "OK"  # Update based on health checks
    CostAlert = $false   # Update based on cost monitoring
}
$status | ConvertTo-Json | Out-File "reports/daily/status-$(Get-Date -Format 'yyyyMMdd').json"
```

### Weekly Reports

#### Comprehensive Status

```powershell
# Generate weekly operational report
$weeklyReport = @{
    Week = "Week of $(Get-Date -Format 'yyyy-MM-dd')"
    TotalUptime = "99.9%"  # Calculate from monitoring data
    IncidentCount = 0      # Count from incident logs
    CostSummary = "Within budget"  # From cost monitoring
    SecurityStatus = "No issues"   # From security checks
    PerformanceMetrics = @{
        AvgCPU = "15%"     # From CloudWatch
        AvgMemory = "60%"  # From CloudWatch
        ResponseTime = "200ms"  # From application monitoring
    }
}
$weeklyReport | ConvertTo-Json | Out-File "reports/weekly/report-$(Get-Date -Format 'yyyyMMdd').json"
```

## 🔧 Automation Scripts

### Custom Operations Scripts

#### Health Check Automation

```powershell
# Enhanced health check script
function Invoke-DetailedHealthCheck {
    Write-Host "🔍 Starting detailed health check..."

    # Infrastructure health
    $instances = aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "Reservations[].Instances[].[InstanceId,State.Name]" --output text
    Write-Host "✅ EC2 instances checked: $($instances.Split("`n").Count) instances"

    # Application health
    try {
        $response = Invoke-WebRequest -Uri "http://workshop-alb-xxxx.us-west-2.elb.amazonaws.com" -TimeoutSec 10
        Write-Host "✅ Application responsive: HTTP $($response.StatusCode)"
    } catch {
        Write-Warning "❌ Application health check failed: $($_.Exception.Message)"
    }

    # Atlantis health
    try {
        $atlantis = Invoke-WebRequest -Uri "http://localhost:4141/healthz" -TimeoutSec 5
        Write-Host "✅ Atlantis healthy: $($atlantis.StatusCode)"
    } catch {
        Write-Warning "❌ Atlantis health check failed: $($_.Exception.Message)"
    }

    Write-Host "🏁 Health check completed"
}
```

#### Cost Monitoring Automation

```powershell
# Automated cost alerting
function Invoke-CostAlert {
    $currentCost = aws ce get-cost-and-usage --time-period Start=$(Get-Date -Format 'yyyy-MM-dd'),End=$(Get-Date -Format 'yyyy-MM-dd') --granularity DAILY --metrics BlendedCost --query "ResultsByTime[0].Total.BlendedCost.Amount" --output text

    $threshold = 50.00  # Daily cost threshold

    if ([float]$currentCost -gt $threshold) {
        Write-Warning "💰 COST ALERT: Current daily cost $currentCost exceeds threshold $threshold"
        # Send notification (email, Slack, etc.)
    } else {
        Write-Host "✅ Cost within limits: $currentCost"
    }
}
```

---

**📝 Notes:**

-   Customize scripts and procedures based on your specific environment
-   Regular review and updates of operational procedures are essential
-   Document any deviations or customizations made to these procedures
-   Ensure all team members are trained on these operational procedures

**Last Updated**: August 2025  
**Version**: 1.0  
**Author**: Nguyen Nhat Quang (Bright-04)
