# Terraform Atlantis Workshop

## Overview

This workshop demonstrates **Environment Provisioning Automation** using Terraform and Atlantis with a focus on approval workflows, cost controls, monitoring integration, and **compliance validation**. The project is designed for real AWS production infrastructure deployment.

### Workshop Objectives

-   ✅ Implement automated environment provisioning with Terraform
-   ✅ Set up approval workflows using Atlantis
-   ✅ Integrate cost controls and monitoring
-   ✅ **Establish compliance validation and rollback procedures**
-   ✅ Create comprehensive operational documentation

## Technologies Used

### Core Infrastructure

-   **Terraform (v1.6.0)** - Infrastructure as Code
-   **AWS Provider (~5.100)** - Cloud resources management
-   **AWS Production Environment** - Real cloud infrastructure
-   **Docker & Docker Compose** - Container orchestration

### Development Tools

-   **PowerShell** - Automation scripts
-   **Git** - Version control
-   **VS Code** - Development environment

### Integration

-   **Atlantis** - GitOps workflow automation
-   **Terraform Validation Blocks** - Native compliance validation
-   **GitHub PR Integration** - Pull request-based workflows

## Current Status

### ✅ **PRODUCTION READY** - All Workshop Requirements Complete

-   [x] **AWS Production Environment** ⭐ **NEW**

    -   **AWS Production Infrastructure**: Complete AWS deployment configuration
    -   Real EC2 instances with Apache web server
    -   Production VPC with enhanced security
    -   Encrypted S3 buckets with public access blocking
    -   CloudWatch logging and monitoring
    -   IAM roles and policies for secure access
    -   Enhanced security groups and compliance
    -   Cost estimation and optimization
    -   Production deployment scripts and procedures

-   [x] **Atlantis Integration**

    -   Complete Atlantis server configuration in Docker Compose
    -   GitHub integration setup with webhook support
    -   Approval workflow definitions in atlantis.yaml
    -   Environment-based configuration
    -   PowerShell script for GitHub integration setup
    -   Terraform v1.6.0 integration with AWS Production

-   [x] **Compliance Validation System** ⭐ **NEW**

    -   **Native Terraform validation blocks** using `lifecycle.precondition`
    -   **Instance type validation** - Only allows t3.micro, t3.small, t3.medium
    -   **Required tags validation** - Ensures Environment, Project, CostCenter tags
    -   **S3 bucket naming validation** - Enforces terraform-atlantis-workshop-\* convention
    -   **Real-time violation detection** during `terraform plan`
    -   **Clear error messages** in GitHub PR comments
    -   **Prevents deployment** when violations are detected
    -   **Works with real AWS production infrastructure**

-   [x] **Cost Controls & Monitoring**

    -   Resource tagging strategy implemented
    -   Cost-effective instance types (t3.micro, t3.small, t3.medium)
    -   S3 bucket versioning and lifecycle policies
    -   Security group restrictions and best practices
    -   Monitoring-ready infrastructure structure

-   [x] **Operational Procedures**
    -   Rollback procedures documented and scripted
    -   Comprehensive documentation and examples
    -   PowerShell automation scripts
    -   GitHub integration automation
    -   Clean workspace management

### 🎯 **PRODUCTION READY INFRASTRUCTURE**

**Environment**: AWS Production Infrastructure - Ready for Deployment

**AWS Production Infrastructure**:

-   **Real EC2 Instances**: Amazon Linux 2 with Apache web server
-   **Production VPC**: Multi-AZ networking with enhanced security
-   **Encrypted S3 Buckets**: AES256 encryption with public access blocking
-   **CloudWatch Logging**: Centralized log management with retention policies
-   **IAM Roles**: Secure access management for EC2 instances
-   **Enhanced Security**: Production-ready security groups and compliance
-   **Compliance Validation**: Active and preventing violations

**🚀 Production Deployment Ready**:

**AWS Production**:

-   Real AWS infrastructure ready for production deployment (~$20-30/month)
-   Live web servers accessible via public IP addresses
-   Production-grade security and compliance features
-   CloudWatch monitoring and logging
-   Enterprise-ready infrastructure for production workloads - **DEPLOYMENT READY**

### 🎉 Workshop Requirements Status

| Requirement                    | Status       | Implementation                  | Working |
| ------------------------------ | ------------ | ------------------------------- | ------- |
| ✅ **Provisioning Automation** | COMPLETE     | Terraform + AWS Production      | ✅      |
| ✅ **Approval Workflows**      | COMPLETE     | GitHub PR + Atlantis            | ✅      |
| ✅ **Cost Controls**           | COMPLETE     | Instance types, tags, naming    | ✅      |
| ✅ **Monitoring Integration**  | COMPLETE     | Validation results integrated   | ✅      |
| ✅ **Compliance Validation**   | **COMPLETE** | **Terraform validation blocks** | ✅      |
| ✅ **Rollback Procedures**     | COMPLETE     | Scripts and procedures          | ✅      |
| ✅ **Operational Procedures**  | COMPLETE     | Complete runbook                | ✅      |
| ✅ **Documentation**           | COMPLETE     | Comprehensive docs              | ✅      |

