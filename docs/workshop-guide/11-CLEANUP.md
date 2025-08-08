# Cleanup and Maintenance Guide

## 🎯 Overview

This guide covers safely cleaning up your infrastructure, optimizing costs, and maintaining your Terraform Atlantis Workshop environment. You'll learn best practices for resource management and cost optimization.

## 📋 Prerequisites

Before starting this guide, ensure you have:

-   ✅ **Infrastructure deployed** to AWS (04-AWS-DEPLOYMENT.md)
-   ✅ **Understanding of your resources** and their costs
-   ✅ **Backup of important data** if needed
-   ✅ **Documentation of your setup** for future reference

## 🧹 Infrastructure Cleanup

### **1. Understanding What to Clean Up**

#### **Resources Created by This Workshop**

-   **EC2 Instances**: Web server and policy test instances
-   **VPC Resources**: VPC, subnets, route tables, internet gateway
-   **Security Groups**: Web and policy test security groups
-   **S3 Buckets**: Workshop and encrypted test buckets
-   **IAM Resources**: Roles, policies, and instance profiles
-   **CloudWatch**: Log groups and metrics
-   **Terraform State**: Local state files

#### **Cost Impact of Resources**

```
Resource Type          | Monthly Cost | Notes
----------------------|--------------|------------------
EC2 t3.micro (2x)     | ~$16-20      | Main cost driver
S3 Storage (1GB)      | ~$0.023      | Minimal cost
CloudWatch Logs       | ~$0.50       | Minimal cost
Data Transfer         | ~$0.09/GB    | Usage-based
Total Estimated       | ~$20-30      | Per month
```

### **2. Terraform Destroy Process**

#### **Step-by-Step Cleanup**

```bash
# 1. Navigate to terraform directory
cd terraform

# 2. Verify current state
terraform show

# 3. List all resources
terraform state list

# 4. Create backup of state
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d-%H%M%S)

# 5. Plan destruction
terraform plan -destroy

# 6. Review the plan carefully
# Look for:
# - Resources being destroyed
# - Any dependencies
# - Data that might be lost

# 7. Execute destruction
terraform destroy

# 8. Confirm destruction when prompted
# Type 'yes' to proceed
```

#### **Automated Cleanup Script**

#### **Windows (PowerShell)**

```powershell
# cleanup.ps1 - Automated cleanup script

Write-Host "🚀 Starting infrastructure cleanup..."

# Backup state
Write-Host "📦 Creating state backup..."
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item "terraform.tfstate" "terraform.tfstate.backup.$timestamp"

# Verify AWS credentials
Write-Host "🔐 Verifying AWS credentials..."
aws sts get-caller-identity

# Plan destruction
Write-Host "📋 Planning destruction..."
terraform plan -destroy -out=destroy-plan.tfplan

# Ask for confirmation
$confirm = Read-Host "Do you want to proceed with destruction? (yes/no)"
if ($confirm -eq "yes") {
    Write-Host "🗑️  Executing destruction..."
    terraform apply destroy-plan.tfplan
    Write-Host "✅ Cleanup completed successfully!"
} else {
    Write-Host "❌ Cleanup cancelled by user"
    exit 1
}

# Clean up plan file
Remove-Item "destroy-plan.tfplan" -ErrorAction SilentlyContinue
```

#### **Linux/macOS**

```bash
#!/bin/bash
# cleanup.sh - Automated cleanup script

echo "🚀 Starting infrastructure cleanup..."

# Backup state
echo "📦 Creating state backup..."
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d-%H%M%S)

# Verify AWS credentials
echo "🔐 Verifying AWS credentials..."
aws sts get-caller-identity

# Plan destruction
echo "📋 Planning destruction..."
terraform plan -destroy -out=destroy-plan.tfplan

# Ask for confirmation
read -p "Do you want to proceed with destruction? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    echo "🗑️  Executing destruction..."
    terraform apply destroy-plan.tfplan
    echo "✅ Cleanup completed successfully!"
else
    echo "❌ Cleanup cancelled by user"
    exit 1
fi

# Clean up plan file
rm -f destroy-plan.tfplan
```

### **3. Verification of Cleanup**

#### **Check AWS Resources**

