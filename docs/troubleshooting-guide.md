# Troubleshooting Guide - Terraform Atlantis Workshop

## 🔧 Common Issues and Solutions

This comprehensive troubleshooting guide covers common issues encountered during the **Environment Provisioning Automation with Terraform and Atlantis** workshop and provides step-by-step solutions.

## 📋 Quick Diagnostic Checklist

### Pre-Troubleshooting Steps

-   ✅ **Check Prerequisites**: Verify all required tools are installed
-   ✅ **Validate Environment**: Ensure AWS credentials and permissions
-   ✅ **Review Logs**: Check error messages and output
-   ✅ **Verify Configuration**: Confirm settings and variables

## 🚨 Critical Issues

### Issue: AWS Credentials Not Configured

**Symptoms**:

```
Error: No valid credential sources found for AWS Provider
```

**Solutions**:

#### Solution 1: Configure AWS CLI

```powershell
# Configure AWS credentials
aws configure

# Verify configuration
aws sts get-caller-identity
```

#### Solution 2: Set Environment Variables

```powershell
# Set environment variables
$env:AWS_ACCESS_KEY_ID = "your-access-key"
$env:AWS_SECRET_ACCESS_KEY = "your-secret-key"
$env:AWS_DEFAULT_REGION = "us-east-1"

# Verify
aws sts get-caller-identity
```

#### Solution 3: Use AWS Profiles

```powershell
# Create named profile
aws configure --profile workshop

# Use profile
aws sts get-caller-identity --profile workshop
```

### Issue: Insufficient AWS Permissions

**Symptoms**:

```
Error: AccessDenied: User: arn:aws:iam::123456789012:user/username is not authorized to perform: ec2:DescribeInstances
```

**Solutions**:

#### Solution 1: Check Current Permissions

```powershell
# Check current user
aws iam get-user

# List attached policies
aws iam list-attached-user-policies --user-name <username>

# Check inline policies
aws iam list-user-policies --user-name <username>
```

#### Solution 2: Required IAM Policy

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

#### Solution 3: Create IAM User with Required Permissions

```powershell
# Create IAM user
aws iam create-user --user-name terraform-workshop

# Attach policy
aws iam attach-user-policy --user-name terraform-workshop --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access keys
aws iam create-access-key --user-name terraform-workshop
```

## 🔧 Terraform Issues

### Issue: Terraform Init Fails

**Symptoms**:

```
Error: Failed to query available provider packages
```

**Solutions**:

#### Solution 1: Clear Terraform Cache

```powershell
# Remove .terraform directory
Remove-Item -Recurse -Force .terraform

# Reinitialize
terraform init
```

#### Solution 2: Check Internet Connectivity

```powershell
# Test connectivity to Terraform registry
Test-NetConnection -ComputerName registry.terraform.io -Port 443

# Check DNS resolution
nslookup registry.terraform.io
```

#### Solution 3: Use Terraform Mirror

```powershell
# Set Terraform mirror
$env:TF_PLUGIN_MIRROR = "https://releases.hashicorp.com/terraform-provider-aws"

# Initialize with mirror
terraform init
```

### Issue: Terraform Plan Fails

**Symptoms**:

```
Error: Invalid value for variable
```

**Solutions**:

#### Solution 1: Validate Variables

```powershell
# Check variable definitions
terraform validate

# Review variable values
Get-Content terraform.tfvars
```

#### Solution 2: Fix Variable Issues

```hcl
# Example: Fix instance type variable
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium."
  }
}
```

#### Solution 3: Use Default Values

```powershell
# Run plan with defaults
terraform plan -var-file=terraform.tfvars.example
```

### Issue: Terraform Apply Fails

**Symptoms**:

```
Error: Error creating EC2 instance: InsufficientInstanceCapacity
```

**Solutions**:

#### Solution 1: Check Resource Limits

```powershell
# Check EC2 limits
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A

# Check VPC limits
aws service-quotas get-service-quota --service-code vpc --quota-code L-F678F1CE
```

#### Solution 2: Use Different Region

```powershell
# List available regions
aws ec2 describe-regions --query 'Regions[*].RegionName' --output table

# Set different region
$env:AWS_DEFAULT_REGION = "us-west-2"
terraform plan
```

#### Solution 3: Use Different Instance Type

```hcl
# Update instance type in terraform.tfvars
instance_type = "t3.small"  # Try different type
```

## 🔧 PowerShell Issues

### Issue: Execution Policy Restriction

**Symptoms**:

```
File cannot be loaded because running scripts is disabled on this system
```

