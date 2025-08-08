# Troubleshooting Guide

## 🎯 Overview

This guide provides solutions for common issues you may encounter during the Terraform Atlantis Workshop. You'll learn how to diagnose problems, apply fixes, and prevent future issues.

## 📋 Prerequisites

Before using this guide, ensure you have:

-   ✅ **Basic understanding** of the workshop components
-   ✅ **Access to AWS console** and CLI
-   ✅ **Terraform installed** and configured
-   ✅ **Git repository** set up

## 🚨 Common Issues by Category

### **1. AWS Credentials and Permissions**

#### **Issue: AWS CLI Not Working**

```bash
# Error: Unable to locate credentials
aws sts get-caller-identity
# Output: Unable to locate credentials
```

**Solution:**

```bash
# Configure AWS credentials
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Verify configuration
aws sts get-caller-identity
```

#### **Issue: Insufficient Permissions**

```bash
# Error: Access Denied when creating resources
terraform apply
# Error: AccessDenied: User is not authorized to perform: ec2:RunInstances
```

**Solution:**

```bash
# Check current permissions
aws iam get-user
aws iam list-attached-user-policies --user-name your-username

# Required policies:
# - AmazonEC2FullAccess
# - AmazonS3FullAccess
# - IAMFullAccess
# - CloudWatchFullAccess
# - AmazonVPCFullAccess
```

### **2. Terraform Issues**

#### **Issue: Terraform Not Found**

```bash
# Error: terraform: command not found
terraform --version
```

**Solution:**

```bash
# Windows (PowerShell)
winget install HashiCorp.Terraform

# macOS
brew install terraform

# Linux
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

#### **Issue: Provider Not Found**

```bash
# Error: Failed to query available provider packages
terraform init
# Error: Could not find a version of provider "hashicorp/aws" that satisfies the constraint "~> 5.0"
```

**Solution:**

```bash
# Update provider versions
terraform init -upgrade

# Or specify provider version in main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

#### **Issue: State File Issues**

```bash
# Error: Error refreshing state: AccessDenied
terraform plan
# Error: Failed to get existing workspaces: AccessDenied
```

**Solution:**

```bash
# Check state file
ls -la terraform.tfstate*

# Backup and recreate state if corrupted
cp terraform.tfstate terraform.tfstate.backup
rm terraform.tfstate
terraform init

# Or use remote state
terraform {
  backend "s3" {
    bucket = "terraform-atlantis-workshop-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
```

### **3. Infrastructure Deployment Issues**

#### **Issue: Instance Not Starting**

```bash
# Error: Error launching source instance: InvalidAMIID.NotFound
terraform apply
# Error: The image id 'ami-0abcdef1234567890' does not exist
```

**Solution:**

```bash
# Use data source to get latest AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Update main.tf to use data source
resource "aws_instance" "web" {
  ami = data.aws_ami.amazon_linux.id
  # ... rest of configuration
}
```

#### **Issue: Security Group Rules**

```bash
# Error: Error creating security group: InvalidGroup.Duplicate
terraform apply
# Error: The security group 'terraform-atlantis-workshop-web-sg' already exists
```

**Solution:**

```bash
# Check existing security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*terraform-atlantis-workshop*"

# Delete conflicting resources
aws ec2 delete-security-group --group-id sg-1234567890abcdef0

# Or use terraform import
terraform import aws_security_group.web sg-1234567890abcdef0
```

#### **Issue: S3 Bucket Name Conflict**

```bash
# Error: Error creating S3 bucket: BucketAlreadyExists
terraform apply
# Error: The requested bucket name is not available
```

**Solution:**

```bash
# Use unique bucket names
resource "aws_s3_bucket" "workshop" {
  bucket = "${var.project_name}-workshop-bucket-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
```

### **4. Compliance Policy Issues**

#### **Issue: Policy Violations Not Detected**

```bash
# Expected violation not caught
terraform plan
# No error message for expensive instance type
```

**Solution:**

```bash
# Check compliance validation configuration
cat terraform/compliance-validation.tf

# Verify policy rules are active
terraform output compliance_validation_status

# Test with explicit violation
terraform plan -var="instance_type=m5.large"
```

#### **Issue: False Positive Violations**

