# Terraform Atlantis Workshop

## Overview

This workshop demonstrates **Environment Provisioning Automation** using Terraform and Atlantis with a focus on approval workflows, cost controls, monitoring integration, and **compliance validation**. The project is designed to work with both LocalStack (for cost-free development) and real AWS infrastructure.

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
-   **LocalStack** - Local AWS cloud stack for development
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

### ✅ Completed

-   [x] **LocalStack Development Environment**

    -   **LIVE LocalStack Infrastructure**: Successfully deployed to LocalStack simulation
    -   Docker Compose configuration with LocalStack and Atlantis
    -   VPC with public/private subnets (10.0.0.0/16)
    -   Internet Gateway and route tables
    -   Security groups for web servers (HTTP, HTTPS, SSH)
    -   EC2 instances running Amazon Linux 2
    -   S3 buckets with versioning and encryption
    -   Complete variable definitions and validation
    -   Output values for resource references

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
    -   Terraform v1.6.0 integration with LocalStack

-   [x] **Compliance Validation System** ⭐ **NEW**

    -   **Native Terraform validation blocks** using `lifecycle.precondition`
    -   **Instance type validation** - Only allows t3.micro, t3.small, t3.medium
    -   **Required tags validation** - Ensures Environment, Project, CostCenter tags
    -   **S3 bucket naming validation** - Enforces terraform-atlantis-workshop-\* convention
    -   **Real-time violation detection** during `terraform plan`
    -   **Clear error messages** in GitHub PR comments
    -   **Prevents deployment** when violations are detected
    -   **Works with both LocalStack and real AWS**

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

### 🎯 Current Live Infrastructure

**Environment**: LocalStack Development (localhost:4566) + AWS Production Ready

**LocalStack Development**:
-   **VPC**: vpc-xxxxxxxxxxxxxxxx (10.0.0.0/16)
-   **Public Subnet**: subnet-xxxxxxxxxxxxxxxx (10.0.1.0/24)
-   **Private Subnet**: subnet-xxxxxxxxxxxxxxxx (10.0.2.0/24)
-   **EC2 Instances**: Multiple t3.micro instances with proper tagging
-   **S3 Buckets**: Multiple buckets with versioning and proper naming
-   **Security Groups**: Properly configured with restricted access
-   **Compliance Validation**: Active and preventing violations

**AWS Production Ready**:
-   **Real EC2 Instances**: Amazon Linux 2 with Apache web server
-   **Production VPC**: Multi-AZ networking with enhanced security
-   **Encrypted S3 Buckets**: AES256 encryption with public access blocking
-   **CloudWatch Logging**: Centralized log management with retention policies
-   **IAM Roles**: Secure access management for EC2 instances
-   **Enhanced Security**: Production-ready security groups and compliance

**⚠️ Environment Notes**:

**LocalStack Simulation**:
-   All resources are running on LocalStack with realistic AWS-like resource IDs
-   The EC2 instances are simulated - no actual web servers are running
-   Network connectivity is simulated - external URLs won't be accessible
-   S3 bucket operations work through LocalStack endpoint (localhost:4566)
-   Perfect for development, testing, and cost-free experimentation

**AWS Production**:
-   Real AWS infrastructure with actual costs (~$20-30/month)
-   Live web servers accessible via public IP addresses
-   Production-grade security and compliance features
-   CloudWatch monitoring and logging
-   Enterprise-ready infrastructure for production workloads

### 🎉 Workshop Requirements Status

