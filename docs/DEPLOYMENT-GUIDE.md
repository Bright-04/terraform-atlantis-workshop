# Deployment Guide - Terraform Atlantis Workshop

## Overview

This guide covers deployment procedures for the Terraform Atlantis Workshop infrastructure, including LocalStack development environment and AWS production deployment.

## 🎯 Current Status

### ✅ **Active Environment**: LocalStack Development

-   **Status**: Fully deployed and operational
-   **Endpoint**: http://localhost:4566
-   **Resources**: VPC, EC2 instances, S3 buckets, security groups
-   **Compliance**: All resources pass validation

### 🔄 **Available Environments**

1. **LocalStack Development** (Current) - Cost-free AWS simulation
2. **AWS Production** (Backup) - Real AWS infrastructure

## 🚀 LocalStack Deployment (Current)

### Prerequisites

-   Docker and Docker Compose installed
-   PowerShell (Windows) or equivalent shell
-   Git for version control

### Quick Deployment

1. **Start LocalStack**:

    ```powershell
    # Start LocalStack service
    docker-compose up localstack -d

    # Verify LocalStack is running
    docker-compose ps
    ```

2. **Deploy Infrastructure**:

    ```powershell
    cd terraform
    .\deploy.ps1
    ```

3. **Verify Deployment**:

    ```powershell
    # Check Terraform outputs
    terraform output

    # Check LocalStack resources
    aws --endpoint-url=http://localhost:4566 ec2 describe-instances
    aws --endpoint-url=http://localhost:4566 s3 ls
    ```

### Detailed LocalStack Setup

1. **Environment Configuration**:

    ```powershell
    # Set LocalStack environment variables
    $env:AWS_ACCESS_KEY_ID="test"
    $env:AWS_SECRET_ACCESS_KEY="test"
    $env:AWS_DEFAULT_REGION="us-east-1"
    ```

2. **Initialize Terraform**:

    ```powershell
    cd terraform
    terraform init
    ```

3. **Plan Deployment**:

    ```powershell
    terraform plan
    ```

4. **Apply Configuration**:
    ```powershell
    terraform apply -auto-approve
    ```

### LocalStack Resource Verification

**Check EC2 Instances**:

```powershell
aws --endpoint-url=http://localhost:4566 ec2 describe-instances \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

**Check S3 Buckets**:

```powershell
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 s3api list-buckets
```

**Check VPC and Networking**:

```powershell
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs
aws --endpoint-url=http://localhost:4566 ec2 describe-subnets
aws --endpoint-url=http://localhost:4566 ec2 describe-security-groups
```

## ☁️ AWS Production Deployment

### Prerequisites

-   AWS CLI configured with appropriate credentials
-   AWS account with necessary permissions
-   Terraform v1.6.0 or later

### AWS Setup

1. **Configure AWS Credentials**:

    ```powershell
    aws configure
    # Enter your AWS Access Key ID
    # Enter your AWS Secret Access Key
    # Enter your default region (e.g., us-east-1)
    # Enter your output format (json)
    ```

2. **Verify AWS Access**:
    ```powershell
    aws sts get-caller-identity
    aws ec2 describe-regions
    ```

### Switch to AWS Configuration

1. **Backup Current Configuration**:

    ```powershell
    cd terraform
    Copy-Item main.tf main-localstack.tf.backup
    ```

2. **Use AWS Configuration**:

    ```powershell
    Copy-Item backup/main-aws.tf main.tf -Force
    ```

3. **Update Variables** (if needed):
    ```powershell
    # Edit terraform.tfvars for AWS-specific values
    notepad terraform.tfvars
    ```

### AWS Deployment

1. **Initialize for AWS**:

    ```powershell
    terraform init
    ```

2. **Plan AWS Deployment**:

    ```powershell
    terraform plan
    ```

3. **Apply to AWS**:

    ```powershell
    terraform apply
    ```

4. **Verify AWS Resources**:

    ```powershell
    # Check EC2 instances
    aws ec2 describe-instances

    # Check S3 buckets
    aws s3 ls

    # Check VPC
    aws ec2 describe-vpcs
    ```

## 🔄 Environment Switching

### LocalStack → AWS

1. **Stop LocalStack**:

    ```powershell
    docker-compose down localstack
    ```

2. **Switch Configuration**:

    ```powershell
    cd terraform
    Copy-Item backup/main-aws.tf main.tf -Force
    ```

3. **Deploy to AWS**:
    ```powershell
    terraform init
    terraform plan
    terraform apply
    ```

### AWS → LocalStack

1. **Destroy AWS Resources** (if needed):

    ```powershell
    terraform destroy
    ```

2. **Switch Configuration**:

    ```powershell
    cd terraform
    Copy-Item backup/main-localstack.tf main.tf -Force
    ```

3. **Start LocalStack**:

    ```powershell
    docker-compose up localstack -d
    ```

4. **Deploy to LocalStack**:
    ```powershell
    terraform init
    terraform plan
    terraform apply
    ```

## 🎯 GitOps Deployment with Atlantis

### Prerequisites

-   GitHub repository configured
-   Atlantis running and accessible
-   GitHub webhook configured

### GitOps Workflow

1. **Create Feature Branch**:

    ```bash
    git checkout -b feature/new-resource
    ```

2. **Make Infrastructure Changes**:

    ```terraform
    # Edit Terraform files
    # Add new resources or modify existing ones
    ```

3. **Test Locally**:

    ```powershell
    cd terraform
    terraform plan
    ```

4. **Commit and Push**:

    ```bash
    git add .
    git commit -m "Add new infrastructure resource"
    git push origin feature/new-resource
    ```

5. **Create Pull Request**:

    - Go to GitHub repository
    - Create pull request from feature branch
    - Add description of changes

6. **Trigger Atlantis Plan**:

    ```bash
    # Comment in PR:
    atlantis plan -p terraform-atlantis-workshop
    ```

7. **Review Plan Output**:

    - Check for compliance violations
    - Review resource changes
    - Verify cost implications

8. **Apply Changes** (after approval):
    ```bash
    # Comment in PR:
    atlantis apply -p terraform-atlantis-workshop
    ```

### Compliance Validation in GitOps

**Automatic Validation**:

-   Atlantis automatically runs compliance checks
-   Violations are detected during plan phase
-   Clear error messages in PR comments

**Example Violation Response**:

```
❌ VIOLATION: Found expensive instance types. Only t3.micro, t3.small, t3.medium are permitted.
Current instances: policy_test=t3.small, test_violation=m5.large, web=t3.micro
```

**Fixing Violations**:

1. Update Terraform configuration
2. Commit and push changes
3. Re-run `atlantis plan`
4. Verify violations are resolved

## 🔧 Configuration Management

### Environment Variables

**LocalStack Environment**:

```powershell
$env:AWS_ACCESS_KEY_ID="test"
$env:AWS_SECRET_ACCESS_KEY="test"
$env:AWS_DEFAULT_REGION="us-east-1"
```

**AWS Environment**:

```powershell
# Use AWS CLI configuration
aws configure
```

### Terraform Variables

**Default Configuration** (`terraform.tfvars`):

```hcl
environment = "workshop"
project     = "terraform-atlantis-workshop"
region      = "us-east-1"
instance_type = "t3.micro"
vpc_cidr    = "10.0.0.0/16"
```

**Environment-Specific Overrides**:

```hcl
# terraform.tfvars.prod
environment = "production"
instance_type = "t3.small"
```

### Provider Configuration

**LocalStack Provider**:

```hcl
provider "aws" {
  region                      = var.region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}
