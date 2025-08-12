# Maintenance Procedures - Terraform Atlantis Workshop

## 🔧 Ongoing Maintenance Tasks

This document provides comprehensive maintenance procedures for keeping the **Environment Provisioning Automation with Terraform and Atlantis** infrastructure running optimally and securely.

## 📅 Maintenance Schedule

### Daily Maintenance (5-10 minutes)

#### Morning Health Check

```powershell
# Quick system status check
.\scripts\04-health-monitoring.ps1

# Check Atlantis server
docker ps | grep atlantis
curl -s http://localhost:4141/healthz

# Verify AWS connectivity
aws sts get-caller-identity
```

#### Evening Cleanup

```powershell
# Clean temporary files
Remove-Item -Path "terraform/*.tfplan" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "logs/*.tmp" -Force -ErrorAction SilentlyContinue

# Backup current state
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
Copy-Item "terraform/terraform.tfstate" "backups/daily/terraform.tfstate.$timestamp"
```

### Weekly Maintenance (30-45 minutes)

#### Every Monday: Planning and Review

```powershell
# Review infrastructure changes from previous week
git log --oneline --since="1 week ago" terraform/

# Check resource utilization trends
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --start-time (Get-Date).AddDays(-7) --end-time (Get-Date) --period 86400 --statistics Average,Maximum

# Cost analysis
.\scripts\05-cost-monitoring.ps1
```

#### Every Wednesday: Updates and Patches

```powershell
# Update Terraform
terraform version
# Compare with latest version at https://releases.hashicorp.com/terraform/

# Update Atlantis container
docker-compose pull
docker-compose up -d

# Check for AWS CLI updates
aws --version
```

#### Every Friday: Security and Optimization

```powershell
# Security group review
aws ec2 describe-security-groups --filters "Name=tag:Workshop,Values=terraform-atlantis"

# Resource optimization check
aws ce get-rightsizing-recommendation --service EC2-Instance

# Backup verification
Test-Path "backups/weekly/terraform.tfstate.$(Get-Date -Format 'yyyyMMdd')"
```

### Monthly Maintenance (2-3 hours)

#### First Monday: Comprehensive Review

-   Complete infrastructure audit
-   Security assessment
-   Performance optimization
-   Documentation updates

#### Third Monday: Disaster Recovery Testing

-   Backup restoration testing
-   Rollback procedure validation
-   Recovery time testing
-   Documentation verification

## 🔄 System Updates

### Terraform Updates

#### Check for Updates

```powershell
# Current version
terraform version

# Check latest version
$latestVersion = Invoke-RestMethod -Uri "https://api.github.com/repos/hashicorp/terraform/releases/latest" | Select-Object -ExpandProperty tag_name
Write-Host "Current: $(terraform version -json | ConvertFrom-Json | Select-Object -ExpandProperty terraform_version)"
Write-Host "Latest: $($latestVersion -replace '^v','')"
```

#### Update Process

```powershell
# 1. Backup current state
Copy-Item "terraform/terraform.tfstate" "backups/pre-update-terraform.tfstate"

# 2. Download new Terraform version
# Visit https://www.terraform.io/downloads or use package manager

# 3. Test with current configuration
terraform version
terraform validate

# 4. Update provider versions if needed
terraform init -upgrade

# 5. Create test plan
terraform plan -out=update-test.tfplan

# 6. Verify no unexpected changes
terraform show update-test.tfplan
```

### Atlantis Updates

#### Container Updates

```powershell
# 1. Check current version
docker images | grep atlantis

# 2. Pull latest image
docker-compose pull

# 3. Backup current configuration
Copy-Item "atlantis.yaml" "backups/atlantis.yaml.$(Get-Date -Format 'yyyyMMdd')"

# 4. Update with minimal downtime
docker-compose down
docker-compose up -d

# 5. Verify functionality
Start-Sleep 30
curl http://localhost:4141/healthz
```

#### Configuration Updates

```powershell
# Validate atlantis.yaml syntax
# Use online YAML validator or VS Code YAML extension

# Test webhook connectivity
curl -X POST http://localhost:4141/events \
  -H "Content-Type: application/json" \
  -d '{"test": "webhook"}'
```

