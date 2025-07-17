# Approval Workflow Testing Guide
## Enhanced GitHub + Atlantis Integration

### Overview
This guide will help you test the enhanced approval workflow for your Terraform Atlantis workshop. The workflow enforces GitOps best practices with mandatory approvals and policy validation.

> **⚠️ Important**: Testing happens on **this repository** (`terraform-atlantis-workshop`), but requires GitHub integration setup first.

## 📋 **Prerequisites**

Before running these tests, ensure you have:

1. **✅ GitHub Integration Configured**
   - Created GitHub Personal Access Token (with `repo` and `admin:repo_hook` permissions)
   - Set up webhook secret
   - Configured `.env` file with your GitHub details
   - Run `./setup-github-integration.ps1` if needed

2. **✅ Services Running**
   ```powershell
   # Start LocalStack and Atlantis
   docker-compose up -d
   
   # Verify services are running
   docker-compose ps
   ```

3. **✅ Ngrok Tunnel Active** (for webhook delivery)
   ```powershell
   # In a separate terminal
   ngrok http 4141
   # Update ATLANTIS_ATLANTIS_URL in .env with the ngrok URL
   ```

4. **✅ Repository Webhook Configured**
   - GitHub repository settings → Webhooks
   - Payload URL: `https://your-ngrok-url.ngrok-free.app/events`
   - Content type: `application/json`
   - Secret: your webhook secret from `.env`
   - Events: Pull requests, Issue comments, Push

---

## 🔧 **Quick Setup Verification**

Before starting the tests, verify your setup:

```powershell
# 1. Check if .env file exists and is configured
if (Test-Path .env) { 
    Write-Host "✅ .env file exists" 
    Get-Content .env | Select-String "ATLANTIS_GH_USER|ATLANTIS_REPO_ALLOWLIST|ATLANTIS_ATLANTIS_URL"
} else { 
    Write-Host "❌ .env file missing - copy from .env.example and configure" 
}

# 2. Check if services are running
docker-compose ps

# 3. Test Atlantis health
Invoke-RestMethod -Uri "http://localhost:4141/healthz" -Method Get
```

**Expected Output:**
- ✅ `.env` file exists with your GitHub username and repository
- ✅ LocalStack and Atlantis containers are running
- ✅ Atlantis health check returns "ok"

---

## 🧪 **Test Scenarios**

### **Scenario 1: Basic Approval Workflow**
**Objective**: Verify pull request → plan → approve → apply workflow

> **📍 Repository**: Tests run on this repository (`Bright-04/terraform-atlantis-workshop`)  
> **🔄 Workflow**: Create branch → Make changes → Push → Create PR → Review → Approve → Apply

#### Steps:
1. **Create test branch**
   ```powershell
   git checkout -b test-basic-approval
   ```

2. **Make a simple change**
   > **Note**: `terraform.tfvars` is in `.gitignore` so changes to it won't trigger Atlantis. We'll modify tracked Terraform files instead.
   
   ```powershell
   # Option A: Add a comment to variables.tf (minimal change)
   echo "" >> terraform/variables.tf
   echo "# Testing basic approval workflow - $(Get-Date)" >> terraform/variables.tf
   ```
   
   **OR (Better for testing)**
   
   ```powershell
   # Option B: Add a simple tag to an existing resource (shows actual Terraform plan)
   # This will trigger a real Terraform plan showing the change
   
   # Add a test tag to the VPC resource in main.tf
   # Find the VPC resource and add TestApproval = "true" to its tags
   (Get-Content terraform\main.tf) -replace 
   '  tags = {
    Name = "\$\{var\.project_name\}-vpc"
  }', 
   '  tags = {
    Name = "${var.project_name}-vpc"
    TestApproval = "true"
  }' | Set-Content terraform\main.tf
   ```

3. **Commit and push**
   ```powershell
   # If you used Option A (variables.tf)
   git add terraform/variables.tf
   
   # If you used Option B (main.tf)
   git add terraform/main.tf
   
   git commit -m "test: basic approval workflow"
   git push origin test-basic-approval
   ```

4. **Create Pull Request**
   - Go to GitHub: `https://github.com/Bright-04/terraform-atlantis-workshop`
   - Create PR from `test-basic-approval` to `main` branch
   - **Watch for**: Atlantis will automatically comment with a Terraform plan within 1-2 minutes
   - **Check**: PR status shows "Some checks haven't completed yet" (this is the approval requirement)

5. **Review and Approve**
   - Review the Terraform plan in the Atlantis comment
   - Click "Approve" on the PR in GitHub (or have someone else approve it)
   - **After approval**: Comment `atlantis apply` on the PR to execute the changes
   - **Watch for**: Atlantis will apply the changes and comment with results

**Expected Results:**
- ✅ Atlantis automatically comments with plan
- ✅ Apply blocked until PR approval
- ✅ Apply succeeds after approval and comment
- ✅ Infrastructure changes applied to LocalStack

---

### **Alternative Simple Changes for Testing**

If you want to test with different types of changes:

#### **Option 1: Add an output (safest)**
```powershell
# Add to terraform/outputs.tf
echo "" >> terraform/outputs.tf
echo "# Test output" >> terraform/outputs.tf
echo "output \"test_timestamp\" {" >> terraform/outputs.tf
echo "  description = \"Test approval workflow\"" >> terraform/outputs.tf
echo "  value       = \"$(Get-Date)\"" >> terraform/outputs.tf
echo "}" >> terraform/outputs.tf
```

#### **Option 2: Modify variable description**
```powershell
# Edit terraform/variables.tf to change a description
(Get-Content terraform\variables.tf) -replace 
'description = "AWS region"', 
'description = "AWS region for deployment"' | Set-Content terraform\variables.tf
```

