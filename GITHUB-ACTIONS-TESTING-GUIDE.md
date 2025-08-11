# GitHub Actions Testing Guide

## 🚀 **Testing GitHub Actions Workflow**

This guide will help you test the GitHub Actions workflow for the Terraform Atlantis Workshop.

---

## 📋 **Prerequisites**

### **1. GitHub Repository Setup**
- ✅ Repository exists on GitHub
- ✅ Local repository is connected to GitHub
- ✅ GitHub Actions workflow file exists (`.github/workflows/terraform.yml`)

### **2. AWS Credentials**
- ✅ AWS Access Key ID
- ✅ AWS Secret Access Key
- ✅ AWS Region configured

### **3. GitHub Secrets**
You need to configure these secrets in your GitHub repository:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Add these secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_DEFAULT_REGION` | Your AWS Region | `ap-southeast-1` |

---

## 🧪 **Testing Steps**

### **Step 1: Verify Current Setup**

First, let's verify your current setup:

```powershell
# Check if you're in the right directory
pwd

# Check if workflow file exists
ls .github/workflows/terraform.yml

# Check current git status
git status

# Check current branch
git branch
```

### **Step 2: Create a Test Branch**

```powershell
# Create a new branch for testing
git checkout -b test-github-actions

# Verify you're on the new branch
git branch
```

### **Step 3: Make a Test Change**

Let's make a small, safe change to trigger the workflow:

```powershell
# Add a comment to terraform.tfvars
echo "# Testing GitHub Actions - $(Get-Date)" >> terraform/terraform.tfvars

# Check the change
git diff
```

### **Step 4: Commit and Push**

```powershell
# Add the changes
git add terraform/terraform.tfvars

# Commit with a descriptive message
git commit -m "test: trigger github actions workflow"

# Push to GitHub
git push origin test-github-actions
```

### **Step 5: Create a Pull Request**

1. Go to your GitHub repository
2. You should see a notification about the recently pushed branch
3. Click **"Compare & pull request"**
4. Fill in the PR details:
   - **Title**: `Test: GitHub Actions Workflow`
   - **Description**: 
     ```
     Testing GitHub Actions workflow for Terraform deployment
     
     Changes:
     - Added test comment to terraform.tfvars
     
     Expected:
     - Terraform plan should run automatically
     - Plan should show no changes (since we only added a comment)
     - Health check should pass
     ```
5. Click **"Create pull request"**

---

## 🔍 **Monitoring the Workflow**

### **1. Watch the Workflow Run**

Once you create the PR, GitHub Actions will automatically trigger:

1. Go to the **Actions** tab in your GitHub repository
2. You should see a new workflow run: **"Terraform AWS Workshop"**
3. Click on it to see the details

### **2. Expected Workflow Steps**

The workflow should run these jobs in sequence:

1. **terraform-plan** (on PR)
   - ✅ Checkout code
   - ✅ Setup Terraform
   - ✅ Configure AWS credentials
   - ✅ Terraform init
   - ✅ Terraform format check
   - ✅ Terraform validate
   - ✅ Terraform plan
   - ✅ Upload plan artifact
   - ✅ Comment PR with plan

2. **terraform-apply** (on merge to main)
   - ✅ Download plan artifact
   - ✅ Terraform apply
   - ✅ Get outputs
   - ✅ Comment with results

3. **health-check** (on merge to main)
   - ✅ Check EC2 instances
   - ✅ Check S3 buckets
   - ✅ Check VPC
   - ✅ Test web server

### **3. Check PR Comments**

After the plan job completes, you should see a comment on your PR with:
- Plan summary
- Security & compliance status
- Plan details (collapsed)

---

## ✅ **Success Criteria**

### **What to Look For:**

1. **✅ Workflow Triggers**: Workflow runs automatically on PR creation
2. **✅ Plan Job Success**: All steps in terraform-plan job pass
3. **✅ No Changes**: Plan should show "No changes. Objects have not changed."
4. **✅ PR Comment**: Automatic comment with plan details appears
5. **✅ Compliance Check**: Policy validation passes
6. **✅ Health Check**: All infrastructure components healthy

### **Expected Output:**

```
## Terraform Plan 📋

**Plan Summary:**
- Plan file generated successfully
- Ready for review and approval

**Next Steps:**
1. Review the plan output above
2. Approve this PR if changes look correct
3. Merge to trigger apply

**Security & Compliance:**
- ✅ Policy validation passed
- ✅ Cost controls enforced
- ✅ Security requirements met
```

---

## 🚨 **Troubleshooting**

### **Common Issues:**

#### **1. Workflow Not Triggering**
- **Check**: Ensure you're pushing to the correct branch
- **Check**: Verify the workflow file exists in `.github/workflows/terraform.yml`
- **Check**: Ensure changes are in the `terraform/` directory

#### **2. AWS Credentials Error**
- **Check**: Verify GitHub secrets are set correctly
- **Check**: Ensure AWS credentials have proper permissions
- **Check**: Verify AWS region is correct

#### **3. Terraform Plan Fails**
- **Check**: Look at the workflow logs for specific error messages
- **Check**: Verify terraform configuration is valid
- **Check**: Ensure AWS resources are accessible

#### **4. No PR Comment**
- **Check**: Ensure the repository has proper permissions
- **Check**: Look for errors in the workflow logs
- **Check**: Verify the PR was created correctly

### **Debug Commands:**

```powershell
# Check workflow file syntax
yamllint .github/workflows/terraform.yml

# Test terraform locally
cd terraform
terraform init
terraform validate
terraform plan

# Check AWS credentials
aws sts get-caller-identity
```

---

## 🎯 **Advanced Testing**

### **Test Different Scenarios:**

#### **1. Test with Real Changes**
```powershell
# Make a real change to test plan
echo 'instance_type = "t3.micro"' >> terraform/terraform.tfvars
git add . && git commit -m "test: change instance type" && git push
```

#### **2. Test Policy Violation**
```powershell
# Try to create an expensive instance (should fail)
# Edit terraform/test-policy-violations.tf
# Change instance type to m5.large
```

#### **3. Test Rollback**
```powershell
# Create a branch with breaking changes
# Test that the workflow catches and reports issues
```

---

## 📊 **Monitoring Dashboard**

### **GitHub Actions Dashboard:**
- **URL**: `https://github.com/[username]/[repo]/actions`
- **Features**: View all workflow runs, logs, and status

### **AWS Console Links:**
- **EC2 Dashboard**: `https://console.aws.amazon.com/ec2/v2/home?region=ap-southeast-1`
- **VPC Dashboard**: `https://console.aws.amazon.com/vpc/home?region=ap-southeast-1`
- **S3 Console**: `https://console.aws.amazon.com/s3/home`

---

## 🏆 **Success Checklist**

- [ ] GitHub repository configured
- [ ] GitHub secrets set up
- [ ] Test branch created
- [ ] Test change made
- [ ] PR created
- [ ] Workflow triggered automatically
- [ ] Plan job completed successfully
- [ ] PR comment generated
- [ ] No infrastructure changes detected
- [ ] Compliance validation passed
- [ ] Health check completed

---

## 🎉 **Next Steps**

Once your GitHub Actions workflow is working:

1. **Merge the test PR** to trigger the apply job
2. **Monitor the apply process** in the Actions tab
3. **Verify infrastructure changes** in AWS Console
4. **Test the health check** results
5. **Explore advanced features** like Atlantis integration

---

*This guide covers the complete testing process for your GitHub Actions workflow. Follow each step carefully to ensure everything works correctly.*
