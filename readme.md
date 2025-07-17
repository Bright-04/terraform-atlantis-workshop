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
  - Local development environment ready and tested

- [x] **Terraform Infrastructure Foundation**
  - VPC with public/private subnets (10.0.0.0/16)
  - Internet Gateway and route tables
  - Security groups for web servers (HTTP, HTTPS, SSH)
  - EC2 instance with user data script
  - Complete variable definitions and validation
  - Output values for resource references
  - Successfully deployed and tested on LocalStack

- [x] **Atlantis Integration**
  - Complete Atlantis server configuration in Docker Compose
  - GitHub integration setup with webhook support
  - Approval workflow definitions in atlantis.yaml
  - Environment-based configuration with .env support
  - PowerShell script for GitHub integration setup
  - Terraform v1.6.0 integration with LocalStack

- [x] **Dual Environment Support**
  - LocalStack configuration for cost-free development (active)
  - AWS configuration for production deployment (backup files)
  - Environment-specific provider configurations
  - Flexible deployment and destruction scripts

- [x] **Project Structure & Automation**
  - Organized terraform configurations
  - Backup configurations for different environments
  - PowerShell deployment and destroy scripts
  - GitHub integration automation script
  - Comprehensive documentation and examples

### 🚧 In Progress
- [ ] **S3 Bucket Implementation**
  - S3 bucket resource available in backup files
  - Versioning configuration ready
  - Need to integrate into main configuration

### 📋 Planned
- [ ] **Monitoring Setup**
  - CloudWatch metrics and alarms
  - Cost monitoring dashboard
  - Infrastructure health checks