```bash
# Error: VIOLATION: Found expensive instance types
terraform plan
# But using t3.micro which should be allowed
```

**Solution:**

```bash
# Check allowed instance types list
terraform console
> local.allowed_instance_types

# Update allowed types if needed
locals {
  allowed_instance_types = ["t3.micro", "t3.small", "t3.medium", "t3.large"]
}
```

### **5. Atlantis GitOps Issues**

#### **Issue: Atlantis Not Responding**

```bash
# No response to PR comments
# atlantis plan command not working
```

**Solution:**

```bash
# Check Atlantis is running
docker ps | grep atlantis

# Check Atlantis logs
docker logs atlantis

# Verify webhook configuration
gh api repos/yourusername/terraform-atlantis-workshop/hooks \
  --method GET \
  --jq '.[0] | {url: .config.url, active: .active}'
```

#### **Issue: Webhook Not Delivering**

```bash
# Webhook deliveries failing
# 404 or 500 errors in webhook logs
```

**Solution:**

```bash
# Check webhook URL is accessible
curl -I http://your-atlantis-url:4141/health

# Verify webhook secret
gh api repos/yourusername/terraform-atlantis-workshop/hooks \
  --method GET \
  --jq '.[0].config.secret'

# Recreate webhook if needed
gh api repos/yourusername/terraform-atlantis-workshop/hooks/123 \
  --method DELETE

gh api repos/yourusername/terraform-atlantis-workshop/hooks \
  --method POST \
  --field name=web \
  --field active=true \
  --field events='["pull_request", "push"]' \
  --field config.url="http://your-atlantis-url:4141/events" \
  --field config.content_type=application/json \
  --field config.secret="$WEBHOOK_SECRET"
```

### **6. Monitoring Issues**

#### **Issue: CloudWatch Metrics Not Appearing**

```bash
# No metrics in CloudWatch console
# Alarms not triggering
```

**Solution:**

```bash
# Check if CloudWatch agent is running on instance
aws ssm send-command \
  --instance-ids $(terraform output -raw instance_id) \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["systemctl status amazon-cloudwatch-agent"]'

# Install CloudWatch agent if needed
aws ssm send-command \
  --instance-ids $(terraform output -raw instance_id) \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["yum install -y amazon-cloudwatch-agent"]'
```

#### **Issue: Logs Not Appearing**

```bash
# No logs in CloudWatch Logs
# Application logs not being sent
```

**Solution:**

```bash
# Check log group exists
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/ec2/terraform-atlantis-workshop"

# Check instance IAM role
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'

# Verify IAM policy allows CloudWatch Logs
aws iam get-role-policy \
  --role-name terraform-atlantis-workshop-ec2-role \
  --policy-name terraform-atlantis-workshop-cloudwatch-logs
```

## 🔧 Diagnostic Commands

### **1. Infrastructure Diagnostics**

```bash
# Check all resources
terraform state list

# Check specific resource
terraform state show aws_instance.web

# Check AWS resources directly
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=terraform-atlantis-workshop"

# Check VPC resources
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=terraform-atlantis-workshop"

# Check S3 buckets
aws s3 ls | grep terraform-atlantis-workshop
```

### **2. Network Diagnostics**

```bash
# Check security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*terraform-atlantis-workshop*"

# Check route tables
aws ec2 describe-route-tables \
  --filters "Name=tag:Project,Values=terraform-atlantis-workshop"

# Test connectivity
telnet $(terraform output -raw instance_public_ip) 80
telnet $(terraform output -raw instance_public_ip) 443
```

### **3. Application Diagnostics**

```bash
# Test web server
curl -I $(terraform output -raw website_url)

# Check instance logs
aws ec2 get-console-output \
  --instance-id $(terraform output -raw instance_id)

# Test S3 access
aws s3 ls s3://$(terraform output -raw s3_bucket_id)
```

## 🛠️ Recovery Procedures

### **1. Infrastructure Recovery**

#### **Recover from State Loss**

```bash
# If state file is lost but resources exist
terraform import aws_vpc.main vpc-1234567890abcdef0
terraform import aws_subnet.public subnet-1234567890abcdef0
terraform import aws_instance.web i-1234567890abcdef0
terraform import aws_s3_bucket.workshop terraform-atlantis-workshop-workshop-bucket
```

