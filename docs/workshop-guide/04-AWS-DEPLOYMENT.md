# AWS Production Deployment Guide

## 🚀 Overview

This guide covers deploying your Terraform infrastructure to real AWS production environment. You'll learn how to safely deploy infrastructure, validate configurations, and monitor costs.

## 📋 Prerequisites

Before starting this guide, ensure you have:

-   ✅ **AWS Account** with appropriate permissions
-   ✅ **AWS CLI** configured with valid credentials
-   ✅ **Terraform** installed and working
-   ✅ **Completed local development** (03-LOCALSTACK.md)
-   ✅ **Understanding of infrastructure** (02-INFRASTRUCTURE.md)

## 🔐 AWS Credentials Setup

### **1. Verify AWS Credentials**

```bash
# Test your AWS credentials
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDAX...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-username"
# }
```

### **2. Check AWS Region**

```bash
# Verify your default region
aws configure get region

# If you need to change region
aws configure set region us-east-1
```

### **3. Verify Permissions**

```bash
# Test EC2 permissions
aws ec2 describe-regions

# Test S3 permissions
aws s3 ls

# Test IAM permissions
aws iam get-user
```

## 🏗️ Infrastructure Deployment

### **1. Prepare for Production**

```bash
# Navigate to terraform directory
cd terraform

# Verify you're using AWS configuration
ls -la main.tf
```

### **2. Configure Variables for Production**

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars for production
```

**Example `terraform.tfvars`:**

```hcl
# AWS Configuration
region = "us-east-1"
environment = "production"
project_name = "terraform-atlantis-workshop"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

# EC2 Configuration
instance_type = "t3.micro"
# key_pair_name = "your-key-pair-name"  # Optional
```

### **3. Initialize Terraform**

```bash
# Initialize Terraform for AWS
terraform init

# Verify providers
terraform providers
```

### **4. Validate Configuration**

```bash
# Validate Terraform configuration
terraform validate

# Check for any syntax errors or issues
```

### **5. Plan Deployment**

```bash
# Create deployment plan
terraform plan

# Review the plan carefully
# Look for:
# - Resources being created
# - Estimated costs
# - Security configurations
# - Compliance status
```

### **6. Deploy Infrastructure**

```bash
# Deploy to AWS (with confirmation)
terraform apply

# Or deploy automatically (use with caution)
terraform apply -auto-approve
```

## 📊 Deployment Verification

### **1. Check Terraform State**

```bash
# Verify deployment status
terraform show

# Check outputs
terraform output
```

### **2. Verify AWS Resources**

```bash
# Check EC2 instances
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Check S3 buckets
aws s3 ls

# Check VPC
aws ec2 describe-vpcs \
  --query 'Vpcs[].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

### **3. Test Web Application**

#### **Windows (PowerShell)**

```powershell
# Get web server URL
$websiteUrl = terraform output -raw website_url

# Test web server
Invoke-WebRequest -Uri $websiteUrl -UseBasicParsing

# Expected output:
# <h1>Hello from terraform-atlantis-workshop on AWS!</h1>
# <p>This instance was created with Terraform on AWS Production.</p>
```

#### **Linux/macOS**

```bash
# Get web server URL
terraform output website_url

# Test web server
curl $(terraform output -raw website_url)

# Expected output:
# <h1>Hello from terraform-atlantis-workshop on AWS!</h1>
# <p>This instance was created with Terraform on AWS Production.</p>
```

## 💰 Cost Monitoring

### **1. Estimate Costs**

```bash
# Review estimated costs from terraform plan
# Typical costs for this infrastructure:
# - EC2 t3.micro: ~$8-10/month per instance
# - S3 storage: ~$0.023/GB/month
# - CloudWatch logs: ~$0.50/month
# - Data transfer: ~$0.09/GB
```

### **2. Set Up Billing Alerts**

1. Go to AWS Billing Console
2. Set up billing alerts
3. Monitor costs regularly
4. Use AWS Cost Explorer for detailed analysis

### **3. Cost Optimization Tips**

-   **Use Spot Instances** for non-critical workloads
-   **Right-size instances** based on actual usage
-   **Enable S3 lifecycle policies** for old data
-   **Monitor and terminate unused resources**

## 🔒 Security Best Practices

### **1. Network Security**

```bash
# Verify security groups
aws ec2 describe-security-groups \
  --query 'SecurityGroups[].[GroupName,Description]' \
  --output table

# Check VPC configuration
aws ec2 describe-vpcs \
  --query 'Vpcs[].[VpcId,EnableDnsHostnames,EnableDnsSupport]' \
  --output table
```

### **2. Access Control**

-   **Use IAM roles** instead of access keys on instances
-   **Enable CloudTrail** for audit logging
-   **Use VPC endpoints** for AWS service access
-   **Implement least privilege** access

### **3. Data Protection**

-   **Enable S3 encryption** (already configured)
-   **Use HTTPS** for all web traffic
-   **Implement backup strategies**
-   **Enable versioning** on S3 buckets

## 📈 Monitoring Setup

### **1. CloudWatch Configuration**

```bash
# Check CloudWatch log groups
aws logs describe-log-groups \
  --query 'logGroups[].[logGroupName,retentionInDays]' \
  --output table

# Check CloudWatch metrics
aws cloudwatch list-metrics --namespace AWS/EC2
```

