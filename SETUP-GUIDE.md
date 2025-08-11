# Terraform Atlantis Workshop - Setup Guide

## 🚨 **CRITICAL SECURITY NOTICE**

**Before proceeding, you MUST fix the security issues:**

1. **Run the security fix script:**

    ```powershell
    .\fix-security-issues.ps1
    ```

2. **Rotate your AWS credentials immediately** - they are currently exposed in the `.env` file
3. **Rotate your GitHub token** - it is currently exposed in the `.env` file
4. **Use GitHub secrets for production** - never commit real credentials

## 📋 **Prerequisites**

### Required Software

-   **Terraform** (v1.6.0 or later)
-   **AWS CLI** (configured with credentials)
-   **Docker** and **Docker Compose**
-   **PowerShell** (Windows) or equivalent shell
-   **Git** for version control
-   **GitHub account** (for Atlantis integration)

### AWS Setup

1. **Create AWS Account** (if you don't have one)
2. **Configure AWS CLI:**
    ```bash
    aws configure
    ```
3. **Verify AWS access:**
    ```bash
    aws sts get-caller-identity
    ```

## 🚀 **Quick Start**

### 1. **Fix Security Issues First**

```powershell
# Run the security fix script
.\fix-security-issues.ps1

# Follow the instructions to rotate credentials
```

### 2. **Configure Environment**

```powershell
# Copy the secure template
Copy-Item ".env.secure-template" ".env"

# Edit .env with your values (use placeholders for credentials)
notepad .env
```

### 3. **Set Up GitHub Actions Secrets**

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add the following secrets:
    - `AWS_ACCESS_KEY_ID`
    - `AWS_SECRET_ACCESS_KEY`
    - `AWS_DEFAULT_REGION`

### 4. **Deploy Infrastructure**

```powershell
# Navigate to terraform directory
cd terraform

# Deploy to AWS
.\deploy-aws.ps1
```

### 5. **Verify Deployment**

```powershell
# Run health check
.\monitoring\health-check-aws.ps1
```

## 🔧 **Detailed Setup**

### **Option 1: GitHub Actions (Recommended)**

The project is configured to use GitHub Actions for automated deployment:

1. **Push your changes to GitHub**
2. **Create a Pull Request**
3. **GitHub Actions will automatically:**
    - Run `terraform plan`
    - Validate compliance
    - Apply changes (after approval)

### **Option 2: Local Atlantis Setup**

For local development with Atlantis:

1. **Start Atlantis:**

    ```powershell
    docker-compose up -d
    ```

2. **Access Atlantis UI:**

    ```
    http://localhost:4141
    ```

3. **Configure GitHub webhook:**
    - Go to your repository settings
    - Add webhook: `http://your-domain:4141/events`
    - Set content type to `application/json`

### **Option 3: Manual Terraform**

For direct Terraform usage:

```powershell
cd terraform

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply
```

## 📁 **Project Structure**

```
terraform-atlantis-workshop/
├── atlantis.yaml              # ✅ Atlantis workflow configuration
├── docker-compose.yml         # ✅ Docker setup for Atlantis
├── terraform/
│   ├── main.tf               # ✅ Main Terraform configuration
│   ├── main-aws.tf           # ✅ AWS production configuration
│   ├── terraform.tfvars      # ✅ Configuration values
│   ├── variables.tf          # ✅ Variable definitions
│   ├── outputs.tf            # ✅ Output values
│   ├── compliance-validation.tf # ✅ Compliance rules
│   └── deploy-aws.ps1        # ✅ Deployment script
├── .github/workflows/
│   └── terraform.yml         # ✅ GitHub Actions workflow
├── monitoring/
│   └── health-check-aws.ps1  # ✅ Health monitoring
└── policies/                 # ✅ Policy definitions
```

## 🔍 **Configuration Files**

### **terraform.tfvars**

```hcl
# AWS Configuration
region = "ap-southeast-1"
environment = "workshop"
project_name = "terraform-atlantis-workshop"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

# EC2 Configuration
instance_type = "t3.micro"
key_pair_name = ""  # Optional

# S3 Configuration
s3_bucket_suffix = "workshop-bucket"
```

### **atlantis.yaml**

```yaml
version: 3
projects:
    - name: terraform-atlantis-workshop
      dir: terraform
      workspace: default
      terraform_version: v1.6.0
      autoplan:
          when_modified: ["*.tf", "../.github/workflows/*.yml"]
          enabled: true
      apply_requirements: [approved, mergeable]
```

## 🧪 **Testing**

### **Test Compliance Validation**

1. **Introduce a violation:**

    ```hcl
    # In terraform/test-policy-violations.tf
    resource "aws_instance" "test" {
      instance_type = "m5.large"  # VIOLATION: Expensive instance
    }
    ```

2. **Run plan:**

    ```bash
    terraform plan
    ```

3. **See violation detected:**
    ```
    ❌ VIOLATION: Found expensive instance types...
    ```

### **Test GitHub Actions**

1. **Create a branch:**

    ```bash
    git checkout -b test-github-actions
    ```

2. **Make a change:**

    ```bash
    echo "# Testing GitHub Actions" >> terraform/terraform.tfvars
    ```

3. **Commit and push:**

    ```bash
    git add .
    git commit -m "test: github actions workflow"
    git push origin test-github-actions
    ```

4. **Create Pull Request** and watch GitHub Actions run

## 🔒 **Security Best Practices**

### **Never Do This:**

-   ❌ Commit real credentials to version control
-   ❌ Use hardcoded secrets in scripts
-   ❌ Share access keys in documentation

### **Always Do This:**

-   ✅ Use environment variables for local development
-   ✅ Use GitHub secrets for CI/CD
-   ✅ Rotate credentials regularly
-   ✅ Use IAM roles when possible
-   ✅ Enable MFA on AWS accounts

## 🚨 **Troubleshooting**

### **Common Issues**

**AWS Credentials Error:**

```bash
# Check credentials
aws sts get-caller-identity

# Configure if needed
aws configure
```

**Terraform Init Error:**

```bash
# Clear cache
rm -rf .terraform
terraform init
```

**Atlantis Not Accessible:**

```bash
# Check if running
docker-compose ps

# Check logs
docker-compose logs atlantis
```

**GitHub Actions Fail:**

1. Check repository secrets are set
2. Verify AWS credentials are valid
3. Check workflow file syntax

### **Getting Help**

1. **Check the logs:**

    ```bash
    # Terraform logs
    terraform plan -detailed-exitcode

    # Atlantis logs
    docker-compose logs atlantis

    # GitHub Actions logs
    # Check the Actions tab in GitHub
    ```

2. **Run health checks:**

    ```bash
    .\monitoring\health-check-aws.ps1
    ```

3. **Verify configuration:**
    ```bash
    .\validate-env-setup.ps1
    ```

## 📚 **Next Steps**

1. **Explore the documentation:**

    - `docs/1.OPERATIONS.md` - Operational procedures
    - `docs/2.COMPLIANCE-VALIDATION.md` - Compliance system
    - `docs/3.DEPLOYMENT-GUIDE.md` - Deployment procedures

2. **Test the compliance validation:**

    - Try introducing policy violations
    - Verify they are caught during plan

3. **Set up monitoring:**

    - Configure CloudWatch alerts
    - Set up cost monitoring

4. **Production deployment:**
    - Review security configurations
    - Set up proper backup strategies
    - Configure monitoring and alerting

## 🎯 **Success Criteria**

You've successfully set up the workshop when:

-   ✅ AWS credentials are secure (not in version control)
-   ✅ GitHub Actions secrets are configured
-   ✅ Infrastructure deploys successfully
-   ✅ Compliance validation works
-   ✅ Health checks pass
-   ✅ Atlantis is accessible (if using local setup)

---

**Need help?** Check the troubleshooting section or review the documentation in the `docs/` directory.