**Solutions**:

#### Solution 1: Allow Script Execution

```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify change
Get-ExecutionPolicy
```

#### Solution 2: Run Script with Bypass

```powershell
# Run script with bypass
PowerShell -ExecutionPolicy Bypass -File .\scripts\00-setup-env.ps1
```

#### Solution 3: Unblock Files

```powershell
# Unblock all files in directory
Get-ChildItem -Recurse | Unblock-File
```

### Issue: PowerShell Module Not Found

**Symptoms**:

```
The term 'Invoke-WebRequest' is not recognized
```

**Solutions**:

#### Solution 1: Check PowerShell Version

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Update PowerShell if needed
# Download from: https://github.com/PowerShell/PowerShell/releases
```

#### Solution 2: Install Required Modules

```powershell
# Install AWS.Tools module
Install-Module -Name AWS.Tools.Installer -Force

# Import modules
Import-Module AWS.Tools.EC2
Import-Module AWS.Tools.S3
```

## 🔧 Atlantis Issues

### Issue: Atlantis Not Accessible

**Symptoms**:

```
Cannot connect to Atlantis server
```

**Solutions**:

#### Solution 1: Check Docker Status

```powershell
# Check if Docker is running
docker ps

# Start Docker if needed
Start-Service docker
```

#### Solution 2: Check Port Availability

```powershell
# Check if port 4141 is in use
netstat -an | findstr :4141

# Kill process using port if needed
netstat -ano | findstr :4141
taskkill /PID <PID> /F
```

#### Solution 3: Restart Atlantis

```powershell
# Stop Atlantis
docker-compose down

# Start Atlantis
docker-compose up -d

# Check logs
docker-compose logs atlantis
```

### Issue: GitHub Webhook Not Working

**Symptoms**:

```
Webhook delivery failed
```

**Solutions**:

#### Solution 1: Check Webhook Configuration

```powershell
# Verify webhook URL
# Should be: https://your-domain/webhooks/github

# Check webhook secret
# Ensure secret matches in atlantis.yaml and GitHub
```

#### Solution 2: Test Webhook Manually

```powershell
# Test webhook endpoint
Invoke-WebRequest -Uri "https://your-domain/webhooks/github" -Method POST
```

#### Solution 3: Check SSL Certificate

```powershell
# Verify SSL certificate
Test-NetConnection -ComputerName your-domain -Port 443
```

## 🔧 Compliance Validation Issues

### Issue: Validation Not Triggered

**Symptoms**:

```
No validation errors shown during terraform plan
```

**Solutions**:

#### Solution 1: Check File Inclusion

```powershell
# Verify compliance-validation.tf exists
Test-Path terraform/compliance-validation.tf

# Check if file is included in main configuration
Get-Content terraform/main-aws.tf | Select-String "compliance-validation"
```

#### Solution 2: Test Validation Manually

```powershell
# Introduce a violation for testing
# Edit terraform/test-policy-violations.tf
# Run: terraform plan
# Verify violations are detected
```

#### Solution 3: Check Validation Logic

```hcl
# Review validation blocks
# Ensure conditions are correct
# Check error messages are clear
```

### Issue: False Positive Violations

**Symptoms**:

```
Validation error for compliant resource
```

**Solutions**:

#### Solution 1: Review Variable Values

```powershell
# Check actual variable values
terraform plan -var-file=terraform.tfvars

# Verify values match validation rules
```

#### Solution 2: Debug Validation Logic

```hcl
# Add debug output
output "validation_debug" {
  value = {
    instance_type = var.instance_type
    allowed_types = ["t3.micro", "t3.small", "t3.medium"]
    is_compliant  = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
  }
}
```

#### Solution 3: Update Validation Rules

```hcl
# Modify validation conditions if needed
condition = contains(["t3.micro", "t3.small", "t3.medium", "t3.large"], var.instance_type)
```

## 🔧 Monitoring Issues

### Issue: Health Check Scripts Fail

**Symptoms**:

```
Health monitoring script returns errors
```

**Solutions**:

#### Solution 1: Check AWS Resources

```powershell
# Verify EC2 instances are running
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table

# Check security groups
aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupName,GroupId]' --output table
```

#### Solution 2: Test Individual Components

```powershell
# Test EC2 connectivity
aws ec2 describe-instance-status --include-all-instances

# Test S3 access
aws s3 ls

