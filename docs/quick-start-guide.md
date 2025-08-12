# Quick Start Guide - Terraform Atlantis Workshop

## 🚀 Get Up and Running in 15 Minutes

This guide will help you quickly set up and deploy the **Environment Provisioning Automation with Terraform and Atlantis** workshop infrastructure.

## 📋 Prerequisites Check

Before starting, ensure you have:

-   ✅ **AWS Account** with appropriate permissions
-   ✅ **PowerShell** (Windows) or equivalent shell
-   ✅ **Git** for version control
-   ✅ **AWS CLI** installed and configured
-   ✅ **Docker** (optional, for Atlantis)

## ⚡ Quick Setup (15 Minutes)

### Step 1: Clone and Navigate (2 minutes)

```powershell
# Clone the repository
git clone <repository-url>
cd terraform-atlantis-workshop

# Verify the structure
ls
```

### Step 2: Configure AWS (3 minutes)

```powershell
# Configure AWS credentials
aws configure

# Verify configuration
aws sts get-caller-identity
aws configure get region
```

### Step 3: Deploy Infrastructure (5 minutes)

```powershell
# Run the complete automated workflow
.\scripts\00-setup-env.ps1

# Or run individual steps
.\scripts\01-validate-environment.ps1
.\scripts\03-deploy-infrastructure.ps1
```

### Step 4: Verify Deployment (3 minutes)

```powershell
# Check infrastructure health
.\scripts\04-health-monitoring.ps1

# View outputs
cd terraform
terraform output
```

### Step 5: Test Compliance Validation (2 minutes)

```powershell
# Test compliance validation
cd terraform
terraform plan

# Check for any violations
# You should see validation results in the output
# Note: Active test resources are included for demonstration
```

**Test Resources**: The workshop includes active test resources in `main-aws.tf` that demonstrate compliance validation. These resources are designed to show how violations are detected and prevented.

## 🎯 What You'll Have After 15 Minutes

### ✅ Production Infrastructure

-   **AWS VPC** with public and private subnets
-   **EC2 Instances** running Apache web servers
-   **S3 Buckets** with encryption and versioning
-   **Security Groups** with proper access controls
-   **CloudWatch Logging** for monitoring

### ✅ Compliance Validation

-   **Instance Type Restrictions** (t3.micro, t3.small, t3.medium only)
-   **Required Tags** (Environment, Project, CostCenter)
-   **S3 Naming Convention** (terraform-atlantis-workshop-\*)
-   **Real-time Validation** during terraform plan

### ✅ Operational Tools

-   **Health Monitoring** scripts
-   **Cost Monitoring** setup
-   **Rollback Procedures** ready
-   **Cleanup Scripts** available

## 🔍 Quick Verification

### Check Infrastructure Status

```powershell
# Check EC2 instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' --output table

# Check S3 buckets
aws s3 ls

# Check VPC
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,State]' --output table
```

### Test Web Servers

```powershell
# Get public IP addresses
terraform output -json | ConvertFrom-Json

# Test web server access (replace with actual IP)
Invoke-WebRequest -Uri "http://<public-ip>" -UseBasicParsing
```

### Verify Compliance

```powershell
# Run compliance check
terraform plan

# Expected output: No violations detected
# If violations exist, they will be clearly shown
```

## 🚨 Common Quick Issues

### Issue: AWS Credentials Not Configured

```powershell
# Solution: Configure AWS
aws configure
```

### Issue: PowerShell Execution Policy

```powershell
# Solution: Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: Terraform Not Found

```powershell
# Solution: Install Terraform
# Download from https://www.terraform.io/downloads.html
# Add to PATH
```

### Issue: Insufficient AWS Permissions

```powershell
# Solution: Check IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name <your-username>
```

## 📊 Quick Cost Estimation

### Expected Monthly Costs (ap-southeast-1)

-   **EC2 Instances**: ~$15-20/month (t3.micro)
-   **S3 Storage**: ~$2-5/month (minimal usage)
-   **Data Transfer**: ~$1-3/month
-   **CloudWatch**: ~$1-2/month
-   **Total Estimated**: **$20-30/month**

### Cost Optimization Tips

-   Use t3.micro instances for development
-   Enable S3 lifecycle policies
-   Monitor CloudWatch usage
-   Clean up unused resources

## 🔄 Next Steps After Quick Start

### 1. Explore Atlantis GitOps (Optional)

```powershell
# Set up GitHub integration
.\scripts\02-setup-github-actions.ps1

# Start Atlantis (if using Docker)
docker-compose up -d
```

### 2. Test Compliance Violations

```powershell
# Introduce a violation for testing
# Edit terraform/test-policy-violations.tf
# Run: terraform plan
# See violation detection in action
```

### 3. Set Up Monitoring

```powershell
# Configure monitoring
.\scripts\04-health-monitoring.ps1
.\scripts\05-cost-monitoring.ps1
```

### 4. Review Documentation

-   Read [Architecture Overview](architecture-overview.md)
-   Review [Best Practices](best-practices.md)
-   Check [Troubleshooting Guide](troubleshooting-guide.md)

## 🧹 Quick Cleanup

When you're done testing:

```powershell
# Destroy infrastructure
.\scripts\07-cleanup-infrastructure.ps1

# Or manually
cd terraform
.\destroy.ps1
```

## 📞 Need Help?

### Quick Support

-   **Documentation**: Check [Troubleshooting Guide](troubleshooting-guide.md)
-   **FAQ**: Review [FAQ](faq.md)
-   **Issues**: Create GitHub issue
-   **Contact**: cbl.nguyennhatquang2809@gmail.com

### Useful Commands

```powershell
# Check workshop status
.\scripts\01-validate-environment.ps1

# View all outputs
terraform output

# Check AWS resources
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table

# Monitor costs
.\scripts\05-cost-monitoring.ps1
```

---

**⏱️ Time to Complete**: 15 minutes  
**🎯 Success Criteria**: Infrastructure deployed, compliance validation working  
**📚 Next**: Read [Architecture Overview](architecture-overview.md) for deeper understanding