```

**AWS Provider**:

```hcl
provider "aws" {
  region = var.region
}
```

## 📊 Deployment Verification

### Health Checks

**LocalStack Health**:

```powershell
curl "http://localhost:4566/_localstack/health"
```

**Terraform State**:

```powershell
terraform show
terraform output
```

**Resource Status**:

```powershell
# LocalStack
aws --endpoint-url=http://localhost:4566 ec2 describe-instances

# AWS
aws ec2 describe-instances
```

### Compliance Validation

**Check Compliance Status**:

```powershell
terraform output compliance_validation_status
```

**Test Validation Rules**:

```powershell
# Introduce violation for testing
# Edit terraform/test-policy-violations.tf
terraform plan  # Should fail with violation message
```

## 🛠️ Troubleshooting

### Common Deployment Issues

**LocalStack Issues**:

```powershell
# Service not responding
docker-compose restart localstack
curl "http://localhost:4566/_localstack/health"

# Clear LocalStack data
curl -X POST http://localhost:4566/_localstack/state/reset
```

**Terraform Issues**:

```powershell
# State lock errors
terraform force-unlock <lock-id>

# Provider errors
terraform init -upgrade

# Resource conflicts
terraform refresh
```

**AWS Issues**:

```powershell
# Credential errors
aws configure
aws sts get-caller-identity

# Permission errors
# Check IAM policies and roles
```

### Emergency Procedures

**Complete Reset**:

```powershell
# Stop all services
docker-compose down

# Clear data
docker volume rm terraform-atlantis-workshop-2_localstack-data 2>$null

# Restart fresh
docker-compose up -d
cd terraform
.\deploy.ps1
```

**State Recovery**:

```powershell
# Backup current state
cp terraform.tfstate terraform.tfstate.backup

# Import existing resources
terraform import aws_vpc.main vpc-xxxxxxxxx
terraform import aws_instance.web i-xxxxxxxxx
```

## 📚 Related Documentation

-   [Operational Procedures](OPERATIONS.md) - Day-to-day operations
-   [Compliance Validation](COMPLIANCE-VALIDATION.md) - Policy enforcement
-   [README.md](../readme.md) - Project overview
-   [Workshop Info](../workshop_info.md) - Workshop requirements

---

_This deployment guide provides comprehensive procedures for deploying infrastructure to both LocalStack and AWS environments with proper validation and compliance checks._