### AWS CLI Updates

#### Update Process

```powershell
# Check current version
aws --version

# Update via PowerShell (Windows)
winget upgrade Amazon.AWSCLI

# Or via MSI installer
# Download from https://aws.amazon.com/cli/

# Verify update
aws --version
aws sts get-caller-identity
```

## 🛡️ Security Maintenance

### Access Management

#### Monthly Access Review

```powershell
# Review IAM users and policies
aws iam list-users --query "Users[].[UserName,CreateDate]" --output table

# Check for unused access keys
aws iam generate-credential-report
aws iam get-credential-report --query 'Content' --output text | base64 -d > credential-report.csv

# Review security groups
aws ec2 describe-security-groups --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "SecurityGroups[].[GroupName,Description,IpPermissions[].IpRanges[].CidrIp]" --output table
```

#### Security Updates

```powershell
# Update EC2 instances
aws ssm send-command --document-name "AWS-RunPatchBaseline" --targets "Key=tag:Workshop,Values=terraform-atlantis" --parameters 'Operation=Install'

# Check patch compliance
aws ssm describe-instance-patch-states --instance-ids $(aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "Reservations[].Instances[].InstanceId" --output text)
```

### Certificate Management

#### SSL/TLS Certificate Renewal

```powershell
# Check certificate expiration (if using HTTPS)
openssl s_client -connect workshop-alb-xxxx.us-west-2.elb.amazonaws.com:443 -servername workshop-alb-xxxx.us-west-2.elb.amazonaws.com 2>/dev/null | openssl x509 -noout -dates

# ACM certificate check
aws acm list-certificates --query "CertificateSummaryList[].[CertificateArn,DomainName]" --output table
```

### Vulnerability Management

#### Security Scanning

```powershell
# Use AWS Inspector (if configured)
aws inspector2 list-findings --filter-criteria '{
    "resourceType": [{"comparison": "EQUALS", "value": "ECR_REPOSITORY"}]
}'

# Check for known vulnerabilities
aws ssm describe-instance-patch-states --instance-ids $(aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "Reservations[].Instances[].InstanceId" --output text)
```

## 🗂️ Data Management

### Backup Procedures

#### Automated Daily Backups

```powershell
# Create automated backup script
function Invoke-DailyBackup {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmm"
    $backupDir = "backups/daily"

    # Ensure backup directory exists
    if (!(Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force
    }

    # Backup Terraform state
    Copy-Item "terraform/terraform.tfstate" "$backupDir/terraform.tfstate.$timestamp"

    # Backup configuration files
    Copy-Item "atlantis.yaml" "$backupDir/atlantis.yaml.$timestamp"
    Copy-Item "docker-compose.yml" "$backupDir/docker-compose.yml.$timestamp"

    # Backup to S3 (optional)
    aws s3 sync $backupDir s3://workshop-backup-bucket/daily/$timestamp/

    # Cleanup old backups (keep 7 days)
    Get-ChildItem $backupDir -Name "terraform.tfstate.*" |
        Sort-Object CreationTime -Descending |
        Select-Object -Skip 7 |
        ForEach-Object { Remove-Item "$backupDir/$_" }

    Write-Host "✅ Daily backup completed: $timestamp"
}

# Schedule this function to run daily
```

#### Weekly Full Backups

```powershell
function Invoke-WeeklyBackup {
    $timestamp = Get-Date -Format "yyyyMMdd"
    $backupDir = "backups/weekly"

    # Create weekly backup directory
    $weeklyPath = "$backupDir/$timestamp"
    New-Item -ItemType Directory -Path $weeklyPath -Force

    # Full infrastructure backup
    terraform state pull > "$weeklyPath/terraform.state.json"

    # Export all outputs
    terraform output -json > "$weeklyPath/terraform.outputs.json"

    # Backup entire terraform directory
    Copy-Item -Recurse "terraform" "$weeklyPath/terraform-configs"

    # Backup scripts and documentation
    Copy-Item -Recurse "scripts" "$weeklyPath/scripts"
    Copy-Item -Recurse "docs" "$weeklyPath/docs"

    # Create archive
    Compress-Archive -Path $weeklyPath -DestinationPath "$backupDir/weekly-backup-$timestamp.zip"

    # Upload to S3
    aws s3 cp "$backupDir/weekly-backup-$timestamp.zip" s3://workshop-backup-bucket/weekly/

    Write-Host "✅ Weekly backup completed: $timestamp"
}
```

