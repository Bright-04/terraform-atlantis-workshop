# LocalStack Development Guide

## Quick Start with LocalStack

### 1. Install Prerequisites
```powershell
# Install Docker Desktop
choco install docker-desktop

# Install Python and pip (if not already installed)
choco install python

# Install LocalStack
pip install localstack

# Install AWS CLI (for testing)
pip install awscli-local
```

### 2. Start LocalStack
```powershell
# Option 1: Using Docker Compose (Recommended)
docker-compose up -d

# Option 2: Using LocalStack CLI
localstack start -d

# Verify LocalStack is running
curl http://localhost:4566/health
```

### 3. Test LocalStack Setup
```powershell
# Set environment variables for LocalStack
$env:AWS_ACCESS_KEY_ID="test"
$env:AWS_SECRET_ACCESS_KEY="test"
$env:AWS_DEFAULT_REGION="us-east-1"

# Test with awslocal (LocalStack AWS CLI)
awslocal s3 mb s3://test-bucket
awslocal s3 ls
```

### 4. Use LocalStack Configuration
```powershell
# Navigate to terraform directory
cd terraform

# Use LocalStack configuration
Copy-Item main-localstack.tf main.tf -Force

# Initialize and apply
terraform init
terraform plan
terraform apply
```

### 5. Verify Resources
```powershell
# Check created resources
awslocal ec2 describe-instances
awslocal s3 ls
awslocal ec2 describe-vpcs
```

## LocalStack vs AWS Comparison

### LocalStack Advantages:
- ✅ **Zero costs** - No AWS charges
- ✅ **Fast iteration** - No internet latency
- ✅ **Offline development** - Works without internet
- ✅ **Reset anytime** - Clean slate with restart
- ✅ **Safe experimentation** - No production impact

### LocalStack Limitations:
- ❌ **Not all services** - Limited AWS service support
- ❌ **Simplified behavior** - Some features may differ
- ❌ **No real networking** - Simulated networking only
- ❌ **Performance differences** - May not match AWS exactly

## Development Workflow

### Phase 1: LocalStack Development (Days 1-6)
1. **Develop and test** Terraform configurations
2. **Debug issues** quickly and cheaply
3. **Learn Terraform** without cost concerns
4. **Iterate rapidly** on infrastructure design

### Phase 2: AWS Deployment (Days 7-13)
1. **Switch to AWS** for production testing
2. **Use AWS Free Tier** resources
3. **Test real-world scenarios**
4. **Implement monitoring and cost controls**

## Switching Between LocalStack and AWS

### For LocalStack:
```powershell
# Use LocalStack main.tf
Copy-Item main-localstack.tf main.tf -Force

# Start LocalStack
docker-compose up -d

# Deploy
terraform init
terraform apply
```

### For AWS:
```powershell
# Use AWS main.tf
Copy-Item main-aws.tf main.tf -Force

# Configure AWS credentials
aws configure

# Deploy
terraform init
terraform apply
```

## Troubleshooting LocalStack

### Common Issues:
1. **Port conflicts** - Ensure port 4566 is available
2. **Docker issues** - Restart Docker Desktop
3. **Permission errors** - Run as administrator
4. **Service not supported** - Check LocalStack documentation

### Debug Commands:
```powershell
# Check LocalStack logs
docker-compose logs localstack

# Check running services
curl http://localhost:4566/health

# Restart LocalStack
docker-compose restart localstack
```

## Cost Savings Calculation

### LocalStack Development:
- **Development time**: 6 days
- **AWS costs**: $0
- **Learning iterations**: Unlimited

### AWS Production Testing:
- **Testing time**: 7 days
- **Estimated costs**: $10-20 (using Free Tier)
- **Total savings**: ~$100-200

## Best Practices

1. **Start with LocalStack** for development
2. **Use consistent configurations** between LocalStack and AWS
3. **Test thoroughly** in LocalStack before AWS
4. **Keep both configurations** for easy switching
5. **Document differences** you encounter

This approach allows you to complete 80% of your workshop development cost-free while still gaining real AWS experience in the final phase!
