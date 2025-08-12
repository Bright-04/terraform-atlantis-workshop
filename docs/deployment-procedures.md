# Deployment Procedures - Terraform Atlantis Workshop

## 🚀 Complete Deployment Guide

This document provides comprehensive step-by-step procedures for deploying the **Environment Provisioning Automation with Terraform and Atlantis** infrastructure to AWS production environment.

## 📋 Pre-Deployment Checklist

### Prerequisites Verification

-   ✅ **AWS Account**: Active AWS account with appropriate permissions
-   ✅ **AWS CLI**: Installed and configured with credentials
-   ✅ **Terraform**: Version 1.6.0 or later installed
-   ✅ **PowerShell**: Available for script execution
-   ✅ **Git**: Version control system installed
-   ✅ **Internet Access**: Required for AWS API calls and downloads

### Required AWS Permissions

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": ["ec2:*", "s3:*", "iam:*", "cloudwatch:*", "vpc:*", "elasticloadbalancing:*", "autoscaling:*"],
			"Resource": "*"
		}
	]
}
```

### Environment Validation

```powershell
# Verify AWS configuration
aws sts get-caller-identity
aws configure get region

# Verify Terraform installation
terraform version

# Verify PowerShell execution policy
Get-ExecutionPolicy
```

## 🎯 Deployment Strategy

### Deployment Phases

1. **Phase 1**: Environment Setup and Validation
2. **Phase 2**: Infrastructure Deployment
3. **Phase 3**: Compliance Validation
4. **Phase 4**: Monitoring Setup
5. **Phase 5**: Verification and Testing

### Deployment Options

-   **Automated Deployment**: Using PowerShell scripts
-   **Manual Deployment**: Step-by-step Terraform commands
-   **GitOps Deployment**: Using Atlantis workflow

## 📦 Phase 1: Environment Setup and Validation

### Step 1.1: Clone Repository

```powershell
# Clone the workshop repository
git clone <repository-url>
cd terraform-atlantis-workshop

# Verify repository structure
ls
```

### Step 1.2: Configure Environment

```powershell
# Run environment setup script
.\scripts\00-setup-env.ps1

# Verify environment configuration
.\scripts\01-validate-environment.ps1
```

### Step 1.3: AWS Configuration

```powershell
# Configure AWS credentials (if not already done)
aws configure

# Verify AWS access
aws sts get-caller-identity
aws ec2 describe-regions --query 'Regions[0].RegionName' --output text
```

### Step 1.4: Terraform Initialization

```powershell
# Navigate to Terraform directory
cd terraform

# Initialize Terraform
terraform init

# Verify initialization
terraform version
terraform providers
```

## 🏗️ Phase 2: Infrastructure Deployment

### Step 2.1: Configure Variables

```powershell
# Copy example variables file
Copy-Item terraform.tfvars.example terraform.tfvars

# Edit variables for your environment
notepad terraform.tfvars
```

**Example terraform.tfvars configuration:**

```hcl
# AWS Configuration
aws_region = "us-east-1"
environment = "production"

# Instance Configuration
instance_type = "t3.micro"
instance_count = 2

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

# Tags
tags = {
  Environment = "production"
  Project     = "terraform-atlantis-workshop"
  CostCenter  = "IT-001"
  Owner       = "DevOps Team"
}
```

### Step 2.2: Validate Configuration

```powershell
# Validate Terraform configuration
terraform validate

# Check configuration syntax
terraform fmt -check

# Review planned changes
terraform plan -out=tfplan
```

### Step 2.3: Deploy Infrastructure

```powershell
# Apply infrastructure changes
terraform apply -auto-approve

# Or apply with plan file
terraform apply tfplan

# Monitor deployment progress
# This may take 5-10 minutes
```

### Step 2.4: Verify Deployment

```powershell
# Check deployment status
terraform show

# View outputs
terraform output

# Verify AWS resources
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' --output table
```

## ✅ Phase 3: Compliance Validation

### Step 3.1: Run Compliance Checks

```powershell
# Run compliance validation
terraform plan

# Check for any policy violations
# Expected: No violations detected
```

### Step 3.2: Test Policy Violations (Optional)

```powershell
# Test violation detection
# Edit terraform/test-policy-violations.tf to introduce violations
# Run: terraform plan
# Verify violations are detected and reported
```

### Step 3.3: Verify Compliance Rules

```powershell
# Check instance type compliance
aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceType' --output table

# Verify required tags
aws ec2 describe-instances --query 'Reservations[*].Instances[*].Tags' --output table

# Check S3 bucket naming
aws s3 ls
```

## 📊 Phase 4: Monitoring Setup

### Step 4.1: Configure Health Monitoring

```powershell
# Navigate back to root directory
cd ..

# Set up health monitoring
.\scripts\04-health-monitoring.ps1

# Verify monitoring configuration
.\monitoring\health-check-aws.ps1
```

### Step 4.2: Configure Cost Monitoring

```powershell
# Set up cost monitoring
.\scripts\05-cost-monitoring.ps1

# Verify cost monitoring
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

### Step 4.3: Set Up CloudWatch Alarms

```powershell
# Create CloudWatch alarms for monitoring
aws cloudwatch put-metric-alarm \
  --alarm-name "HighCPUUtilization" \
  --alarm-description "Alarm when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

## 🧪 Phase 5: Verification and Testing

### Step 5.1: Infrastructure Health Check

```powershell
# Run comprehensive health check
.\scripts\04-health-monitoring.ps1