```bash
# Verify EC2 instances are terminated
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=terraform-atlantis-workshop" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name]' \
  --output table

# Verify S3 buckets are deleted
aws s3 ls | Select-String "terraform-atlantis-workshop"

# Verify VPC is deleted
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=terraform-atlantis-workshop" \
  --query 'Vpcs[].[VpcId,State]' \
  --output table

# Verify IAM roles are deleted
aws iam list-roles \
  --query 'Roles[?contains(RoleName, `terraform-atlantis-workshop`)].RoleName' \
  --output table
```

#### **Check Terraform State**

```bash
# Verify state is empty
terraform show

# Expected output: "No state."

# List any remaining resources
terraform state list

# Expected output: (empty)
```

## 💰 Cost Optimization

### **1. Before Cleanup - Cost Analysis**

#### **Analyze Current Costs**

```bash
# Check current month's costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Check EC2 costs specifically
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{"Dimensions": {"Key": "SERVICE", "Values": ["Amazon Elastic Compute Cloud - Compute"]}}'
```

#### **Set Up Cost Monitoring**

```bash
# Create billing alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "MonthlyBillingAlarm" \
  --alarm-description "Alarm when monthly billing exceeds $50" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

### **2. Cost Optimization Strategies**

#### **Right-Sizing Resources**

```hcl
# Example: Use smaller instance types for development
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # Smallest viable instance

  validation {
    condition     = contains(["t3.micro", "t3.small"], var.instance_type)
    error_message = "Only t3.micro and t3.small are allowed for cost control."
  }
}
```

#### **Scheduled Shutdown**

```hcl
# Example: Auto-stop instances during off-hours
resource "aws_instance" "web" {
  # ... other configuration ...

  instance_initiated_shutdown_behavior = "stop"

  # Use AWS Systems Manager for scheduled shutdown
  # or implement Lambda function with EventBridge
}
```

#### **S3 Lifecycle Policies**

```hcl
# Example: Automatically delete old objects
resource "aws_s3_bucket_lifecycle_configuration" "workshop" {
  bucket = aws_s3_bucket.workshop.id

  rule {
    id     = "delete_old_objects"
    status = "Enabled"

    expiration {
      days = 30  # Delete objects older than 30 days
    }
  }
}
```

## 🔄 Maintenance Procedures

### **1. Regular Maintenance Tasks**

#### **Weekly Tasks**

```bash
# Check resource health
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=terraform-atlantis-workshop" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType]' \
  --output table

# Check CloudWatch logs
aws logs describe-log-streams \
  --log-group-name "/aws/ec2/terraform-atlantis-workshop" \
  --order-by LastEventTime \
  --descending \
  --max-items 5

# Check S3 bucket usage
aws s3 ls --recursive --summarize s3://terraform-atlantis-workshop-workshop-bucket
```

#### **Monthly Tasks**

```bash
# Review costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Update Terraform providers
terraform init -upgrade

# Review security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*terraform-atlantis-workshop*" \
  --query 'SecurityGroups[].[GroupName,Description]' \
  --output table
```

### **2. Backup Strategies**

#### **Terraform State Backup**

```bash
# Create regular state backups
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d)