| Requirement                    | Status       | Implementation                  | Working |
| ------------------------------ | ------------ | ------------------------------- | ------- |
| ✅ **Provisioning Automation** | COMPLETE     | Terraform + LocalStack          | ✅      |
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
├── docker-compose.yml              # LocalStack and Atlantis containers
├── Dockerfile.atlantis             # Custom Atlantis Docker image
├── setup-github-integration.ps1    # GitHub integration setup script
├── workshop_info.md                # Workshop requirements and objectives
├── terraform/
│   ├── main.tf                     # Main Terraform configuration (LocalStack)
│   ├── main-aws.tf                 # ⭐ AWS production configuration
│   ├── variables.tf                # Variable definitions
│   ├── outputs.tf                  # Output values
│   ├── versions.tf                 # Provider requirements
│   ├── compliance-validation.tf    # ⭐ Compliance validation rules
│   ├── test-policy-violations.tf   # Test resources for validation
│   ├── terraform.tfvars.example    # Example variables
│   ├── deploy.ps1                  # LocalStack deployment script
│   ├── deploy-aws.ps1              # ⭐ AWS production deployment script
│   └── destroy.ps1                 # Cleanup script
├── policies/                       # Policy files (for reference)
├── scripts/
│   └── rollback.ps1               # Rollback functionality
├── monitoring/                     # Monitoring configuration
│   ├── health-check.ps1           # LocalStack health check
│   └── health-check-aws.ps1       # ⭐ AWS production health check
├── docs/                          # Documentation
│   ├── 1.OPERATIONS.md            # Operational procedures
│   ├── 2.COMPLIANCE-VALIDATION.md # Compliance validation
│   ├── 3.DEPLOYMENT-GUIDE.md      # Deployment procedures
│   ├── 4.TESTING-GUIDE.md         # Testing procedures
│   └── 5.AWS-PRODUCTION-GUIDE.md  # ⭐ AWS production guide
└── localstack-data/               # LocalStack persistence data
```

## Getting Started

### Prerequisites

**For LocalStack Development:**
-   Docker Desktop installed and running
-   PowerShell (Windows) or equivalent shell
-   Git for version control
-   GitHub account (for Atlantis integration)

**For AWS Production:**
-   AWS CLI installed and configured
-   AWS account with appropriate permissions
-   PowerShell (Windows) or equivalent shell
-   Git for version control

### Quick Start

**LocalStack Development:**

1. **Clone and Navigate**
    ```powershell
    git clone <repository-url>
    cd terraform-atlantis-workshop
    ```

2. **Start LocalStack**
    ```powershell
    docker-compose up localstack -d
    ```

3. **Deploy Infrastructure**
    ```powershell
    cd terraform
    .\deploy.ps1
    ```

4. **Verify Deployment**
    ```powershell
    terraform output
    aws --endpoint-url=http://localhost:4566 ec2 describe-instances
    ```

**AWS Production:**

1. **Configure AWS Credentials**
    ```powershell
    aws configure
    ```

2. **Deploy to AWS**
    ```powershell
    cd terraform
    .\deploy-aws.ps1
    ```

3. **Verify AWS Deployment**
    ```powershell
    .\monitoring\health-check-aws.ps1
    ```

### Atlantis GitOps Workflow

1. **Configure GitHub Integration**

    ```powershell
    .\setup-github-integration.ps1
    ```

2. **Start Atlantis**

    ```powershell
    docker-compose up atlantis -d
    ```

3. **Access Atlantis UI**

    ```
    http://localhost:4141
    ```

4. **Test Compliance Validation**
    ```bash
    # In your GitHub PR, comment:
    atlantis plan -p terraform-atlantis-workshop
    ```

## Compliance Validation System ⭐

### How It Works

The compliance validation system uses **native Terraform validation blocks** to enforce:

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

1. **Introduce Violations** (for testing):

    ```terraform
    # In terraform/test-policy-violations.tf
    resource "aws_instance" "test_violation" {
      instance_type = "m5.large"  # VIOLATION: Expensive instance
    }
    ```

2. **Run Plan**:

    ```bash
    atlantis plan -p terraform-atlantis-workshop
    ```

3. **See Violations** in GitHub PR comments

4. **Fix Violations** and re-run plan

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
-   **Environment Agnostic**: Works with LocalStack and real AWS

### Cost-Effective Development

-   **LocalStack Integration**: Develop and test without AWS costs
-   **Container-Based Setup**: Quick environment provisioning
-   **Resource Optimization**: Efficient resource allocation
-   **Environment Isolation**: Separate development and production

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
-   **Region**: us-east-1
-   **Allowed Instance Types**: t3.micro, t3.small, t3.medium
-   **Required Tags**: Environment, Project, CostCenter
-   **S3 Naming Convention**: terraform-atlantis-workshop-\*

Customize these values in `terraform.tfvars` or through environment variables.

## Troubleshooting

### Common Issues

**LocalStack Issues:**

-   **LocalStack not starting**: Check Docker Desktop is running
-   **Port conflicts**: Ensure ports 4566 and 4510-4559 are available
-   **Service timeouts**: Wait for LocalStack health check to pass

**Atlantis Issues:**

-   **Atlantis not accessible**: Check port 4141 is available
-   **GitHub webhook errors**: Verify webhook configuration
-   **Permission errors**: Ensure GitHub token has proper permissions

**Compliance Validation Issues:**

-   **Violations not detected**: Check `compliance-validation.tf` is included
-   **False positives**: Verify resource configurations match validation rules
-   **Plan failures**: Fix violations before applying

### Service Management

**Check Service Status:**

```powershell
# Check all services
docker-compose ps

# Check specific service logs
docker-compose logs localstack
docker-compose logs atlantis
```

**Restart Services:**

```powershell
# Restart specific service
docker-compose restart localstack
docker-compose restart atlantis

# Restart all services
docker-compose restart
```

### Cleanup

```powershell
# Destroy infrastructure
cd terraform
.\destroy.ps1

# Stop all services
docker-compose down

# Remove volumes and networks (complete cleanup)
docker-compose down -v --remove-orphans
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
4. Test with LocalStack
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
