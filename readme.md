# Terraform Atlantis Workshop

## Overview

This workshop demonstrates **Environment Provisioning Automation** using Terraform and Atlantis with a focus on approval workflows, cost controls, and monitoring integration. The project is designed to work with both LocalStack (for cost-free development) and real AWS infrastructure.

### Workshop Objectives
- Implement automated environment provisioning with Terraform
- Set up approval workflows using Atlantis
- Integrate cost controls and monitoring
- Establish compliance validation and rollback procedures
- Create comprehensive operational documentation

## Technologies Used

### Core Infrastructure
- **Terraform (v1.0+)** - Infrastructure as Code
- **AWS Provider (~5.0)** - Cloud resources management
- **LocalStack** - Local AWS cloud stack for development
- **Docker & Docker Compose** - Container orchestration

### Development Tools
- **PowerShell** - Automation scripts
- **Git** - Version control
- **VS Code** - Development environment

### Planned Integration
- **Atlantis** - GitOps workflow automation
- **CloudWatch** - Monitoring and alerting
- **AWS Cost Explorer** - Cost management
- **S3** - Terraform state backend

## Current Status

### ✅ Completed
- [x] **LocalStack Environment Setup**
  - Docker Compose configuration for LocalStack
  - Support for EC2, S3, RDS, IAM, CloudWatch, Lambda, API Gateway
  - Local development environment ready

- [x] **Terraform Infrastructure Foundation**
  - VPC with public/private subnets (10.0.0.0/16)
  - Internet Gateway and route tables
  - Security groups for web servers
  - EC2 instance with user data
  - S3 bucket for testing
  - Complete variable definitions
  - Output values for resource references

- [x] **Dual Environment Support**
  - LocalStack configuration for cost-free development
  - AWS configuration for production deployment
  - Environment-specific provider configurations
  - Flexible deployment scripts

- [x] **Project Structure**
  - Organized terraform modules
  - Backup configurations for different environments
  - PowerShell deployment scripts
  - Documentation templates

### 🚧 In Progress
- [ ] **Atlantis Integration**
  - Atlantis server configuration
  - Webhook setup for GitHub integration
  - Approval workflow definitions

- [ ] **Monitoring Setup**
  - CloudWatch metrics and alarms
  - Cost monitoring dashboard
  - Infrastructure health checks

### 📋 Planned
- [ ] **Approval Workflows**
  - Pull request-based infrastructure changes
  - Multi-stage approval process
  - Automated compliance checks

- [ ] **Cost Controls**
  - Budget alerts and limits
  - Resource tagging strategy
  - Cost optimization recommendations

- [ ] **Compliance & Security**
  - Security group auditing
  - Compliance validation rules
  - Automated security scanning

- [ ] **Rollback Procedures**
  - Automated rollback mechanisms
  - State backup and recovery
  - Disaster recovery procedures

## Project Structure

```
terraform-atlantis-workshop/
├── docker-compose.yml              # LocalStack container configuration
├── workshop_info.md                # Workshop requirements and objectives
├── terraform/
│   ├── main.tf                     # Current Terraform configuration (LocalStack)
│   ├── variables.tf                # Variable definitions
│   ├── outputs.tf                  # Output values
│   ├── versions.tf                 # Provider requirements
│   ├── terraform.tfvars            # Variable values (not in git)
│   ├── terraform.tfvars.example    # Example variables
│   ├── deploy.ps1                  # Deployment script
│   ├── destroy.ps1                 # Cleanup script
│   ├── README.md                   # Terraform-specific documentation
│   └── backup/
│       ├── main-aws.tf             # AWS production configuration
│       ├── main-localstack.tf      # LocalStack development configuration
│       └── main.tf                 # Generic backup configuration
├── atlantis/                       # Atlantis configuration (planned)
├── docs/                           # Documentation (planned)
├── monitoring/                     # Monitoring configuration (planned)
└── localstack-data/                # LocalStack persistence data
```

## Getting Started

### Prerequisites
- Docker Desktop installed and running
- PowerShell (Windows) or equivalent shell
- Git for version control
- AWS CLI (for production deployment)

### Quick Start with LocalStack

1. **Clone and Navigate**
   ```powershell
   git clone <repository-url>
   cd terraform-atlantis-workshop
   ```

2. **Start LocalStack**
   ```powershell
   docker-compose up -d
   ```

3. **Deploy Infrastructure**
   ```powershell
   cd terraform
   .\deploy.ps1
   ```

4. **Verify Deployment**
   ```powershell
   # Set LocalStack environment variables
   $env:AWS_ACCESS_KEY_ID="test"
   $env:AWS_SECRET_ACCESS_KEY="test"
   $env:AWS_DEFAULT_REGION="us-east-1"
   
   # Check resources
   aws --endpoint-url=http://localhost:4566 ec2 describe-instances
   aws --endpoint-url=http://localhost:4566 s3 ls
   ```

### Production Deployment (AWS)

1. **Configure AWS Credentials**
   ```powershell
   aws configure
   ```

2. **Switch to AWS Configuration**
   ```powershell
   Copy-Item backup/main-aws.tf main.tf -Force
   ```

3. **Deploy to AWS**
   ```powershell
   terraform init
   terraform plan
   terraform apply
   ```

### Configuration

The project uses the following default configuration:
- **VPC CIDR**: 10.0.0.0/16
- **Public Subnet**: 10.0.1.0/24
- **Private Subnet**: 10.0.2.0/24
- **Instance Type**: t3.micro
- **Region**: us-east-1

Customize these values in `terraform.tfvars` or through environment variables.

## Key Features

### Cost-Effective Development
- **LocalStack Integration**: Develop and test without AWS costs
- **Resource Optimization**: Efficient resource allocation
- **Environment Isolation**: Separate development and production

### Infrastructure as Code
- **Terraform Best Practices**: Modular, reusable configurations
- **Version Control**: All infrastructure changes tracked
- **Automated Deployment**: PowerShell scripts for consistency

### Security & Compliance
- **Security Groups**: Properly configured network access
- **Resource Tagging**: Consistent labeling strategy
- **Environment Separation**: Isolated development/production

## Next Steps

1. **Atlantis Integration**
   - Configure Atlantis server
   - Set up GitHub webhooks
   - Implement approval workflows

2. **Monitoring & Alerting**
   - Deploy CloudWatch dashboards
   - Set up cost alerts
   - Configure health checks

3. **Advanced Features**
   - Implement Terraform modules
   - Add automated testing
   - Set up CI/CD pipelines

4. **Documentation**
   - Operational runbooks
   - Troubleshooting guides
   - Best practices documentation

## Troubleshooting

### Common Issues
- **LocalStack not starting**: Check Docker Desktop is running
- **Port conflicts**: Ensure ports 4566 and 4510-4559 are available
- **Permission issues**: Verify AWS credentials and IAM permissions

### Cleanup
```powershell
# Destroy infrastructure
.\destroy.ps1

# Stop LocalStack
docker-compose down

# Remove volumes (optional)
docker-compose down -v
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with LocalStack
5. Submit a pull request

## Author

**Nguyen Nhat Quang (Bright-04)**
- Email: cbl.nguyennhatquang2809@gmail.com
- Repository: terraform-atlantis-workshop
- Program: First Cloud Journey 2025, Amazon Web Service Vietnam
- Focus: Environment Provisioning Automation with Terraform and Atlantis

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*This project is part of a workshop series focusing on infrastructure automation, GitOps workflows, and cloud cost optimization.*