#### **Recover from Partial Failure**

```bash
# If some resources failed to create
terraform plan
# Review what needs to be created

terraform apply -target=aws_vpc.main
terraform apply -target=aws_subnet.public
terraform apply -target=aws_instance.web
```

### **2. Data Recovery**

#### **Recover S3 Data**

```bash
# If S3 bucket was accidentally deleted
# Check for versioned objects
aws s3api list-object-versions \
  --bucket terraform-atlantis-workshop-workshop-bucket

# Restore from version if available
aws s3api get-object \
  --bucket terraform-atlantis-workshop-workshop-bucket \
  --key important-file \
  --version-id version-id \
  restored-file
```

### **3. Configuration Recovery**

#### **Recover from Configuration Errors**

```bash
# Revert to working configuration
git log --oneline
git checkout <commit-hash>

# Or restore from backup
cp terraform.tfvars.backup terraform.tfvars
cp main.tf.backup main.tf
```

## 📋 Troubleshooting Checklist

When encountering issues, follow this checklist:

-   [ ] **Check AWS credentials** and permissions
-   [ ] **Verify Terraform version** and configuration
-   [ ] **Check resource dependencies** and ordering
-   [ ] **Review error messages** carefully
-   [ ] **Check AWS service status** for outages
-   [ ] **Verify network connectivity** and security groups
-   [ ] **Check CloudWatch logs** for application errors
-   [ ] **Review compliance policies** for violations
-   [ ] **Test GitOps workflow** step by step
-   [ ] **Document the issue** and solution

## 🎯 Prevention Strategies

### **1. Proactive Monitoring**

```bash
# Set up regular health checks
crontab -e
# Add: */5 * * * * /path/to/health-check.sh

# Monitor costs daily
# Add: 0 9 * * * /path/to/cost-monitor.sh
```

### **2. Backup Strategies**

```bash
# Regular state backups
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d)

# Configuration backups
tar -czf terraform-config-$(date +%Y%m%d).tar.gz terraform/*.tf

# Use remote state for team environments
terraform {
  backend "s3" {
    bucket = "terraform-atlantis-workshop-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
```

### **3. Testing Procedures**

```bash
# Test changes in development first
terraform plan -var-file="terraform.tfvars.development"

# Use feature branches for changes
git checkout -b feature/new-resource

# Test compliance policies
terraform plan
# Verify no violations

# Test GitOps workflow
# Create PR and verify Atlantis plan
```

## 📞 Getting Help

### **1. Self-Service Resources**

-   **AWS Documentation**: https://docs.aws.amazon.com/
-   **Terraform Documentation**: https://www.terraform.io/docs
-   **Atlantis Documentation**: https://www.runatlantis.io/docs/
-   **CloudWatch Documentation**: https://docs.aws.amazon.com/cloudwatch/

### **2. Community Support**

-   **Terraform Community**: https://discuss.hashicorp.com/c/terraform-core
-   **AWS Community**: https://aws.amazon.com/developer/community/
-   **Stack Overflow**: Search for specific error messages
-   **GitHub Issues**: Check existing issues in repositories

### **3. Professional Support**

-   **AWS Support**: For AWS-specific issues
-   **HashiCorp Support**: For Terraform issues
-   **Consulting Services**: For complex infrastructure problems

## 🚨 Emergency Procedures

### **1. Critical Issues**

#### **Security Breach**

```bash
# Immediately terminate affected instances
aws ec2 terminate-instances \
  --instance-ids $(terraform output -raw instance_id)

# Revoke compromised credentials
# Contact AWS support immediately
```

#### **Cost Explosion**

```bash
# Stop all non-critical resources
terraform destroy -target=aws_instance.web

# Set up billing alerts
aws cloudwatch put-metric-alarm \
  --alarm-name "EmergencyBillingAlarm" \
  --alarm-description "Emergency alarm for cost control" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 3600 \
  --threshold 100 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

### **2. Service Outages**

#### **AWS Service Outage**

```bash
# Check AWS service status
aws health describe-events \
  --filter eventTypeCategory=issue

# Monitor for updates
# Consider failover to different region if available
```

---

**Need more help?** Check the specific documentation for each component or reach out to the community!