## Project Structure

```
terraform-atlantis-workshop/
├── atlantis.yaml                   # Atlantis workflow configuration
├── setup-github-integration.ps1    # GitHub integration setup script
├── workshop_info.md                # Workshop requirements and objectives
├── terraform/
│   ├── main.tf                     # Main Terraform configuration (AWS Production)
│   ├── variables.tf                # Variable definitions
│   ├── outputs.tf                  # Output values
│   ├── versions.tf                 # Provider requirements
│   ├── compliance-validation.tf    # ⭐ Compliance validation rules
│   ├── test-policy-violations.tf   # Test resources for validation
│   ├── terraform.tfvars.example    # Example variables
│   ├── deploy-aws.ps1              # ⭐ AWS production deployment script
│   └── destroy.ps1                 # Cleanup script
├── policies/                       # Policy files (for reference)
├── scripts/
│   └── rollback.ps1               # Rollback functionality
├── monitoring/                     # Monitoring configuration
│   └── health-check-aws.ps1       # ⭐ AWS production health check
├── docs/                          # Documentation
│   ├── 1.OPERATIONS.md            # Operational procedures
│   ├── 2.COMPLIANCE-VALIDATION.md # Compliance validation
│   ├── 3.DEPLOYMENT-GUIDE.md      # Deployment procedures
│   ├── 4.TESTING-GUIDE.md         # Testing procedures
│   └── 5.AWS-PRODUCTION-GUIDE.md  # ⭐ AWS production guide
└── aws-production-data/           # AWS production data
```

## 🚀 **Production Deployment**

### Prerequisites

**For AWS Production Deployment:**

-   AWS CLI installed and configured
-   AWS account with appropriate permissions
-   PowerShell (Windows) or equivalent shell
-   Git for version control
-   GitHub account (for Atlantis integration)

### Quick Production Deployment

**AWS Production Deployment:**

1. **Clone and Navigate**

    ```powershell
    git clone <repository-url>
    cd terraform-atlantis-workshop
    ```

2. **Configure AWS Credentials**

    ```powershell
    aws configure
    ```

3. **Deploy to Production**

    ```powershell
    # Run the complete workshop workflow
    .\scripts\00-complete-workflow.ps1

    # Or run individual steps
    .\scripts\01-validate-environment.ps1
    .\scripts\02-setup-github-actions.ps1
    .\scripts\03-deploy-infrastructure.ps1
    ```

4. **Verify Production Deployment**
    ```powershell
    .\scripts\04-health-monitoring.ps1
    ```

### Atlantis GitOps Workflow

1. **Configure GitHub Integration**

    ```powershell
    .\scripts\02-setup-github-actions.ps1
    ```

2. **Start Atlantis (Manual Setup)**

    ```powershell
    # Install Atlantis manually or use Docker
    # Follow the setup-github-integration.ps1 instructions
    ```

3. **Access Atlantis UI**

    ```
    https://your-domain:4141
    ```

4. **Test Compliance Validation**
    ```bash
    # In your GitHub PR, comment:
    atlantis plan -p terraform-atlantis-workshop
    ```

## Compliance Validation System ⭐

### How It Works

The compliance validation system uses **native Terraform validation blocks** as the primary validation mechanism to enforce:

**Note**: While OPA (Open Policy Agent) `.rego` policy files are included for reference and future integration, the current implementation primarily uses Terraform's native `lifecycle.precondition` blocks for real-time validation during the `terraform plan` phase.

1. **Instance Type Restrictions**

    - Only allows: t3.micro, t3.small, t3.medium
    - Prevents expensive instance types

2. **Required Tags**

    - Environment, Project, CostCenter tags required
    - Ensures proper resource labeling

3. **S3 Bucket Naming**
    - Must follow: terraform-atlantis-workshop-\* convention
    - Enforces consistent naming strategy

### Example Violations

When violations are detected, you'll see clear error messages:

```
❌ VIOLATION: Found expensive instance types. Only t3.micro, t3.small, t3.medium are permitted.
Current instances: policy_test=t3.small, test_violation=m5.large, web=t3.micro
```

```
❌ VIOLATION: S3 buckets must follow naming convention: terraform-atlantis-workshop-*.
Current buckets: [violating bucket names]
```

### Testing Compliance Validation

#### Test Resources Status

The workshop includes test resources specifically designed for compliance validation testing:

-   **Active Test Resources**: Located in `terraform/main-aws.tf`

    -   `aws_instance.test_violation` - Tests instance type and tag violations
    -   `aws_s3_bucket.test_violation` - Tests S3 naming and security violations
    -   `aws_security_group.test_violation` - Tests security group policy violations

-   **Commented Test Resources**: Located in `terraform/test-policy-violations.tf`
    -   These are example violations for educational purposes
    -   Uncomment specific resources to test different violation scenarios
    -   **Warning**: These resources will cause plan failures when uncommented

#### Testing Process

