# Terraform Atlantis Workshop

A comprehensive workshop demonstrating **Environment Provisioning Automation** using Terraform and Atlantis with production-ready AWS infrastructure, approval workflows, cost controls, monitoring integration, and compliance validation.

## 🎯 Overview

This workshop provides a complete solution for automated infrastructure provisioning with enterprise-grade features including:

-   **Automated Environment Provisioning** with Terraform
-   **GitOps Workflow Automation** using Atlantis
-   **Compliance Validation** with real-time policy enforcement
-   **Cost Controls** and resource optimization
-   **Production-Ready AWS Infrastructure** deployment
-   **Comprehensive Operational Procedures** and documentation

## 🏗️ Architecture

### Core Technologies

| Component                  | Technology              | Version | Purpose                   |
| -------------------------- | ----------------------- | ------- | ------------------------- |
| **Infrastructure as Code** | Terraform               | v1.6.0  | AWS resource provisioning |
| **Cloud Provider**         | AWS                     | ~5.100  | Production infrastructure |
| **GitOps Platform**        | Atlantis                | Latest  | Workflow automation       |
| **Containerization**       | Docker & Docker Compose | Latest  | Service orchestration     |
| **Automation**             | PowerShell              | 7.0+    | Script automation         |
| **Version Control**        | Git                     | Latest  | Code management           |

### Integration Stack

-   **GitHub PR Integration** - Pull request-based workflows
-   **Terraform Validation Blocks** - Native compliance validation
-   **CloudWatch Monitoring** - Infrastructure monitoring
-   **IAM Security** - Role-based access control

## ✅ Project Status

### **PRODUCTION READY** - All Requirements Complete

| Feature                        | Status   | Implementation                | Status |
| ------------------------------ | -------- | ----------------------------- | ------ |
| ✅ **Provisioning Automation** | COMPLETE | Terraform + AWS Production    | ✅     |
| ✅ **Approval Workflows**      | COMPLETE | GitHub PR + Atlantis          | ✅     |
| ✅ **Cost Controls**           | COMPLETE | Instance types, tags, naming  | ✅     |
| ✅ **Monitoring Integration**  | COMPLETE | Validation results integrated | ✅     |
| ✅ **Compliance Validation**   | COMPLETE | Terraform validation blocks   | ✅     |
| ✅ **Rollback Procedures**     | COMPLETE | Scripts and procedures        | ✅     |
| ✅ **Operational Procedures**  | COMPLETE | Complete runbook              | ✅     |
| ✅ **Documentation**           | COMPLETE | Comprehensive docs            | ✅     |

### 🚀 Production Infrastructure

**AWS Production Environment** - Ready for Deployment:

-   **Real EC2 Instances**: Amazon Linux 2 with Apache web server
-   **Production VPC**: Multi-AZ networking with enhanced security
-   **Encrypted S3 Buckets**: AES256 encryption with public access blocking
-   **CloudWatch Logging**: Centralized log management with retention policies
-   **IAM Roles**: Secure access management for EC2 instances
-   **Enhanced Security**: Production-ready security groups and compliance
-   **Compliance Validation**: Active and preventing violations

**Estimated Cost**: ~$20-30/month for production deployment

## 📁 Project Structure

