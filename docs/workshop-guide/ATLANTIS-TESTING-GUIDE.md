# Atlantis Workshop Testing Guide

## 🎯 Overview

This guide provides step-by-step instructions for testing the complete Atlantis workshop with GitHub integration, including fixing the issues you encountered.

## ❌ Issues Identified & Solutions

### 1. Health Check Issues (7/8 components healthy)

**Problem**: Missing `Test-S3Buckets` function and JSON parsing errors in compliance validation.

**Solution**: Fixed health check script with proper S3 bucket checking and robust JSON parsing.

### 2. GitHub Integration Setup Issues

**Problem**: Script shows LocalStack information instead of production AWS deployment.

**Solution**: Updated setup script to properly detect AWS vs LocalStack environment.

### 3. Missing ngrok Configuration

**Problem**: ngrok not properly configured for webhook tunneling.

**Solution**: Added proper ngrok setup and validation.

## 🚀 Complete Testing Workflow

### Phase 1: Infrastructure Deployment

#### 1.1 Deploy AWS Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Deploy infrastructure
terraform plan
terraform apply -auto-approve

# Verify deployment
terraform output
```

#### 1.2 Health Check Verification

```bash
# Run comprehensive health check
.\monitoring\health-check-aws.ps1

# Expected: 8/8 components healthy
# - ✅ VPC Networking
# - ✅ EC2 Instances
# - ✅ S3 Buckets
# - ✅ CloudWatch Logs
# - ✅ Security Groups
# - ✅ Terraform State
# - ✅ Compliance Validation
# - ✅ Web Server Access
```

### Phase 2: Atlantis Setup

#### 2.1 Install Prerequisites

```bash
# Install ngrok (if not installed)
# Download from https://ngrok.com/download
# Add to PATH

# Install Docker (if not installed)
# Download from https://docker.com
```

#### 2.2 Configure GitHub Integration

```bash
# Run enhanced setup script
.\setup-github-integration.ps1

# This will:
# - Detect AWS environment (not LocalStack)
# - Configure proper ngrok tunneling
# - Set up GitHub webhook
# - Create proper .env file
```

#### 2.3 Start Atlantis

```bash
# Start Atlantis with Docker
docker-compose up -d

# Verify Atlantis is running
curl http://localhost:4141/health
```

### Phase 3: GitHub PR Testing

#### 3.1 Create Test Branch

```bash
# Create feature branch
git checkout -b test-atlantis-workflow

# Make infrastructure change
# Edit terraform/terraform.tfvars
echo "# Testing Atlantis workflow - $(Get-Date)" >> terraform/terraform.tfvars

# Commit and push
git add .
git commit -m "test: atlantis workflow - add comment"
git push origin test-atlantis-workflow
```

#### 3.2 Create Pull Request

```bash
# Using GitHub CLI
gh pr create --title "Test Atlantis Workflow" --body "Testing complete GitOps workflow with Atlantis"

# Or manually on GitHub:
# 1. Go to your repository
# 2. Click "Compare & pull request"
# 3. Add description
# 4. Create pull request
```

#### 3.3 Monitor Atlantis Response

**Expected Behavior:**

1. **Automatic Plan**: Atlantis should comment with `terraform plan` output
2. **Policy Validation**: Should show compliance check results
3. **Plan Summary**: Should display resource changes

**Example Atlantis Comment:**

```
atlantis plan
dir: terraform
workspace: default

**Plan Summary**
- 0 to add, 1 to change, 0 to destroy

**Changes**
- aws_instance.web: tags updated

**Policy Check Results**
✅ All policies passed
```

#### 3.4 Test Approval Workflow

```bash
# 1. Review the plan in PR comments
# 2. Approve the PR (if using branch protection)
# 3. Comment on PR: "atlantis apply"
# 4. Watch Atlantis apply the changes
```

### Phase 4: Advanced Testing Scenarios

#### 4.1 Test Policy Violations

```bash
# Create violation branch
git checkout -b test-policy-violation

# Add expensive instance type
echo 'instance_type = "m5.large"' >> terraform/terraform.tfvars

# Commit and create PR
git add .
git commit -m "test: policy violation - expensive instance"
git push origin test-policy-violation
gh pr create --title "Test Policy Violation" --body "Testing compliance policies"
```

**Expected Result**: Atlantis should block the plan due to policy violation.

#### 4.2 Test Security Policies

```bash
# Create security test branch
git checkout -b test-security-policies

# Add S3 bucket without encryption
# Edit terraform/main.tf to remove encryption configuration