# Or use remote state storage
terraform {
  backend "s3" {
    bucket = "terraform-atlantis-workshop-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
```

#### **Configuration Backup**

```bash
# Backup Terraform configuration
tar -czf terraform-config-$(date +%Y%m%d).tar.gz \
  terraform/*.tf \
  terraform/*.tfvars \
  atlantis/ \
  policies/
```

### **3. Security Maintenance**

#### **Regular Security Checks**

```bash
# Check for security group changes
aws ec2 describe-security-group-rules \
  --filters "Name=group-name,Values=*terraform-atlantis-workshop*" \
  --query 'SecurityGroupRules[].[GroupId,IsEgress,FromPort,ToPort,CidrIpv4]' \
  --output table

# Verify S3 bucket encryption
aws s3api get-bucket-encryption \
  --bucket terraform-atlantis-workshop-workshop-bucket

# Check IAM role permissions
aws iam get-role-policy \
  --role-name terraform-atlantis-workshop-ec2-role \
  --policy-name terraform-atlantis-workshop-cloudwatch-logs
```

## 🚨 Emergency Procedures

### **1. Emergency Cleanup**

#### **Force Delete Resources**

```bash
# If Terraform destroy fails, manually delete resources
# WARNING: This bypasses Terraform state management

# Delete EC2 instances
aws ec2 terminate-instances \
  --instance-ids $(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=terraform-atlantis-workshop" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)

# Delete S3 buckets (must be empty first)
aws s3 rm s3://terraform-atlantis-workshop-workshop-bucket --recursive
aws s3 rb s3://terraform-atlantis-workshop-workshop-bucket

# Delete VPC (will delete dependent resources)
aws ec2 delete-vpc \
  --vpc-id $(aws ec2 describe-vpcs \
    --filters "Name=tag:Project,Values=terraform-atlantis-workshop" \
    --query 'Vpcs[0].VpcId' \
    --output text)
```

### **2. State Recovery**

#### **Recover from Backup**

```bash
# Restore state from backup
cp terraform.tfstate.backup.20240101 terraform.tfstate

# Refresh state
terraform refresh

# Verify state
terraform show
```

#### **Import Existing Resources**

```bash
# If resources exist but aren't in state
terraform import aws_instance.web i-1234567890abcdef0
terraform import aws_vpc.main vpc-1234567890abcdef0
```

## 📋 Cleanup Checklist

Before considering cleanup complete, verify:

-   [ ] **All EC2 instances terminated**
-   [ ] **All S3 buckets deleted**
-   [ ] **VPC and networking resources removed**
-   [ ] **IAM roles and policies deleted**
-   [ ] **CloudWatch resources cleaned up**
-   [ ] **Terraform state cleared**
-   [ ] **Local files cleaned up**
-   [ ] **Cost monitoring disabled**
-   [ ] **Documentation updated**

## 🎯 Best Practices

### **1. Before Cleanup**

-   **Document your setup** for future reference
-   **Backup important data** from S3 buckets
-   **Review costs** to understand what you're removing
-   **Test cleanup** on a copy if possible

### **2. During Cleanup**

-   **Use Terraform destroy** when possible
-   **Review the plan** carefully before executing
-   **Monitor the process** for any errors
-   **Keep backups** of state and configuration

### **3. After Cleanup**

-   **Verify all resources are gone**
-   **Check for any orphaned resources**
-   **Monitor billing** to ensure costs stop
-   **Update documentation** with lessons learned

## 🚨 Troubleshooting

### **1. Common Cleanup Issues**

#### **Resources Won't Delete**

```bash
# Check for dependencies
terraform graph

# Force delete with -auto-approve
terraform destroy -auto-approve

# Check AWS console for manual cleanup
```

#### **State File Issues**

```bash
# If state is corrupted
terraform init -reconfigure

# Or start fresh
rm -rf .terraform terraform.tfstate*
terraform init
```

#### **Permission Issues**

```bash
# Verify AWS permissions
aws sts get-caller-identity

# Check IAM policies
aws iam get-user
aws iam list-attached-user-policies --user-name your-username
```

### **2. Debugging Commands**

```bash
# Check what resources exist
terraform state list

# Check specific resource
terraform state show aws_instance.web

# Check AWS resources directly
aws ec2 describe-instances --filters "Name=tag:Project,Values=terraform-atlantis-workshop"

# Check for orphaned resources
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=terraform-atlantis-workshop
```

## 📞 Support

If you encounter cleanup issues:

1. **Check the troubleshooting guide** (09-TROUBLESHOOTING.md)
2. **Review AWS console** for manual cleanup options
3. **Contact AWS support** for billing issues
4. **Check Terraform documentation** for state management
5. **Use AWS CLI** for manual resource management

---

**Cleanup completed?** Congratulations on completing the Terraform Atlantis Workshop! 🎉

## 🏆 Workshop Completion

You have successfully:

-   ✅ **Deployed infrastructure** to AWS
-   ✅ **Implemented compliance policies**
-   ✅ **Set up GitOps workflows**
-   ✅ **Tested policy violations**
-   ✅ **Cleaned up resources**

### **Next Steps**

1. **Practice with different scenarios**
2. **Explore advanced Terraform features**
3. **Implement in your own projects**
4. **Share knowledge with your team**
5. **Stay updated with latest practices**

### **Resources for Continued Learning**

-   [Terraform Documentation](https://www.terraform.io/docs)
-   [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
-   [GitOps Best Practices](https://www.gitops.tech/)
-   [Atlantis Documentation](https://www.runatlantis.io/docs/)

**Happy Infrastructure as Code! 🚀**