### Backup Verification

#### Test Backup Integrity

```powershell
function Test-BackupIntegrity {
    $latestBackup = Get-ChildItem "backups/daily" -Name "terraform.tfstate.*" | Sort-Object -Descending | Select-Object -First 1

    if ($latestBackup) {
        # Create temporary workspace for testing
        $testDir = "temp-restore-test"
        New-Item -ItemType Directory -Path $testDir -Force

        # Copy terraform configuration
        Copy-Item -Recurse "terraform/*" $testDir

        # Replace state with backup
        Copy-Item "backups/daily/$latestBackup" "$testDir/terraform.tfstate"

        # Test plan generation
        Push-Location $testDir
        try {
            terraform init -input=false
            $planResult = terraform plan -detailed-exitcode
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 2) {
                Write-Host "✅ Backup integrity verified"
            } else {
                Write-Warning "❌ Backup integrity check failed"
            }
        } finally {
            Pop-Location
            Remove-Item -Recurse $testDir -Force
        }
    } else {
        Write-Warning "❌ No backup found for verification"
    }
}
```

## 📊 Performance Maintenance

### Resource Optimization

#### Regular Performance Review

```powershell
# CPU utilization analysis
function Get-CPUTrends {
    $instances = aws ec2 describe-instances --filters "Name=tag:Workshop,Values=terraform-atlantis" --query "Reservations[].Instances[].InstanceId" --output text

    foreach ($instance in $instances.Split(' ')) {
        $cpuData = aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value=$instance --start-time (Get-Date).AddDays(-7) --end-time (Get-Date) --period 86400 --statistics Average,Maximum --query "Datapoints[].{Date:Timestamp,Avg:Average,Max:Maximum}"

        Write-Host "Instance: $instance"
        $cpuData | ConvertFrom-Json | Format-Table
    }
}
```

#### Memory and Disk Optimization

```powershell
# Memory utilization check
function Get-MemoryUsage {
    # Requires CloudWatch agent installation on EC2 instances
    aws cloudwatch get-metric-statistics --namespace CWAgent --metric-name mem_used_percent --start-time (Get-Date).AddHours(-24) --end-time (Get-Date) --period 3600 --statistics Average,Maximum
}

# Disk space monitoring
function Get-DiskUsage {
    aws cloudwatch get-metric-statistics --namespace CWAgent --metric-name disk_used_percent --start-time (Get-Date).AddHours(-24) --end-time (Get-Date) --period 3600 --statistics Average,Maximum
}
```

### Cost Optimization

#### Right-sizing Analysis

```powershell
function Invoke-RightSizingAnalysis {
    # Get rightsizing recommendations
    $recommendations = aws ce get-rightsizing-recommendation --service EC2-Instance --configuration '{
        "BenefitsConsidered": true,
        "RecommendationTarget": "SAME_INSTANCE_FAMILY"
    }' | ConvertFrom-Json

    if ($recommendations.RightsizingRecommendations) {
        Write-Host "💡 Rightsizing Recommendations Found:"
        foreach ($rec in $recommendations.RightsizingRecommendations) {
            Write-Host "  Instance: $($rec.CurrentInstance.ResourceId)"
            Write-Host "  Current: $($rec.CurrentInstance.InstanceType)"
            Write-Host "  Recommended: $($rec.RightsizingType)"
            Write-Host "  Estimated Savings: $($rec.EstimatedMonthlySavings.Amount) $($rec.EstimatedMonthlySavings.CurrencyCode)"
            Write-Host ""
        }
    } else {
        Write-Host "✅ No rightsizing recommendations at this time"
    }
}
```