```
terraform-atlantis-workshop/
├── atlantis.yaml                   # Atlantis workflow configuration
├── docker-compose.yml              # Container orchestration
├── terraform/
│   ├── main-aws.tf                 # Main Terraform configuration
│   ├── variables.tf                # Variable definitions
│   ├── outputs.tf                  # Output values
│   ├── versions.tf                 # Provider requirements
│   ├── compliance-validation.tf    # Compliance validation rules
│   ├── test-policy-violations.tf   # Test resources for validation
│   ├── terraform.tfvars.example    # Example variables
│   └── user_data.sh                # EC2 user data script
├── policies/                       # OPA policy files
│   ├── cost_control.rego          # Cost control policies
│   └── terraform_security.rego    # Security policies
├── scripts/                        # Automation scripts
│   ├── 00-setup-env.ps1           # Environment setup
│   ├── 01-validate-environment.ps1 # Environment validation
│   ├── 02-setup-github-actions.ps1 # GitHub integration
│   ├── 03-deploy-infrastructure.ps1 # Infrastructure deployment
│   ├── 04-health-monitoring.ps1   # Health monitoring
│   ├── 05-cost-monitoring.ps1     # Cost monitoring
│   ├── 06-rollback-procedures.ps1 # Rollback procedures
│   ├── 07-cleanup-infrastructure.ps1 # Cleanup procedures
│   └── 08-complete-workflow.ps1   # Complete workflow
├── monitoring/                     # Monitoring configuration
├── docs/                          # Comprehensive documentation
│   ├── api-reference.md           # API documentation
│   ├── architecture-overview.md   # Architecture details
│   ├── atlantis-gitops.md         # GitOps workflow guide
│   ├── aws-production-setup.md    # AWS production setup
│   ├── best-practices.md          # Best practices guide
│   ├── compliance-validation.md   # Compliance validation guide
│   ├── configuration-reference.md # Configuration reference
│   ├── cost-management.md         # Cost management guide
│   ├── deployment-procedures.md   # Deployment procedures
│   ├── faq.md                     # Frequently asked questions
│   ├── github-integration.md      # GitHub integration guide
│   ├── installation-guide.md      # Installation guide
│   ├── maintenance-procedures.md  # Maintenance procedures
│   ├── monitoring-alerting.md     # Monitoring and alerting
│   ├── operational-procedures.md  # Operational procedures
│   ├── policy-reference.md        # Policy reference
│   ├── prerequisites.md           # Prerequisites
│   ├── quick-start-guide.md       # Quick start guide
│   ├── rollback-procedures.md     # Rollback procedures
│   ├── scripts-reference.md       # Scripts reference
│   ├── security-guidelines.md     # Security guidelines
│   ├── terraform-fundamentals.md  # Terraform fundamentals
│   ├── testing-procedures.md      # Testing procedures
│   └── troubleshooting-guide.md   # Troubleshooting guide
└── backups/                       # Backup files
```

## 🚀 Quick Start

### Prerequisites

-   **AWS CLI** installed and configured
-   **AWS Account** with appropriate permissions
-   **PowerShell** (Windows) or equivalent shell
-   **Git** for version control
-   **GitHub Account** (for Atlantis integration)
-   **Docker** and Docker Compose (for Atlantis)

### Production Deployment

1. **Clone and Navigate**

    ```powershell
    git clone <repository-url>
    cd terraform-atlantis-workshop
    ```

2. **Configure AWS Credentials**

    ```powershell
    aws configure
    ```

3. **Run Complete Workflow**

    ```powershell
    .\scripts\08-complete-workflow.ps1
    ```

4. **Or Run Individual Steps**
    ```powershell
    .\scripts\00-setup-env.ps1
    .\scripts\01-validate-environment.ps1
    .\scripts\02-setup-github-actions.ps1
    .\scripts\03-deploy-infrastructure.ps1
    .\scripts\04-health-monitoring.ps1
    ```

### Atlantis GitOps Workflow

1. **Setup GitHub Integration**

    ```powershell
    .\scripts\02-setup-github-actions.ps1
    ```

