# GitOps with Atlantis Guide

## 🎯 Overview

This guide covers setting up GitOps workflows with Atlantis for automated infrastructure deployments. You'll learn how to configure GitHub webhooks, automate Terraform operations, and enforce compliance policies in your GitOps pipeline.

## 📋 Prerequisites

Before starting this guide, ensure you have:

-   ✅ **Infrastructure deployed** to AWS (04-AWS-DEPLOYMENT.md)
-   ✅ **Compliance policies** working (05-COMPLIANCE.md)
-   ✅ **GitHub repository** with Terraform code
-   ✅ **Docker** installed and running
-   ✅ **Git** configured and working

## 🏗️ GitOps Architecture Overview

### **What is GitOps?**

GitOps is a practice where:

-   **Git is the single source of truth** for infrastructure
-   **Pull requests trigger deployments** automatically
-   **Infrastructure changes are auditable** and traceable
-   **Compliance is enforced** in the deployment pipeline

### **Atlantis Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │    │    Atlantis     │    │   AWS Cloud     │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Terraform   │ │───▶│ │ Webhook     │ │───▶│ │ VPC         │ │
│ │ Code        │ │    │ │ Handler     │ │    │ │ EC2         │ │
│ │ Policies    │ │    │ │ Policy      │ │    │ │ S3          │ │
│ │ Tests       │ │    │ │ Validation  │ │    │ │ CloudWatch  │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Pull Request  │    │   Terraform     │    │   Deployment    │
│   Workflow      │    │   Operations    │    │   Automation    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Atlantis Installation

### **1. Install Atlantis**

#### **Using Docker (Recommended)**

```bash
# Pull Atlantis image
docker pull runatlantis/atlantis:latest

# Verify installation
docker run --rm runatlantis/atlantis:latest atlantis version
```

#### **Using Binary**

```bash
# Download Atlantis binary
wget https://github.com/runatlantis/atlantis/releases/download/v0.24.0/atlantis_linux_amd64.zip
unzip atlantis_linux_amd64.zip
sudo mv atlantis /usr/local/bin/

# Verify installation
atlantis version
```

### **2. Configure Atlantis**

#### **Create Atlantis Configuration**

```bash
# Create atlantis directory
mkdir -p atlantis

# Create atlantis.yaml configuration
cat > atlantis/atlantis.yaml << EOF
version: 3
projects:
- name: terraform-atlantis-workshop
  dir: terraform
  workspace: default
  terraform_version: v1.6.0
  autoplan:
    when_modified: ["*.tf", "../modules/**/*.tf"]
    enabled: true
  apply_requirements: [approved, mergeable]
  workflow: custom
workflows:
  custom:
    plan:
      steps:
      - run: terraform plan -out=\$PLANFILE
    apply:
      steps:
      - run: terraform apply \$PLANFILE
EOF
```

#### **Create Atlantis Server Configuration**

```bash
# Create atlantis server configuration
cat > atlantis/server.yaml << EOF
# Atlantis server configuration
repo-allowlist: github.com/yourusername/terraform-atlantis-workshop
gh-token: \$GITHUB_TOKEN
gh-webhook-secret: \$WEBHOOK_SECRET
gh-user: atlantis
gh-hostname: github.com
log-level: info
port: 4141
EOF
```

### **3. Set Up GitHub Integration**

#### **Create GitHub Personal Access Token**

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token with permissions:
    - `repo` (full control)
    - `admin:org` (if using organization)
    - `admin:repo_hook` (for webhooks)

#### **Configure Environment Variables**

```bash
# Set GitHub token
export GITHUB_TOKEN="your-github-token"

# Generate webhook secret
export WEBHOOK_SECRET=$(openssl rand -base64 32)

# Verify environment variables
echo "GITHUB_TOKEN: ${GITHUB_TOKEN:0:10}..."
echo "WEBHOOK_SECRET: ${WEBHOOK_SECRET:0:10}..."
```

## 🔧 GitHub Webhook Configuration

### **1. Set Up Webhook**

#### **Using GitHub CLI**

```bash
# Install GitHub CLI if not installed
# macOS: brew install gh
# Linux: sudo apt install gh

# Authenticate with GitHub
gh auth login

# Create webhook
gh api repos/yourusername/terraform-atlantis-workshop/hooks \
  --method POST \
  --field name=web \
  --field active=true \
  --field events='["pull_request", "push"]' \
  --field config.url="http://your-atlantis-url:4141/events" \
  --field config.content_type=application/json \
  --field config.secret="$WEBHOOK_SECRET"
```

#### **Using GitHub Web Interface**