#### Unused Resource Cleanup

```powershell
function Remove-UnusedResources {
    Write-Host "🧹 Scanning for unused resources..."

    # Find unattached EBS volumes
    $unusedVolumes = aws ec2 describe-volumes --filters "Name=status,Values=available" --query "Volumes[].{VolumeId:VolumeId,Size:Size,CreateTime:CreateTime}" --output json | ConvertFrom-Json

    if ($unusedVolumes) {
        Write-Host "📦 Found $($unusedVolumes.Count) unattached EBS volumes:"
        $unusedVolumes | Format-Table

        # Optionally delete after confirmation
        # foreach ($volume in $unusedVolumes) {
        #     aws ec2 delete-volume --volume-id $volume.VolumeId
        # }
    }

    # Find unused snapshots older than 30 days
    $oldSnapshots = aws ec2 describe-snapshots --owner-ids self --query "Snapshots[?StartTime<'$(Get-Date -Date (Get-Date).AddDays(-30) -Format 'yyyy-MM-dd')'T00:00:00.000Z'].{SnapshotId:SnapshotId,Description:Description,StartTime:StartTime}" --output json | ConvertFrom-Json

    if ($oldSnapshots) {
        Write-Host "📸 Found $($oldSnapshots.Count) old snapshots:"
        $oldSnapshots | Format-Table
    }
}
```

## 🔍 Monitoring Maintenance

### Alert Management

#### Alert Optimization

```powershell
# Review CloudWatch alarms
function Optimize-Alerts {
    $alarms = aws cloudwatch describe-alarms --query "MetricAlarms[].[AlarmName,StateValue,ActionsEnabled]" --output json | ConvertFrom-Json

    Write-Host "📊 Current Alarms Status:"
    foreach ($alarm in $alarms) {
        $status = if ($alarm[2]) { "Enabled" } else { "Disabled" }
        Write-Host "  $($alarm[0]): $($alarm[1]) ($status)"
    }

    # Check for alarms that have been in ALARM state for too long
    $problemAlarms = aws cloudwatch describe-alarms --state-value ALARM --query "MetricAlarms[?StateUpdatedTimestamp<'$(Get-Date -Date (Get-Date).AddHours(-24) -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')'].AlarmName" --output text

    if ($problemAlarms) {
        Write-Warning "⚠️  Alarms in ALARM state for >24h: $problemAlarms"
    }
}
```

#### Log Management