2. **Start Atlantis**

    ```powershell
    docker-compose up -d
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

## 🔒 Compliance Validation System

### Overview

The compliance validation system uses **native Terraform validation blocks** to enforce policies during the `terraform plan` phase, preventing violations before deployment.

### Validation Rules

| Policy             | Rule                               | Enforcement                  |
| ------------------ | ---------------------------------- | ---------------------------- |
| **Instance Types** | Only t3.micro, t3.small, t3.medium | Prevents expensive instances |
| **Required Tags**  | Environment, Project, CostCenter   | Ensures proper labeling      |
| **S3 Naming**      | terraform-atlantis-workshop-\*     | Enforces naming convention   |

### Example Violations

```bash
❌ VIOLATION: Found expensive instance types. Only t3.micro, t3.small, t3.medium are permitted.
Current instances: policy_test=t3.small, test_violation=m5.large, web=t3.micro
```

```bash
❌ VIOLATION: S3 buckets must follow naming convention: terraform-atlantis-workshop-*.
Current buckets: [violating bucket names]
```

### Testing Compliance

1. **Test with Active Resources**

    ```bash
    terraform plan
    ```

2. **Test with Commented Resources**

    ```terraform
    # In terraform/test-policy-violations.tf
    # Uncomment specific resources to test violations
    resource "aws_instance" "test_violation" {
      instance_type = "m5.large"  # VIOLATION: Expensive instance
    }
    ```

3. **Run Plan and Check Results**
    ```bash
    atlantis plan -p terraform-atlantis-workshop
    ```

## ⚙️ Configuration

### Default Settings

| Setting               | Value                            | Description              |
| --------------------- | -------------------------------- | ------------------------ |
| **VPC CIDR**          | 10.0.0.0/16                      | Main VPC network         |
| **Public Subnet**     | 10.0.1.0/24                      | Public subnet range      |
| **Private Subnet**    | 10.0.2.0/24                      | Private subnet range     |
| **Instance Type**     | t3.micro                         | Default EC2 instance     |
| **Region**            | ap-southeast-1                   | AWS region               |
| **Allowed Instances** | t3.micro, t3.small, t3.medium    | Compliant instance types |
| **Required Tags**     | Environment, Project, CostCenter | Mandatory resource tags  |
| **S3 Naming**         | terraform-atlantis-workshop-\*   | Bucket naming convention |

### Customization

Modify `terraform/terraform.tfvars` or use environment variables to customize settings.

## 🔧 Troubleshooting

### Common Issues

#### AWS Issues

-   **Credentials not configured**: Run `aws configure`
-   **Insufficient permissions**: Verify IAM roles and policies
-   **Region configuration**: Check AWS region settings

#### Atlantis Issues

-   **Service not accessible**: Verify port 4141 availability
-   **GitHub webhook errors**: Check webhook configuration
-   **Permission errors**: Validate GitHub token permissions

#### Compliance Validation Issues

-   **Violations not detected**: Ensure `compliance-validation.tf` is included
-   **False positives**: Verify resource configurations
-   **Plan failures**: Fix violations before applying

### Service Management

#### Check Infrastructure Status

```powershell
# Verify AWS credentials
aws sts get-caller-identity

# Check infrastructure health
.\scripts\04-health-monitoring.ps1

# Monitor costs
.\scripts\05-cost-monitoring.ps1
```

#### Restart Services

```powershell
# Restart Atlantis
docker-compose restart atlantis

# Check EC2 instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
```

### Cleanup Procedures

```powershell
# Destroy infrastructure
.\scripts\07-cleanup-infrastructure.ps1

# Verify cleanup
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
```

## 📚 Documentation

Comprehensive documentation is available in the `docs/` directory:

-   **[Quick Start Guide](docs/quick-start-guide.md)** - Get started quickly
-   **[Installation Guide](docs/installation-guide.md)** - Detailed installation steps
-   **[AWS Production Setup](docs/aws-production-setup.md)** - Production deployment guide
-   **[Compliance Validation](docs/compliance-validation.md)** - Policy enforcement details
-   **[Deployment Procedures](docs/deployment-procedures.md)** - Deployment workflows
-   **[Troubleshooting Guide](docs/troubleshooting-guide.md)** - Common issues and solutions
-   **[Best Practices](docs/best-practices.md)** - Recommended practices
-   **[API Reference](docs/api-reference.md)** - Technical reference

## 🔄 Next Steps

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

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test with AWS Production infrastructure
5. Ensure compliance validation passes
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Nguyen Nhat Quang (Bright-04)**

-   **Email**: cbl.nguyennhatquang2809@gmail.com
-   **Repository**: terraform-atlantis-workshop
-   **Program**: First Cloud Journey 2025, Amazon Web Service Vietnam
-   **Focus**: Environment Provisioning Automation with Terraform and Atlantis

---

_This project demonstrates a complete infrastructure automation solution with compliance validation, GitOps workflows, and cost optimization strategies for production environments._