- [ ] **Advanced Approval Workflows**
  - Multi-stage approval process
  - Automated compliance checks
  - Branch-based deployment strategies

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
├── atlantis.yaml                   # Atlantis workflow configuration
├── docker-compose.yml              # LocalStack and Atlantis containers
├── setup-github-integration.ps1    # GitHub integration setup script
├── .env.example                    # Environment variables template
├── workshop_info.md                # Workshop requirements and objectives
├── dev.md                          # Development notes and guidelines
├── ENVIRONMENT_SETUP.md            # Environment setup instructions
├── TESTING.md                      # Testing procedures
├── terraform/
│   ├── main.tf                     # Current Terraform configuration (LocalStack)
│   ├── variables.tf                # Variable definitions
│   ├── outputs.tf                  # Output values
│   ├── versions.tf                 # Provider requirements
│   ├── terraform.tfvars            # Variable values (configured)
│   ├── terraform.tfvars.example    # Example variables
│   ├── terraform.tfstate           # Current state (deployed)
│   ├── terraform.tfstate.backup    # State backup
│   ├── deploy.ps1                  # Deployment script
│   ├── destroy.ps1                 # Cleanup script
│   ├── README.md                   # Terraform-specific documentation
│   └── backup/
│       ├── main-aws.tf             # AWS production configuration
│       ├── main-localstack.tf      # LocalStack with S3 bucket
│       ├── main.tf                 # Generic backup configuration
│       └── versions.tf             # Provider version backups
├── atlantis/
│   ├── atlantis.db                 # Atlantis database file
│   ├── bin/
│   │   └── terraform1.6.0         # Terraform binary
│   └── plugin-cache/               # Terraform plugin cache
├── docs/                           # Documentation (placeholder)
├── monitoring/                     # Monitoring configuration (placeholder)
└── localstack-data/                # LocalStack persistence data
```

## Getting Started

### Prerequisites
- Docker Desktop installed and running
- PowerShell (Windows) or equivalent shell
- Git for version control
- AWS CLI (for production deployment)
- GitHub account (for Atlantis integration)

### Quick Start with LocalStack + Atlantis

1. **Clone and Navigate**
   ```powershell
   git clone <repository-url>
   cd terraform-atlantis-workshop
   ```

2. **Configure GitHub Integration (Optional)**
   ```powershell
   # Run the setup script to configure GitHub integration
   .\setup-github-integration.ps1
   ```

3. **Start LocalStack and Atlantis**
   ```powershell
   # Start both LocalStack and Atlantis services
   docker-compose up -d
   
   # Check services are running
   docker-compose ps
   ```

4. **Deploy Infrastructure (Direct Method)**
   ```powershell
   cd terraform
   .\deploy.ps1
   ```

5. **Verify Deployment**
   ```powershell
   # Set LocalStack environment variables
   $env:AWS_ACCESS_KEY_ID="test"
   $env:AWS_SECRET_ACCESS_KEY="test"
   $env:AWS_DEFAULT_REGION="us-east-1"
   
   # Check resources
   aws --endpoint-url=http://localhost:4566 ec2 describe-instances
   aws --endpoint-url=http://localhost:4566 s3 ls
   ```

6. **Access Atlantis UI (if configured)**
   ```
   http://localhost:4141
   ```

### GitOps Workflow with Atlantis

Once GitHub integration is configured:

1. **Create a Pull Request** with infrastructure changes
2. **Atlantis automatically runs** `terraform plan`
3. **Review the plan** in the PR comments
4. **Approve the PR** following your approval workflow
5. **Comment `atlantis apply`** to apply changes
6. **Atlantis applies** the infrastructure changes

### Manual Deployment (Alternative)

For direct deployment without GitOps workflow:

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

### GitOps Workflow with Atlantis
- **Pull Request-Based Infrastructure Changes**: All changes through PR workflow
- **Automated Plan Generation**: Atlantis automatically runs `terraform plan`
- **Approval Requirements**: Configurable approval workflows before apply
- **GitHub Integration**: Seamless integration with GitHub webhooks
- **Audit Trail**: Complete history of infrastructure changes

### Cost-Effective Development
- **LocalStack Integration**: Develop and test without AWS costs
- **Container-Based Setup**: Quick environment provisioning
- **Resource Optimization**: Efficient resource allocation
- **Environment Isolation**: Separate development and production

### Infrastructure as Code
- **Terraform Best Practices**: Modular, reusable configurations
- **Version Control**: All infrastructure changes tracked
- **Automated Deployment**: PowerShell and Atlantis-based deployment
- **State Management**: Proper state file handling and backup

### Security & Compliance
- **Security Groups**: Properly configured network access
- **Resource Tagging**: Consistent labeling strategy
- **Environment Separation**: Isolated development/production
- **Approval Workflows**: Controlled infrastructure changes

### Operational Excellence
- **Comprehensive Documentation**: Clear setup and usage guides
- **Automated Scripts**: PowerShell automation for common tasks
- **Container Orchestration**: Docker Compose for service management
- **Monitoring Ready**: Structured for monitoring integration

## Next Steps

1. **Complete S3 Integration**
   - Move S3 bucket from backup to main configuration
   - Add S3 bucket versioning and security configurations
   - Test S3 integration with LocalStack

2. **Enhance Atlantis Workflows**
   - Configure multi-environment workflows
   - Add policy checks and validation
   - Implement custom approval requirements

3. **Monitoring & Alerting**
   - Deploy CloudWatch dashboards
   - Set up cost alerts and monitoring
   - Configure infrastructure health checks

4. **Advanced Features**
   - Implement Terraform modules
   - Add automated testing with terratest
   - Set up CI/CD pipelines

5. **Production Hardening**
   - Implement remote state backend
   - Add encryption and security scanning
   - Configure backup and disaster recovery

6. **Documentation Enhancement**
   - Create operational runbooks
   - Add troubleshooting guides
   - Document best practices and patterns

## Troubleshooting

### Common Issues

**LocalStack Issues:**
- **LocalStack not starting**: Check Docker Desktop is running
- **Port conflicts**: Ensure ports 4566 and 4510-4559 are available
- **Service timeouts**: Wait for LocalStack health check to pass

**Atlantis Issues:**
- **Atlantis not accessible**: Check port 4141 is available
- **GitHub webhook errors**: Verify .env configuration and webhook URL
- **Permission errors**: Ensure GitHub token has proper permissions

**Terraform Issues:**
- **State lock errors**: Check if terraform processes are running
- **Provider errors**: Verify LocalStack is running and accessible
- **Resource conflicts**: Check for existing resources in LocalStack

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