# Test CloudWatch
aws cloudwatch list-metrics --namespace AWS/EC2
```

#### Solution 3: Update Health Check Scripts

```powershell
# Review and update monitoring scripts
# Ensure they handle errors gracefully
# Add more detailed error reporting
```

### Issue: Cost Monitoring Not Working

**Symptoms**:

```
Cost monitoring script fails or shows no data
```

**Solutions**:

#### Solution 1: Check Cost Explorer Permissions

```powershell
# Verify Cost Explorer access
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

#### Solution 2: Enable Cost Explorer

```powershell
# Enable Cost Explorer if not enabled
# This may take 24 hours for data to appear
```

#### Solution 3: Check Resource Tagging

```powershell
# Verify resources are properly tagged
aws ec2 describe-instances --query 'Reservations[*].Instances[*].Tags' --output table
```

## 🔧 Network Issues

### Issue: Cannot Access Web Servers

**Symptoms**:

```
Web server not responding
```

**Solutions**:

#### Solution 1: Check Security Groups

```powershell
# Verify security group allows HTTP traffic
aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupName,IpPermissions]' --output table

# Check if port 80 is open
aws ec2 describe-security-groups --filters Name=ip-permission.from-port,Values=80
```

#### Solution 2: Check Instance Status

```powershell
# Verify instances are running
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' --output table

# Check instance health
aws ec2 describe-instance-status --include-all-instances
```

#### Solution 3: Test Connectivity

```powershell
# Test HTTP connectivity
$ip = "your-instance-public-ip"
try {
    $response = Invoke-WebRequest -Uri "http://$ip" -UseBasicParsing -TimeoutSec 10
    Write-Host "✅ Web server responding: $($response.StatusCode)"
} catch {
    Write-Host "❌ Web server not responding: $($_.Exception.Message)"
}
```

## 🔧 Performance Issues

### Issue: Slow Terraform Operations

**Symptoms**:

```
Terraform plan/apply takes too long
```

**Solutions**:

#### Solution 1: Optimize Configuration

```hcl
# Use data sources instead of hardcoded values
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

#### Solution 2: Use Parallelism

```powershell
# Increase parallelism
terraform plan -parallelism=10
terraform apply -parallelism=10
```

#### Solution 3: Use Targeted Operations

```powershell
# Target specific resources
terraform plan -target=aws_instance.web
terraform apply -target=aws_instance.web
```

## 📊 Diagnostic Commands

### System Health Check

```powershell
# Complete system health check
Write-Host "=== System Health Check ==="

# Check AWS configuration
Write-Host "AWS Configuration:"
aws sts get-caller-identity
aws configure get region

# Check Terraform
Write-Host "Terraform Version:"
terraform version

# Check PowerShell
Write-Host "PowerShell Version:"
$PSVersionTable.PSVersion

# Check Docker
Write-Host "Docker Status:"
docker --version
docker ps
```

### Infrastructure Status Check

```powershell
# Complete infrastructure status
Write-Host "=== Infrastructure Status ==="

# Check EC2 instances
Write-Host "EC2 Instances:"
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' --output table

# Check S3 buckets
Write-Host "S3 Buckets:"
aws s3 ls

# Check VPC
Write-Host "VPC:"
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,State]' --output table
```

### Compliance Check

```powershell
# Complete compliance check
Write-Host "=== Compliance Check ==="

# Check instance types
Write-Host "Instance Types:"
aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceType' --output table

# Check tags
Write-Host "Resource Tags:"
aws ec2 describe-instances --query 'Reservations[*].Instances[*].Tags' --output table

# Run Terraform validation
Write-Host "Terraform Validation:"
cd terraform
terraform plan
```

## 📞 Getting Help

### Escalation Matrix

1. **Level 1**: Check this troubleshooting guide
2. **Level 2**: Review [FAQ](faq.md) and [Best Practices](best-practices.md)
3. **Level 3**: Create GitHub issue with detailed information
4. **Level 4**: Contact support team

### Information to Include in Issues

When creating issues, include:

-   **Error Message**: Complete error output
-   **Environment**: OS, PowerShell version, Terraform version
-   **Steps to Reproduce**: Detailed steps that led to the issue
-   **Expected vs Actual**: What you expected vs what happened
-   **Logs**: Relevant log files and output

### Contact Information

-   **Documentation Issues**: Create GitHub issue
-   **Technical Support**: cbl.nguyennhatquang2809@gmail.com
-   **Workshop Questions**: Check [FAQ](faq.md)

---

**📚 Related Documentation**

-   [Quick Start Guide](quick-start-guide.md)
-   [Deployment Procedures](deployment-procedures.md)
-   [Compliance Validation](compliance-validation.md)
-   [FAQ](faq.md)