#### **Option 3: Add data source (read-only)**
```powershell
# Add to terraform/main.tf (after existing data sources)
echo "" >> terraform/main.tf
echo "# Test data source for approval workflow" >> terraform/main.tf
echo "data \"aws_caller_identity\" \"current\" {}" >> terraform/main.tf
```

---

### **Scenario 2: Policy Validation Testing**
**Objective**: Test security and cost control policies

#### Steps:
1. **Create policy test branch**
   ```bash
   git checkout -b test-policy-validation
   ```

2. **Make a change that violates policies**
   ```bash
   # Edit terraform/main.tf to add instance without proper tags
   # This should trigger policy violations
   ```

3. **Add this to terraform/main.tf** (temporarily):
   ```hcl
   resource "aws_instance" "policy_test" {
     ami           = data.aws_ami.amazon_linux.id
     instance_type = "m5.large"  # Expensive instance - should be blocked
     subnet_id     = aws_subnet.public.id
     
     # Missing required tags - should trigger policy violation
   }
   ```

4. **Commit and create PR**
   ```bash
   git add terraform/main.tf
   git commit -m "test: policy validation with violations"
   git push origin test-policy-validation
   ```

5. **Observe policy failures**
   - Check Atlantis comments for policy violations
   - Verify that apply is blocked due to policy failures

**Expected Results:**
- ❌ Policy violations detected and reported
- ❌ Apply blocked due to policy failures
- ✅ Clear error messages about violations

---

### **Scenario 3: Successful Policy Compliance**
**Objective**: Test successful deployment with policy compliance

#### Steps:
1. **Create compliant test branch**
   ```bash
   git checkout -b test-policy-compliant
   ```

2. **Add compliant resource**
   ```bash
   # Add this to terraform/main.tf
   ```
   ```hcl
   resource "aws_instance" "compliant_test" {
     ami           = data.aws_ami.amazon_linux.id
     instance_type = "t3.micro"  # Allowed instance type
     subnet_id     = aws_subnet.public.id
     
     tags = {
       Name        = "compliant-test-instance"
       Environment = var.environment
       Project     = var.project_name
       CostCenter  = "workshop"
       ManagedBy   = "Terraform"
       Backup      = "daily"
     }
   }
   ```

3. **Commit and create PR**
   ```bash
   git add terraform/main.tf
   git commit -m "test: compliant resource with proper tags"
   git push origin test-policy-compliant
   ```

4. **Complete approval workflow**
   - Create PR
   - Review plan
   - Approve PR
   - Apply changes

**Expected Results:**
- ✅ All policies pass
- ✅ Plan shows compliant resource creation
- ✅ Apply succeeds without errors
- ✅ Resource created in LocalStack

---

## 🔍 **Verification Commands**

### Check Atlantis Status
```powershell
# Check Atlantis container
docker-compose ps atlantis

# View Atlantis logs
docker-compose logs atlantis

# Check Atlantis health
curl "http://localhost:4141/healthz"
```

### Verify LocalStack Resources
```powershell
# Set environment for LocalStack
$env:AWS_ACCESS_KEY_ID="test"
$env:AWS_SECRET_ACCESS_KEY="test"
$env:AWS_DEFAULT_REGION="us-east-1"

# Check EC2 instances
aws --endpoint-url=http://localhost:4566 ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' --output table

# Check S3 buckets
aws --endpoint-url=http://localhost:4566 s3 ls

# Check VPC resources
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table
```

### Check Policy Validation
```bash
# Test policies locally (if conftest is installed)
conftest verify --policy policies/ terraform/

# Check for policy files
ls -la policies/
```

---

## 🎯 **Success Criteria**

Your approval workflow is working correctly when:

- [ ] **Automatic Planning**: Atlantis automatically comments with plan on PR creation
- [ ] **Approval Requirements**: Apply is blocked until PR is approved
- [ ] **Policy Validation**: Security and cost policies are enforced
- [ ] **Apply Control**: Apply only works with `atlantis apply` comment
- [ ] **Audit Trail**: Complete history of changes in GitHub PR comments
- [ ] **Error Handling**: Clear error messages for policy violations
- [ ] **Resource Creation**: Changes successfully applied to LocalStack

---

## 🔧 **Troubleshooting**

### Common Issues:

#### Atlantis Not Commenting on PRs
- Check webhook configuration in GitHub
- Verify ngrok tunnel is active
- Check Atlantis logs: `docker-compose logs atlantis`
- Ensure GitHub token has proper permissions

#### Policy Validation Errors
- Check policy syntax: `conftest verify --policy policies/`
- Verify policy files are in correct location
- Check Atlantis policy configuration in atlantis.yaml

#### Apply Failures
- Ensure LocalStack is running: `docker-compose ps localstack`
- Check LocalStack health: `curl "http://localhost:4566/_localstack/health"`
- Verify AWS credentials are set for LocalStack

#### Permission Errors
- GitHub token needs: `repo`, `admin:repo_hook` permissions
- Check repository allowlist in .env file
- Verify webhook secret matches configuration

---

## 📊 **Workshop Completion Status**

After successful testing:

- ✅ **Provisioning automation** - Working with LocalStack
- ✅ **Approval workflows** - Implemented and tested
- 🔄 **Cost controls** - Basic policies implemented (enhance with Infracost)
- 🔄 **Monitoring integration** - Ready for CloudWatch integration
- 🔄 **Compliance validation** - Basic policies implemented (enhance with OPA)
- 🔄 **Rollback procedures** - Ready for implementation
- ✅ **Operational procedures** - Documented and tested
- ✅ **Documentation** - Complete with testing guide

**Next Phase**: Implement Cost Controls with Infracost integration