1. Go to your repository on GitHub
2. Navigate to Settings → Webhooks
3. Click "Add webhook"
4. Configure:
    - **Payload URL**: `http://your-atlantis-url:4141/events`
    - **Content type**: `application/json`
    - **Secret**: Your webhook secret
    - **Events**: Select "Pull requests" and "Pushes"
5. Click "Add webhook"

### **2. Test Webhook**

```bash
# Test webhook delivery
gh api repos/yourusername/terraform-atlantis-workshop/hooks \
  --method GET \
  --jq '.[0].last_response.status'
```

## 🏃‍♂️ Running Atlantis

### **1. Start Atlantis Server**

#### **Using Docker**

```bash
# Run Atlantis with Docker
docker run -d \
  --name atlantis \
  -p 4141:4141 \
  -e GITHUB_TOKEN="$GITHUB_TOKEN" \
  -e GITHUB_WEBHOOK_SECRET="$WEBHOOK_SECRET" \
  -e ATLANTIS_REPO_ALLOWLIST="github.com/yourusername/terraform-atlantis-workshop" \
  -e ATLANTIS_GH_USER="atlantis" \
  -e ATLANTIS_GH_HOSTNAME="github.com" \
  -v $(pwd):/workspace \
  runatlantis/atlantis:latest server
```

#### **Using Binary**

```bash
# Run Atlantis server
atlantis server \
  --gh-token="$GITHUB_TOKEN" \
  --gh-webhook-secret="$WEBHOOK_SECRET" \
  --repo-allowlist="github.com/yourusername/terraform-atlantis-workshop" \
  --gh-user="atlantis" \
  --gh-hostname="github.com" \
  --port=4141
```

### **2. Verify Atlantis is Running**

```bash
# Check if Atlantis is running
curl http://localhost:4141/health

# Check Atlantis logs
docker logs atlantis

# Or if running binary
# Check process
ps aux | grep atlantis
```

## 🔄 GitOps Workflow

### **1. Development Workflow**

```bash
# 1. Create feature branch
git checkout -b feature/new-resource

# 2. Make infrastructure changes
# Edit terraform/main.tf or other files

# 3. Commit changes
git add .
git commit -m "Add new infrastructure resource"

# 4. Push to repository
git push origin feature/new-resource

# 5. Create pull request on GitHub
gh pr create --title "Add new infrastructure resource" --body "This PR adds a new EC2 instance for testing."

# 6. Atlantis will automatically run plan
# Check the PR comments for plan output
```

### **2. Pull Request Workflow**

#### **Automatic Plan**

When you create a pull request:

1. Atlantis detects the PR
2. Runs `terraform plan` automatically
3. Comments on the PR with plan results
4. Shows any compliance violations

#### **Manual Commands**

You can also trigger Atlantis manually:

```bash
# In PR comments, use:
atlantis plan -p terraform-atlantis-workshop

# To apply changes:
atlantis apply -p terraform-atlantis-workshop
```

### **3. Approval and Merge**

#### **Review Process**

1. **Review the plan** in PR comments
2. **Check for violations** and fix if needed
3. **Approve the PR** if everything looks good
4. **Merge the PR** to trigger apply

#### **Automatic Apply**

After merging:

1. Atlantis automatically runs `terraform apply`
2. Updates infrastructure in AWS
3. Comments on the PR with apply results

## 🧪 Testing GitOps Workflow

### **1. Test Policy Violations**

#### **Create Violation PR**

```bash
# Create branch for testing
git checkout -b test-policy-violation

# Modify terraform/test-policy-violations.tf
# Add expensive instance type
cat >> terraform/test-policy-violations.tf << EOF

resource "aws_instance" "expensive_test" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "m5.large"  # Expensive instance type

  tags = {
    Name        = "expensive-test-instance"
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}
EOF

# Commit and push
git add .
git commit -m "Test policy violation with expensive instance"
git push origin test-policy-violation

# Create PR
gh pr create --title "Test policy violation" --body "Testing compliance policies with expensive instance type"
```

#### **Verify Violation Detection**

1. Check PR comments for Atlantis plan
2. Look for violation error messages
3. Verify that apply is blocked

### **2. Test Fix and Deploy**

#### **Fix the Violation**

```bash
# Fix the violation
sed -i 's/m5.large/t3.micro/' terraform/test-policy-violations.tf

# Commit the fix
git add .
git commit -m "Fix policy violation: change to t3.micro"
git push origin test-policy-violation
```

#### **Verify Fix**

1. Check PR comments for updated plan
2. Verify no violations are reported
3. Approve and merge the PR
4. Verify successful deployment

### **3. Test Different Scenarios**

#### **Test Tag Violations**

```bash
# Create branch for tag testing
git checkout -b test-tag-violation

# Remove required tags from main.tf
# Comment out Project tag in web instance

# Commit and test
git add .
git commit -m "Test tag violation"
git push origin test-tag-violation
gh pr create --title "Test tag violation" --body "Testing tag compliance policies"
```