# Check specific components
aws ec2 describe-instance-status --include-all-instances
aws elbv2 describe-load-balancers
aws s3 ls
```

### Step 5.2: Application Testing

```powershell
# Get public IP addresses
cd terraform
$outputs = terraform output -json | ConvertFrom-Json

# Test web server access
foreach ($ip in $outputs.public_ips.value) {
    try {
        $response = Invoke-WebRequest -Uri "http://$ip" -UseBasicParsing -TimeoutSec 10
        Write-Host "✅ Web server at $ip is responding: $($response.StatusCode)"
    }
    catch {
        Write-Host "❌ Web server at $ip is not responding: $($_.Exception.Message)"
    }
}
```

### Step 5.3: Security Verification

```powershell
# Verify security group configuration
aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupName,GroupId,IpPermissions]' --output table

# Check IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `terraform`)].[RoleName,Arn]' --output table

# Verify S3 bucket encryption
aws s3api get-bucket-encryption --bucket <bucket-name>
```

## 🔄 GitOps Deployment (Alternative)

### Step 5.4: Atlantis Setup (Optional)

```powershell
# Set up GitHub integration
.\scripts\02-setup-github-actions.ps1

# Start Atlantis server
docker-compose up -d

# Access Atlantis UI
# Open browser to: http://localhost:4141
```

### Step 5.5: GitOps Workflow

```bash
# Create feature branch
git checkout -b feature/infrastructure-update

# Make infrastructure changes
# Edit terraform files

# Commit and push changes
git add .
git commit -m "Update infrastructure configuration"
git push origin feature/infrastructure-update

# Create pull request
# Atlantis will automatically run terraform plan
# Review plan output in PR comments
# Approve and merge to trigger apply
```

## 📈 Post-Deployment Activities

### Step 6.1: Documentation Update

```powershell
# Update deployment documentation
# Record deployment details
# Update runbooks and procedures
```

### Step 6.2: Team Training

```powershell
# Conduct team training on new infrastructure
# Review operational procedures
# Practice incident response scenarios
```

### Step 6.3: Monitoring Verification

```powershell
# Verify all monitoring is working
.\scripts\04-health-monitoring.ps1
.\scripts\05-cost-monitoring.ps1

# Set up alerting notifications
# Configure escalation procedures
```

## 🚨 Emergency Procedures

### Rollback Procedure

```powershell
# Emergency rollback
.\scripts\06-rollback-procedures.ps1

# Or manual rollback
cd terraform
terraform destroy -auto-approve
```

### Incident Response

```powershell
# Check infrastructure status
.\scripts\04-health-monitoring.ps1

# Review CloudWatch logs
aws logs describe-log-groups
aws logs filter-log-events --log-group-name /aws/ec2/terraform-workshop

# Contact support team
# Follow incident response procedures
```

## 📊 Deployment Verification Checklist

### Infrastructure Components

-   ✅ **VPC**: Created with proper CIDR blocks
-   ✅ **Subnets**: Public and private subnets configured
-   ✅ **EC2 Instances**: Running with correct instance types
-   ✅ **Security Groups**: Proper access controls configured
-   ✅ **S3 Buckets**: Created with encryption and versioning
-   ✅ **IAM Roles**: Least privilege access configured
-   ✅ **CloudWatch**: Monitoring and logging enabled

### Compliance Validation

-   ✅ **Instance Types**: Only compliant types deployed
-   ✅ **Required Tags**: All resources properly tagged
-   ✅ **S3 Naming**: Buckets follow naming convention
-   ✅ **Security**: Encryption and access controls in place

### Operational Readiness

-   ✅ **Monitoring**: Health checks configured and working
-   ✅ **Cost Controls**: Cost monitoring and alerts set up
-   ✅ **Documentation**: Procedures and runbooks updated
-   ✅ **Team Training**: Staff trained on new infrastructure

## 🔧 Troubleshooting Deployment Issues

### Common Issues and Solutions

**Issue: Terraform Init Fails**

```powershell
# Solution: Clear Terraform cache
Remove-Item -Recurse -Force .terraform
terraform init
```

**Issue: AWS Credentials Not Found**

```powershell
# Solution: Configure AWS credentials
aws configure
aws sts get-caller-identity
```

**Issue: Insufficient Permissions**

```powershell
# Solution: Check IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name <username>
```

**Issue: Resource Creation Fails**

```powershell
# Solution: Check resource limits
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A
aws service-quotas get-service-quota --service-code vpc --quota-code L-F678F1CE
```

## 📞 Support and Escalation

### Getting Help

-   **Documentation**: Check [Troubleshooting Guide](troubleshooting-guide.md)
-   **FAQ**: Review [FAQ](faq.md)
-   **Issues**: Create GitHub issue with detailed information
-   **Contact**: cbl.nguyennhatquang2809@gmail.com

### Escalation Matrix

1. **Level 1**: Check documentation and troubleshooting guides
2. **Level 2**: Contact DevOps team lead
3. **Level 3**: Escalate to infrastructure architect
4. **Level 4**: Contact AWS support (if applicable)

---

**📚 Related Documentation**

-   [Quick Start Guide](quick-start-guide.md)
-   [Architecture Overview](architecture-overview.md)
-   [Compliance Validation](compliance-validation.md)
-   [Troubleshooting Guide](troubleshooting-guide.md)
