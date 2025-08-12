# FAQ - Terraform Atlantis Workshop

## ❓ Frequently Asked Questions

This FAQ addresses common questions about the **Environment Provisioning Automation with Terraform and Atlantis** workshop.

## 🚀 Getting Started

### Q: What is this workshop about?

**A**: This workshop demonstrates **Environment Provisioning Automation** using Terraform and Atlantis with a focus on:

-   Automated infrastructure deployment to AWS
-   GitOps workflows with approval processes
-   Compliance validation and cost controls
-   Monitoring and operational procedures
-   Production-ready infrastructure automation

### Q: What are the prerequisites?

**A**: You need:

-   **AWS Account** with appropriate permissions
-   **PowerShell** (Windows) or equivalent shell
-   **Git** for version control
-   **AWS CLI** installed and configured
-   **Terraform** version 1.6.0 or later
-   **Docker** (optional, for Atlantis)

### Q: How long does it take to complete?

**A**:

-   **Quick Start**: 15 minutes for basic deployment
-   **Full Workshop**: 2-4 hours for complete implementation
-   **Production Setup**: 1-2 days for enterprise deployment

### Q: What will I learn?

**A**: You'll learn:

-   Infrastructure as Code with Terraform
-   GitOps workflows with Atlantis
-   AWS production infrastructure deployment
-   Compliance validation and policy enforcement
-   Cost optimization and monitoring
-   Operational procedures and troubleshooting

## 💰 Cost and Billing

### Q: How much does this cost?

**A**: Expected monthly costs (ap-southeast-1):

-   **EC2 Instances**: ~$15-20/month (t3.micro)
-   **S3 Storage**: ~$2-5/month (minimal usage)
-   **Data Transfer**: ~$1-3/month
-   **CloudWatch**: ~$1-2/month
-   **Total Estimated**: **$20-30/month**

### Q: How can I minimize costs?

**A**:

-   Use t3.micro instances for development
-   Enable S3 lifecycle policies
-   Monitor CloudWatch usage
-   Clean up unused resources
-   Use the provided cleanup scripts

### Q: Will I be charged for unused resources?

**A**: Yes, if you don't clean up resources. Always run:

```powershell
.\scripts\07-cleanup-infrastructure.ps1
```

## 🔧 Technical Questions

### Q: What AWS services are used?

**A**: The workshop uses:

-   **EC2**: Virtual servers
-   **VPC**: Virtual private cloud
-   **S3**: Object storage
-   **IAM**: Identity and access management
-   **CloudWatch**: Monitoring and logging
-   **Security Groups**: Network security

### Q: What is Atlantis?

**A**: Atlantis is a GitOps tool that:

-   Automates Terraform workflows
-   Integrates with GitHub pull requests
-   Provides approval workflows
-   Runs `terraform plan` and `apply` automatically
-   Posts results back to PR comments

### Q: What is compliance validation?

**A**: Compliance validation ensures:

-   Only cost-effective instance types (t3.micro, t3.small, t3.medium)
-   Required tags (Environment, Project, CostCenter)
-   S3 bucket naming conventions
-   Security best practices
-   Prevents deployment of non-compliant resources

### Q: Can I use a different cloud provider?

**A**: This workshop is designed for AWS, but the concepts apply to other providers. You would need to:

-   Modify Terraform configurations
-   Update provider configurations
-   Adjust compliance validation rules
-   Update monitoring scripts

## 🛠️ Setup and Configuration

### Q: How do I configure AWS credentials?

**A**:

```powershell
# Configure AWS CLI
aws configure

# Verify configuration
aws sts get-caller-identity
```

### Q: What permissions do I need?

**A**: You need permissions for:

-   EC2 (create, describe, terminate instances)
-   S3 (create, delete buckets)
-   IAM (create roles and policies)
-   VPC (create networks and security groups)
-   CloudWatch (create logs and metrics)

### Q: Can I use existing AWS resources?

**A**: Yes, but be careful:

-   The workshop creates new resources
-   Ensure no naming conflicts
-   Use different regions if needed
-   Review the Terraform plan before applying

### Q: How do I customize the configuration?

**A**: Edit `terraform/terraform.tfvars`:

```hcl
# Customize these values
instance_type = "t3.small"
instance_count = 3
environment = "development"
```

## 🔄 Workflow Questions

### Q: How does the GitOps workflow work?

**A**:

1. Create a feature branch
2. Make infrastructure changes
3. Create a pull request
4. Atlantis automatically runs `terraform plan`
5. Review the plan in PR comments
6. Approve and merge to trigger `terraform apply`

### Q: What if I don't want to use Atlantis?

**A**: You can use manual deployment:

```powershell
cd terraform
terraform plan
terraform apply
```

### Q: How do I rollback changes?

**A**:

```powershell
# Emergency rollback
.\scripts\06-rollback-procedures.ps1

# Or manual rollback
cd terraform
terraform destroy
```

### Q: How do I test compliance validation?

**A**:

```powershell
# Introduce violations for testing
# Edit terraform/test-policy-violations.tf
# Run: terraform plan
# See violation detection in action
```

## 🔍 Monitoring and Operations

### Q: How do I monitor the infrastructure?

**A**:

```powershell
# Health monitoring
.\scripts\04-health-monitoring.ps1

# Cost monitoring
.\scripts\05-cost-monitoring.ps1

# Manual checks
aws ec2 describe-instances
aws s3 ls
```

### Q: How do I access the web servers?

**A**:

```powershell
# Get public IP addresses
cd terraform
terraform output

# Test web server access
Invoke-WebRequest -Uri "http://<public-ip>"
```

### Q: How do I troubleshoot issues?

**A**:

1. Check [Troubleshooting Guide](troubleshooting-guide.md)
2. Review [FAQ](faq.md)
3. Check AWS CloudWatch logs
4. Verify Terraform state
5. Contact support if needed

### Q: How do I scale the infrastructure?

**A**:

-   Modify `instance_count` in terraform.tfvars
-   Use Auto Scaling Groups (ready for future use)
-   Add load balancers
-   Implement horizontal scaling

## 🔒 Security Questions

### Q: Is this secure for production?

**A**: The workshop implements security best practices:

-   VPC with public/private subnets
-   Security groups with minimal access
-   S3 encryption and versioning
-   IAM roles with least privilege
-   Compliance validation

### Q: How do I secure the Atlantis server?

**A**:

-   Use HTTPS with valid certificates
-   Implement authentication
-   Restrict access to authorized users
-   Monitor access logs
-   Use private subnets

### Q: Are the AWS credentials secure?

**A**:

-   Never commit credentials to Git
-   Use IAM roles when possible
-   Rotate access keys regularly
-   Use least privilege permissions
-   Monitor credential usage

### Q: How do I handle secrets?

**A**:

-   Use AWS Secrets Manager
-   Use environment variables
-   Use Terraform variables (not committed)
-   Implement proper access controls

## 📚 Learning and Development

### Q: Where can I learn more about Terraform?

**A**:

-   [Terraform Documentation](https://www.terraform.io/docs)
-   [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
-   [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Q: Where can I learn more about Atlantis?

**A**:

-   [Atlantis Documentation](https://www.runatlantis.io/docs)
-   [Atlantis GitHub Repository](https://github.com/runatlantis/atlantis)
-   [GitOps Best Practices](https://www.gitops.tech/)

### Q: How do I contribute to this workshop?

**A**:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Q: Can I use this in my organization?

**A**: Yes, but consider:

-   Customize for your environment
-   Review security requirements
-   Adjust compliance policies
-   Test in non-production first
-   Get proper approvals

## 🚨 Common Issues

### Q: Why does terraform init fail?

**A**: Common causes:

-   No internet connectivity
-   Invalid AWS credentials
-   Insufficient permissions
-   Corrupted Terraform cache

**Solution**:

```powershell
Remove-Item -Recurse -Force .terraform
terraform init
```

### Q: Why does terraform apply fail?

**A**: Common causes:

-   Insufficient AWS permissions
-   Resource limits exceeded
-   Invalid configuration
-   Network connectivity issues

**Solution**: Check [Troubleshooting Guide](troubleshooting-guide.md)

### Q: Why can't I access the web servers?

**A**: Common causes:

-   Security group blocking access
-   Instances not running
-   Network configuration issues
-   DNS resolution problems

**Solution**:

```powershell
# Check instance status
aws ec2 describe-instances

# Check security groups
aws ec2 describe-security-groups
```

### Q: Why is Atlantis not working?

**A**: Common causes:

-   Docker not running
-   Port conflicts
-   Webhook configuration issues
-   SSL certificate problems

**Solution**:

```powershell
# Check Docker status
docker ps

# Check port availability
netstat -an | findstr :4141
```

## 📞 Support

### Q: Where can I get help?

**A**:

-   **Documentation**: Check the docs folder
-   **Troubleshooting**: [Troubleshooting Guide](troubleshooting-guide.md)
-   **Issues**: Create GitHub issue
-   **Contact**: cbl.nguyennhatquang2809@gmail.com

### Q: How do I report a bug?

**A**:

1. Check if it's already reported
2. Create a new GitHub issue
3. Include detailed information:
    - Error messages
    - Steps to reproduce
    - Environment details
    - Expected vs actual behavior

### Q: How do I request a feature?

**A**:

1. Create a GitHub issue
2. Label it as "enhancement"
3. Describe the feature
4. Explain the use case
5. Provide implementation suggestions

### Q: Can I get training on this?

**A**:

-   Review all documentation
-   Practice with the examples
-   Join the community discussions
-   Consider formal training courses
-   Contact the author for custom training

## 🎯 Workshop Completion

### Q: How do I know I've completed the workshop?

**A**: You've completed the workshop when:

-   ✅ Infrastructure is deployed successfully
-   ✅ Compliance validation is working
-   ✅ Monitoring is configured
-   ✅ GitOps workflow is functional
-   ✅ You understand all concepts

### Q: What should I do after completing the workshop?

**A**:

1. **Practice**: Try different configurations
2. **Extend**: Add more resources and features
3. **Customize**: Adapt for your use cases
4. **Share**: Help others learn
5. **Contribute**: Improve the workshop

### Q: How do I clean up after the workshop?

**A**:

```powershell
# Clean up all resources
.\scripts\07-cleanup-infrastructure.ps1

# Verify cleanup
aws ec2 describe-instances
aws s3 ls
```

### Q: Can I keep the infrastructure running?

**A**: Yes, but remember:

-   You'll be charged for resources
-   Monitor costs regularly
-   Update security patches
-   Review compliance policies
-   Consider production requirements

---

**📚 Related Documentation**

-   [Quick Start Guide](quick-start-guide.md)
-   [Troubleshooting Guide](troubleshooting-guide.md)
-   [Deployment Procedures](deployment-procedures.md)
-   [Compliance Validation](compliance-validation.md)