1. **Test with Active Resources** (Recommended):

    ```bash
    # Run terraform plan to see current validation status
    terraform plan
    ```

2. **Test with Commented Resources** (Educational):

    ```terraform
    # In terraform/test-policy-violations.tf
    # Uncomment and modify specific resources:
    resource "aws_instance" "test_violation" {
      instance_type = "m5.large"  # VIOLATION: Expensive instance
    }
    ```

3. **Run Plan**:

    ```bash
    atlantis plan -p terraform-atlantis-workshop
    ```

4. **See Violations** in GitHub PR comments

5. **Fix Violations** and re-run plan

## Key Features

### GitOps Workflow with Atlantis

-   **Pull Request-Based Infrastructure Changes**: All changes through PR workflow
-   **Automated Plan Generation**: Atlantis automatically runs `terraform plan`
-   **Compliance Validation**: Real-time violation detection and prevention
-   **Approval Requirements**: Configurable approval workflows before apply
-   **GitHub Integration**: Seamless integration with GitHub webhooks
-   **Audit Trail**: Complete history of infrastructure changes

### Compliance Validation

-   **Native Terraform Validation**: Uses `lifecycle.precondition` blocks
-   **Real-Time Detection**: Violations caught during plan phase
-   **Clear Error Messages**: Specific violation details in PR comments
-   **Prevention**: Stops deployment when violations exist
-   **AWS Production Focus**: Optimized for real AWS infrastructure

### Production-Ready Infrastructure

-   **AWS Production Environment**: Real cloud infrastructure deployment
-   **Enhanced Security**: Production-grade security and compliance
-   **Resource Optimization**: Efficient resource allocation and cost control
-   **Monitoring Integration**: CloudWatch logging and monitoring

### Infrastructure as Code

-   **Terraform Best Practices**: Modular, reusable configurations
-   **Version Control**: All infrastructure changes tracked
-   **Automated Deployment**: PowerShell and Atlantis-based deployment
-   **State Management**: Proper state file handling and backup

### Security & Compliance

-   **Security Groups**: Properly configured network access
-   **Resource Tagging**: Consistent labeling strategy
-   **Environment Separation**: Isolated development/production
-   **Approval Workflows**: Controlled infrastructure changes
-   **Compliance Validation**: Automated policy enforcement

## Configuration

The project uses the following default configuration:

-   **VPC CIDR**: 10.0.0.0/16
-   **Public Subnet**: 10.0.1.0/24
-   **Private Subnet**: 10.0.2.0/24
-   **Instance Type**: t3.micro (compliant)
-   **Region**: ap-southeast-1
-   **Allowed Instance Types**: t3.micro, t3.small, t3.medium
-   **Required Tags**: Environment, Project, CostCenter
-   **S3 Naming Convention**: terraform-atlantis-workshop-\*

Customize these values in `terraform.tfvars` or through environment variables.

## Troubleshooting

### Common Issues

**AWS Issues:**

-   **AWS credentials not configured**: Run `aws configure`
-   **Insufficient permissions**: Ensure IAM roles have required permissions
-   **Region configuration**: Verify AWS region is set correctly

**Atlantis Issues:**

-   **Atlantis not accessible**: Check port 4141 is available
-   **GitHub webhook errors**: Verify webhook configuration
-   **Permission errors**: Ensure GitHub token has proper permissions

**Compliance Validation Issues:**

-   **Violations not detected**: Check `compliance-validation.tf` is included
-   **False positives**: Verify resource configurations match validation rules
-   **Plan failures**: Fix violations before applying

### Service Management

**Check AWS Status:**

```powershell
# Check AWS credentials and region
aws sts get-caller-identity
aws configure get region

# Check infrastructure health
.\monitoring\health-check-aws.ps1
```

**Restart Services:**

```powershell
# Restart Atlantis (if using Docker)
docker-compose restart atlantis

# Check AWS infrastructure
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
```

### Cleanup

```powershell
# Destroy infrastructure
cd terraform
.\destroy.ps1

# Verify cleanup
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
```

## Next Steps

1. **Test Compliance Validation**

    - Introduce violations and verify detection
    - Test with different resource types
    - Validate error message clarity

2. **Enhance Validation Rules**

    - Add more compliance checks
    - Implement custom validation logic
    - Add security group validation

3. **Production Deployment**

    - Configure real AWS credentials
    - Deploy to production environment
    - Set up monitoring and alerting

4. **Advanced Features**
    - Multi-environment workflows
    - Automated testing with terratest
    - Disaster recovery procedures

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with AWS Production
5. Ensure compliance validation passes
6. Submit a pull request

## Author

**Nguyen Nhat Quang (Bright-04)**

-   Email: cbl.nguyennhatquang2809@gmail.com
-   Repository: terraform-atlantis-workshop
-   Program: First Cloud Journey 2025, Amazon Web Service Vietnam
-   Focus: Environment Provisioning Automation with Terraform and Atlantis

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

_This project demonstrates a complete infrastructure automation solution with compliance validation, GitOps workflows, and cost optimization strategies._