### **2. Set Up Alarms**

```bash
# Create CPU utilization alarm
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

### **3. Log Monitoring**

```bash
# Check application logs
aws logs describe-log-streams \
  --log-group-name "/aws/ec2/terraform-atlantis-workshop" \
  --order-by LastEventTime \
  --descending
```

## 🧪 Testing in Production

### **1. Functional Testing**

#### **Windows (PowerShell)**

```powershell
# Test web server functionality
$websiteUrl = terraform output -raw website_url
try {
    $response = Invoke-WebRequest -Uri $websiteUrl -UseBasicParsing
    Write-Host "HTTP Status: $($response.StatusCode)"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}

# Test S3 bucket access
$bucketId = terraform output -raw s3_bucket_id
aws s3 ls $bucketId

# Test security group rules
aws ec2 describe-security-group-rules `
  --filters Name=group-name,Values=terraform-atlantis-workshop-web-sg
```

#### **Linux/macOS**

```bash
# Test web server functionality
curl -I $(terraform output -raw website_url)

# Test S3 bucket access
aws s3 ls $(terraform output -raw s3_bucket_id)

# Test security group rules
aws ec2 describe-security-group-rules \
  --filters Name=group-name,Values=terraform-atlantis-workshop-web-sg
```

### **2. Performance Testing**

#### **Windows (PowerShell)**

```powershell
# Test web server response time
$websiteUrl = terraform output -raw website_url
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
    Invoke-WebRequest -Uri $websiteUrl -UseBasicParsing | Out-Null
    $stopwatch.Stop()
    Write-Host "Response time: $($stopwatch.ElapsedMilliseconds)ms"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}

# Monitor instance metrics
$instanceId = terraform output -raw instance_id
$startTime = (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ss")
$endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")

aws cloudwatch get-metric-statistics `
  --namespace AWS/EC2 `
  --metric-name CPUUtilization `
  --dimensions Name=InstanceId,Value=$instanceId `
  --start-time $startTime `
  --end-time $endTime `
  --period 300 `
  --statistics Average
```

#### **Linux/macOS**

```bash
# Test web server response time
time curl -s $(terraform output -raw website_url) > /dev/null

# Monitor instance metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### **3. Security Testing**

```bash
# Test security group restrictions
# Try to access restricted ports
telnet $(terraform output -raw instance_public_ip) 22

# Verify S3 bucket encryption
aws s3api get-bucket-encryption \
  --bucket $(terraform output -raw s3_bucket_id)
```

## 🔄 Infrastructure Updates

### **1. Making Changes**

```bash
# Edit Terraform files
# Example: Change instance type
# In terraform.tfvars: instance_type = "t3.small"

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### **2. Scaling Infrastructure**

```bash
# To add more instances, modify main.tf
# To change instance types, modify terraform.tfvars
# To add new resources, add to main.tf
```

### **3. Backup and Recovery**

```bash
# Backup Terraform state
cp terraform.tfstate terraform.tfstate.backup

# Backup configuration
tar -czf terraform-config-backup.tar.gz *.tf *.tfvars
```

## 🚨 Troubleshooting

### **1. Common Issues**

#### **Instance Not Starting**

```bash
# Check instance status
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id)

# Check system logs
aws ec2 get-console-output \
  --instance-id $(terraform output -raw instance_id)
```

#### **Security Group Issues**

```bash
# Verify security group rules
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw security_group_id)
```

#### **S3 Access Issues**

```bash
# Check bucket permissions
aws s3api get-bucket-policy \
  --bucket $(terraform output -raw s3_bucket_id)
```

### **2. Debugging Commands**

```bash
# Check Terraform state
terraform state list
terraform state show aws_instance.web

# Check AWS resources directly
aws ec2 describe-instances --filters "Name=tag:Project,Values=terraform-atlantis-workshop"

# Check CloudWatch logs
aws logs filter-log-events \
  --log-group-name "/aws/ec2/terraform-atlantis-workshop" \
  --start-time $(date -u -d '1 hour ago' +%s)000
```

## 📋 Deployment Checklist

Before considering deployment complete, verify:

-   [ ] **All resources created** successfully
-   [ ] **Web application accessible** and responding
-   [ ] **Security groups configured** correctly
-   [ ] **S3 buckets encrypted** and secure
-   [ ] **CloudWatch monitoring** active
-   [ ] **Cost monitoring** set up
-   [ ] **Backup strategy** implemented
-   [ ] **Documentation updated** with production details

## 🎯 Next Steps

After successful deployment:

1. **Test compliance policies** (05-COMPLIANCE.md)
2. **Set up GitOps with Atlantis** (06-ATLANTIS.md)
3. **Implement monitoring** (08-MONITORING.md)
4. **Plan for scaling** (10-ADVANCED.md)
5. **Set up cleanup procedures** (11-CLEANUP.md)

## 📞 Support

If you encounter issues:

1. **Check the troubleshooting guide** (09-TROUBLESHOOTING.md)
2. **Verify AWS permissions** and credentials
3. **Review Terraform plan** output carefully
4. **Check AWS service limits** and quotas
5. **Monitor CloudWatch logs** for errors

---

**Deployment successful?** Continue to [05-COMPLIANCE.md](05-COMPLIANCE.md) to test compliance policies!