#### **Test Naming Violations**

```bash
# Create branch for naming testing
git checkout -b test-naming-violation

# Create bucket with non-compliant name
cat >> terraform/test-policy-violations.tf << EOF

resource "aws_s3_bucket" "non_compliant" {
  bucket = "my-non-compliant-bucket"

  tags = {
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    CostCenter  = "workshop-training"
  }
}
EOF

# Commit and test
git add .
git commit -m "Test naming violation"
git push origin test-naming-violation
gh pr create --title "Test naming violation" --body "Testing naming convention policies"
```

## 📊 Monitoring GitOps

### **1. Atlantis Logs**

```bash
# View Atlantis logs
docker logs -f atlantis

# Or if running binary
# Check log files or console output
```

### **2. GitHub Integration**

```bash
# Check webhook deliveries
gh api repos/yourusername/terraform-atlantis-workshop/hooks \
  --method GET \
  --jq '.[0].deliveries[] | {id: .id, status: .status, delivered_at: .delivered_at}'

# Check recent PRs
gh pr list --limit 10
```

### **3. Infrastructure State**

```bash
# Check Terraform state
cd terraform
terraform show

# Check AWS resources
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=terraform-atlantis-workshop" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

## 🔒 Security Best Practices

### **1. Access Control**

-   **Use GitHub App** instead of personal access tokens
-   **Implement branch protection** rules
-   **Require PR reviews** before merge
-   **Use least privilege** for Atlantis permissions

### **2. Secret Management**

```bash
# Use environment variables for secrets
export GITHUB_TOKEN="your-token"
export WEBHOOK_SECRET="your-secret"

# Or use secret management tools
# AWS Secrets Manager
# HashiCorp Vault
# GitHub Secrets (for GitHub Actions)
```

### **3. Network Security**

-   **Use HTTPS** for webhook endpoints
-   **Implement IP allowlisting** for Atlantis
-   **Use VPC endpoints** for AWS access
-   **Enable CloudTrail** for audit logging

## 🚨 Troubleshooting

### **1. Common Issues**

#### **Webhook Not Delivering**

```bash
# Check webhook configuration
gh api repos/yourusername/terraform-atlantis-workshop/hooks \
  --method GET \
  --jq '.[0] | {url: .config.url, active: .active, events: .events}'

# Check Atlantis is accessible
curl -I http://your-atlantis-url:4141/health
```

#### **Atlantis Not Responding**

```bash
# Check Atlantis logs
docker logs atlantis

# Check environment variables
docker exec atlantis env | grep -E "(GITHUB|ATLANTIS)"

# Restart Atlantis if needed
docker restart atlantis
```

#### **Terraform Plan Failing**

```bash
# Check Terraform configuration
cd terraform
terraform validate

# Check AWS credentials
aws sts get-caller-identity

# Check Atlantis workspace
docker exec -it atlantis ls -la /workspace/terraform
```

### **2. Debugging Commands**

```bash
# Test webhook manually
curl -X POST http://localhost:4141/events \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -d '{"action": "opened", "pull_request": {"number": 1}}'

# Check Atlantis status
curl http://localhost:4141/status

# View recent operations
curl http://localhost:4141/events
```

## 📋 GitOps Checklist

Before considering GitOps complete, verify:

-   [ ] **Atlantis installed** and running
-   [ ] **GitHub webhook configured** and delivering
-   [ ] **Repository allowlist** configured correctly
-   [ ] **Compliance policies** enforced in GitOps
-   [ ] **Pull request workflow** working
-   [ ] **Automatic plan/apply** functioning
-   [ ] **Security measures** implemented
-   [ ] **Monitoring and logging** active

## 🎯 Best Practices

### **1. Workflow Design**

-   **Use feature branches** for all changes
-   **Require PR reviews** before merge
-   **Automate testing** in the pipeline
-   **Document changes** in PR descriptions

### **2. Security**

-   **Rotate tokens** regularly
-   **Use GitHub Apps** for better security
-   **Implement branch protection** rules
-   **Monitor access** and audit logs

### **3. Operations**

-   **Monitor Atlantis** health and performance
-   **Backup Terraform state** regularly
-   **Test disaster recovery** procedures
-   **Keep Atlantis updated** to latest version

## 📞 Support

If you encounter GitOps issues:

1. **Check Atlantis logs** for error messages
2. **Verify webhook configuration** and delivery
3. **Test GitHub integration** and permissions
4. **Review troubleshooting guide** (09-TROUBLESHOOTING.md)
5. **Check Atlantis documentation** and community

---

**GitOps working?** Continue to [07-TESTING.md](07-TESTING.md) to test your complete infrastructure!