# Commit and test
git add .
git commit -m "test: security violation - unencrypted bucket"
git push origin test-security-policies
gh pr create --title "Test Security Violation" --body "Testing security policies"
```

**Expected Result**: Atlantis should detect missing encryption.

#### 4.3 Test Tag Compliance

```bash
# Create tag test branch
git checkout -b test-tag-compliance

# Remove required tags from resources
# Edit terraform/main.tf to remove Environment/Project tags

# Commit and test
git add .
git commit -m "test: tag violation - missing required tags"
git push origin test-tag-compliance
gh pr create --title "Test Tag Violation" --body "Testing tag compliance"
```

**Expected Result**: Atlantis should detect missing required tags.

### Phase 5: Monitoring & Verification

#### 5.1 Monitor Atlantis Logs

```bash
# View Atlantis logs
docker-compose logs -f atlantis

# Check for errors or issues
docker-compose logs atlantis | grep -i error
```

#### 5.2 Verify GitHub Webhook

```bash
# Check webhook deliveries
gh api repos/yourusername/terraform-atlantis-workshop/hooks \
  --method GET \
  --jq '.[0].deliveries[] | {id: .id, status: .status, delivered_at: .delivered_at}'
```

#### 5.3 Verify AWS Changes

```bash
# Check if changes were applied
terraform show

# Verify resources in AWS
aws ec2 describe-instances --filters "Name=tag:Project,Values=terraform-atlantis-workshop"
aws s3api list-buckets --query 'Buckets[?contains(Name, `terraform-atlantis-workshop`)]'
```

## 🔧 Troubleshooting

### Common Issues & Solutions

#### 1. Atlantis Not Responding to PRs

```bash
# Check Atlantis is running
docker-compose ps

# Check webhook configuration
gh api repos/yourusername/terraform-atlantis-workshop/hooks

# Verify ngrok tunnel
curl http://localhost:4040/api/tunnels
```

#### 2. Webhook Delivery Failures

```bash
# Check webhook secret matches
# Verify ngrok URL is correct
# Check Atlantis logs for webhook errors
docker-compose logs atlantis | grep webhook
```

#### 3. Terraform Plan Failures

```bash
# Check AWS credentials in Atlantis container
docker-compose exec atlantis aws sts get-caller-identity

# Check Terraform configuration
docker-compose exec atlantis terraform validate
```

#### 4. Policy Check Failures

```bash
# Check policy files exist
ls -la policies/

# Verify policy syntax
# Check Atlantis policy configuration
```

## 📊 Success Criteria

### ✅ Workshop Completion Checklist

-   [ ] **Infrastructure Deployed**: AWS resources created successfully
-   [ ] **Health Check**: 8/8 components healthy
-   [ ] **Atlantis Running**: Containerized Atlantis accessible
-   [ ] **GitHub Integration**: Webhook configured and delivering
-   [ ] **PR Workflow**: Automatic plan generation on PR creation
-   [ ] **Policy Validation**: Compliance policies enforced
-   [ ] **Approval Workflow**: Manual approval required for apply
-   [ ] **Apply Process**: Changes applied successfully after approval
-   [ ] **Monitoring**: Logs and metrics accessible
-   [ ] **Cleanup**: Infrastructure destroyed after testing

### 🎯 Testing Scenarios Completed

-   [ ] **Basic PR Workflow**: Plan → Review → Approve → Apply
-   [ ] **Policy Violations**: Expensive instances blocked
-   [ ] **Security Policies**: Encryption requirements enforced
-   [ ] **Tag Compliance**: Required tags validated
-   [ ] **Error Handling**: Failed plans handled gracefully
-   [ ] **Rollback**: Infrastructure changes reverted

## 🧹 Cleanup

### After Testing Complete

```bash
# Destroy infrastructure
cd terraform
terraform destroy -auto-approve

# Stop Atlantis
docker-compose down

# Remove test branches
git branch -D test-atlantis-workflow
git branch -D test-policy-violation
git branch -D test-security-policies
git branch -D test-tag-compliance

# Push branch deletions
git push origin --delete test-atlantis-workflow
git push origin --delete test-policy-violation
git push origin --delete test-security-policies
git push origin --delete test-tag-compliance
```

## 📚 Additional Resources

-   [Atlantis Documentation](https://www.runatlantis.io/docs/)
-   [GitHub Webhooks Guide](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
-   [Terraform Policy Examples](https://www.terraform.io/docs/cloud/sentinel/examples.html)
-   [AWS Cost Optimization](https://aws.amazon.com/cost-optimization/)

---

**Ready to test?** Follow this guide step-by-step to ensure your Atlantis workshop works perfectly! 🚀
