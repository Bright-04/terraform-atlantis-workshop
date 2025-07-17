# First Terraform Configuration - VPC and EC2 Setup

## Overview
This is your starting point for the workshop. We'll create a basic AWS infrastructure including:
- VPC with public and private subnets
- Internet Gateway
- Route tables
- Security groups
- EC2 instance

## Development Options

### Option 1: LocalStack (Cost-Free Development)
- **No AWS costs** during development
- **Fast iteration** and testing
- **Perfect for learning** Terraform basics
- Use `main-localstack.tf` configuration

### Option 2: AWS (Production Testing)
- **Real AWS environment** for final testing
- **AWS Free Tier** resources
- **Production-ready** deployment
- Use `main-aws.tf` configuration

## Prerequisites

### For LocalStack:
- Docker Desktop installed
- LocalStack CLI installed
- Basic understanding of containers

### For AWS:
- AWS CLI configured
- Terraform installed
- Appropriate IAM permissions

## Files Structure
```
terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── versions.tf         # Provider versions
└── terraform.tfvars.example  # Example variables file
```

## Getting Started

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Edit `terraform.tfvars` with your specific values
3. Run Terraform commands:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Quick Start with LocalStack

### 1. Start LocalStack
```powershell
# Navigate to workshop root
cd "d:\IT WORKSHOP"

# Start LocalStack services
docker-compose up -d

# Verify LocalStack is running
curl http://localhost:4566/health
```

### 2. Use LocalStack Configuration
```powershell
# Navigate to terraform directory
cd terraform

# Use LocalStack configuration
Copy-Item main-localstack.tf main.tf -Force

# Copy example variables
Copy-Item terraform.tfvars.example terraform.tfvars

# Initialize and apply
terraform init
terraform plan
terraform apply
```

### 3. Test Your Infrastructure
```powershell
# Set LocalStack environment
$env:AWS_ACCESS_KEY_ID="test"
$env:AWS_SECRET_ACCESS_KEY="test"
$env:AWS_DEFAULT_REGION="us-east-1"

# Install awslocal for testing
pip install awscli-local

# Test resources
awslocal ec2 describe-instances
awslocal s3 ls
```

## Switching to AWS Later

### When Ready for AWS:
```powershell
# Use AWS configuration
Copy-Item main-aws.tf main.tf -Force

# Configure real AWS credentials
aws configure

# Deploy to AWS
terraform init
terraform plan
terraform apply
```

## Next Steps
After successfully deploying this basic infrastructure:
1. Set up S3 backend for state management
2. Implement Terraform modules
3. Add more complex resources
4. Integrate with Atlantis for approval workflows

## Important Notes
- Never commit `.tfvars` files with sensitive data
- Always review `terraform plan` before applying
- Use consistent naming conventions
- Tag all resources appropriately