```powershell
# Clean up old logs
function Invoke-LogCleanup {
    # CloudWatch log retention
    $logGroups = aws logs describe-log-groups --query "logGroups[].logGroupName" --output text

    foreach ($logGroup in $logGroups.Split("`t")) {
        # Set retention policy (30 days for workshop)
        aws logs put-retention-policy --log-group-name $logGroup --retention-in-days 30
        Write-Host "✅ Set 30-day retention for $logGroup"
    }

    # Local log cleanup
    Get-ChildItem "logs" -Recurse -File | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item -Force
}
```

## 🔧 Infrastructure Maintenance

### Database Maintenance (if applicable)

#### RDS Maintenance

```powershell
# Check RDS instances
function Invoke-RDSMaintenance {
    $rdsInstances = aws rds describe-db-instances --query "DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,PreferredMaintenanceWindow,PreferredBackupWindow]" --output json | ConvertFrom-Json

    if ($rdsInstances) {
        Write-Host "🗄️  RDS Maintenance Status:"
        foreach ($instance in $rdsInstances) {
            Write-Host "  Instance: $($instance[0])"
            Write-Host "  Status: $($instance[1])"
            Write-Host "  Maintenance Window: $($instance[2])"
            Write-Host "  Backup Window: $($instance[3])"
            Write-Host ""
        }

        # Check for pending maintenance
        $pendingActions = aws rds describe-pending-maintenance-actions --query "PendingMaintenanceActions[].[ResourceIdentifier,PendingMaintenanceActionDetails[].Action]" --output json | ConvertFrom-Json

        if ($pendingActions) {
            Write-Host "📅 Pending Maintenance Actions:"
            $pendingActions | Format-Table
        }
    }
}
```

### Load Balancer Maintenance

#### ALB Health Checks

```powershell
function Test-LoadBalancerHealth {
    $loadBalancers = aws elbv2 describe-load-balancers --query "LoadBalancers[].[LoadBalancerName,DNSName,State.Code]" --output json | ConvertFrom-Json

    foreach ($lb in $loadBalancers) {
        Write-Host "🔄 Testing Load Balancer: $($lb[0])"

        try {
            $response = Invoke-WebRequest -Uri "http://$($lb[1])" -TimeoutSec 10
            Write-Host "  ✅ Status: $($response.StatusCode)"
        } catch {
            Write-Warning "  ❌ Health check failed: $($_.Exception.Message)"
        }

        # Check target group health
        $targetGroups = aws elbv2 describe-target-groups --load-balancer-arn $(aws elbv2 describe-load-balancers --names $lb[0] --query "LoadBalancers[0].LoadBalancerArn" --output text) --query "TargetGroups[].TargetGroupArn" --output text

        foreach ($tg in $targetGroups.Split("`t")) {
            $health = aws elbv2 describe-target-health --target-group-arn $tg --query "TargetHealthDescriptions[].[Target.Id,TargetHealth.State]" --output json | ConvertFrom-Json
            Write-Host "  Target Group Health:"
            $health | ForEach-Object { Write-Host "    $($_[0]): $($_[1])" }
        }
    }
}
```

## 📋 Maintenance Checklist Templates

### Daily Checklist

```markdown
## Daily Maintenance Checklist - $(Get-Date -Format 'yyyy-MM-dd')

### Morning (5 minutes)

-   [ ] Run health monitoring script
-   [ ] Check Atlantis server status
-   [ ] Verify AWS connectivity
-   [ ] Review overnight alerts

### Evening (5 minutes)

-   [ ] Clean temporary files
-   [ ] Create daily backup
-   [ ] Review day's activities
-   [ ] Check cost alerts

### Notes:

_Record any issues or observations_
```

### Weekly Checklist

```markdown
## Weekly Maintenance Checklist - Week of $(Get-Date -Format 'yyyy-MM-dd')

### Monday - Planning (15 minutes)

-   [ ] Review infrastructure changes
-   [ ] Analyze resource utilization
-   [ ] Cost analysis
-   [ ] Plan week's activities

### Wednesday - Updates (30 minutes)

-   [ ] Check for Terraform updates
-   [ ] Update Atlantis container
-   [ ] Update AWS CLI
-   [ ] Apply security patches

### Friday - Review (15 minutes)

-   [ ] Security group review
-   [ ] Resource optimization check
-   [ ] Backup verification
-   [ ] Week summary report

### Notes:

_Document any maintenance activities performed_
```

### Monthly Checklist

```markdown
## Monthly Maintenance Checklist - $(Get-Date -Format 'MMMM yyyy')

### Infrastructure Review (60 minutes)

-   [ ] Complete infrastructure audit
-   [ ] Security assessment
-   [ ] Performance analysis
-   [ ] Cost optimization review

### Updates and Patches (30 minutes)

-   [ ] Major version updates
-   [ ] Security patches
-   [ ] Configuration updates
-   [ ] Documentation updates

### Testing (60 minutes)

-   [ ] Disaster recovery testing
-   [ ] Backup restoration test
-   [ ] Performance testing
-   [ ] Security testing

### Reporting (30 minutes)

-   [ ] Monthly status report
-   [ ] Cost analysis report
-   [ ] Performance metrics
-   [ ] Lessons learned

### Notes:

_Document major maintenance activities and outcomes_
```

---

**🔄 Maintenance Best Practices:**

-   Schedule maintenance during low-usage periods
-   Always backup before making changes
-   Test procedures in staging environment first
-   Document all maintenance activities
-   Monitor systems closely after maintenance
-   Have rollback plans ready

**Last Updated**: August 2025  
**Version**: 1.0  
**Author**: Nguyen Nhat Quang (Bright-04)
