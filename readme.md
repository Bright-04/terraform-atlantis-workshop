# Environment Provisioning Automation Workshop
## Terraform & Atlantis Infrastructure Automation

### 🎯 Workshop Purpose & Definition

This workshop teaches **Infrastructure as Code (IaC)** automation using **Terraform** and **Atlantis** to create enterprise-grade AWS environment provisioning with approval workflows, cost controls, and compliance validation.

#### What You'll Build:
- **Automated Infrastructure Provisioning** using Terraform
- **GitOps Workflow** with Atlantis for approval processes
- **Cost Monitoring & Control** system
- **Compliance Validation** framework
- **Rollback & Recovery** procedures
- **Complete Documentation** with Hugo

### 🏆 Workshop Learning Objectives

1. **Master Infrastructure as Code**
   - Write Terraform configurations for AWS resources
   - Implement reusable modules and best practices
   - Manage infrastructure state and versioning

2. **Implement GitOps Workflows**
   - Set up Atlantis for automated Terraform operations
   - Create approval gates for infrastructure changes
   - Integrate with Git-based change management

3. **Establish Cost Controls**
   - Implement AWS cost monitoring and budgeting
   - Set up automated cost alerts and reporting
   - Create cost estimation for infrastructure changes

4. **Ensure Compliance & Security**
   - Validate infrastructure against compliance rules
   - Implement security scanning and policies
   - Create audit trails for all changes

5. **Develop Operational Excellence**
   - Create comprehensive documentation
   - Establish rollback and disaster recovery procedures
   - Develop operational runbooks and troubleshooting guides

### 🎓 Target Audience
- DevOps Engineers
- Cloud Architects
- Infrastructure Engineers
- Teams implementing GitOps for infrastructure
- Students preparing for AWS DevOps graduation

### 💼 Real-World Application
This workshop simulates enterprise environments where:
- Multiple teams need controlled infrastructure access
- All changes require approval and audit trails
- Cost control and monitoring are critical
- Compliance and security must be maintained
- Documentation and procedures are essential

### 🏗️ What You'll Create
By the end of this workshop, you'll have:
- **Production-ready Terraform infrastructure**
- **Atlantis-powered approval workflow**
- **Cost monitoring dashboard**
- **Compliance validation system**
- **Complete Hugo documentation site**
- **Operational procedures and runbooks**

## 📅 13-Day Accelerated Workshop Timeline

### **Phase 1: Foundation (Days 1-2)**
- AWS environment setup
- Tool installation and configuration
- Basic Terraform infrastructure deployment

### **Phase 2: Core Infrastructure (Days 3-4)**
- Advanced Terraform configurations
- Module development and testing
- State management setup

### **Phase 3: Atlantis Integration (Days 5-6)**
- Atlantis server deployment
- GitHub/GitLab integration
- Approval workflow implementation

### **Phase 4: Monitoring & Cost Controls (Days 7-8)**
- AWS cost monitoring setup
- CloudWatch dashboards
- Automated alerting system

### **Phase 5: Compliance & Security (Days 9-10)**
- AWS Config rules implementation
- Security scanning automation
- Compliance reporting

### **Phase 6: Documentation & Operations (Days 11-12)**
- Hugo documentation site
- Operational procedures
- Rollback testing

### **Phase 7: Final Integration (Day 13)**
- End-to-end testing
- Final demonstration
- Workshop completion

## 🚀 Step-by-Step Getting Started Guide

### **Day 1-2: Foundation Setup**

#### Step 1: Install Required Tools
```powershell
# Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Terraform
choco install terraform

# Install AWS CLI
choco install awscli

# Install Git
choco install git

# Install Hugo (for documentation)
choco install hugo

# Verify installations
terraform version
aws --version
git --version
hugo version
```

#### Step 2: AWS Account Setup
1. **Create AWS Account** (if you don't have one)
   - Go to [AWS Console](https://aws.amazon.com/)
   - Create new account or use existing

2. **Configure Billing Alerts**
   - Go to AWS Billing Dashboard
   - Set up billing alerts for cost control
   - Create budget alerts

3. **Create IAM User for Terraform**
   - Go to IAM Console
   - Create new user: `terraform-user`
   - Attach policies: `PowerUserAccess` (or custom restrictive policy)
   - Generate Access Key and Secret Key

4. **Configure AWS CLI**
   ```powershell
   aws configure
   # Enter your Access Key ID
   # Enter your Secret Access Key
   # Enter your preferred region (e.g., us-east-1)
   # Enter output format: json
   ```

#### Step 3: Initialize Your Workspace
```powershell
# Navigate to your workshop directory
cd "d:\IT WORKSHOP"

# Initialize Git repository
git init

# Create initial commit
git add .
git commit -m "Initial workshop setup"

# Create GitHub repository and push (optional but recommended)
# git remote add origin https://github.com/yourusername/terraform-atlantis-workshop.git
# git push -u origin main
```

### **Day 3-4: Core Terraform Infrastructure**

#### Step 4: Deploy Your First Infrastructure
```powershell
# Navigate to terraform directory
cd terraform

# Copy example variables
Copy-Item terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your specific values
# Use any text editor to modify:
# - region (your preferred AWS region)
# - project_name (your project name)
# - key_pair_name (create a key pair in AWS console first)
```

#### Step 5: Deploy Infrastructure
```powershell
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Note the outputs - you'll need them later
terraform output
```

### **Day 5-6: Atlantis Setup**

#### Step 6: Create Atlantis Configuration
```powershell
# Navigate to atlantis directory
cd ..\atlantis

# Create atlantis.yaml configuration file
# (This file will be created in the next steps)
```

#### Step 7: Deploy Atlantis Server
- Deploy Atlantis on AWS ECS or EC2
- Configure GitHub/GitLab webhooks
- Set up SSL certificate for HTTPS

### **Day 7-8: Monitoring & Cost Controls**

#### Step 8: Implement Cost Monitoring
```powershell
# Navigate to monitoring directory
cd ..\monitoring

# Create CloudWatch dashboards
# Set up cost alerts
# Implement budget monitoring
```

### **Day 9-10: Compliance & Security**

#### Step 9: Security Implementation
- Set up AWS Config rules
- Implement security scanning with Checkov
- Create compliance reporting

### **Day 11-12: Documentation**

#### Step 10: Create Hugo Documentation
```powershell
# Navigate to docs directory
cd ..\docs

# Initialize Hugo site
hugo new site .

# Add theme and content
# Create documentation pages
```

### **Day 13: Final Integration**

#### Step 11: End-to-End Testing
- Test complete workflow
- Validate all components
- Prepare demonstration

## 💰 Cost-Free Local Development with LocalStack

### Why Use LocalStack?
- **Zero AWS costs** during development and testing
- **Fast iteration** without waiting for AWS API calls
- **Offline development** capability
- **Perfect for learning** and experimentation

### LocalStack Setup (Alternative to AWS)

#### Step 1: Install LocalStack
```powershell
# Install Docker Desktop first
choco install docker-desktop

# Install LocalStack CLI
pip install localstack

# Verify installation
localstack --version
```

#### Step 2: Start LocalStack
```powershell
# Start LocalStack with required services
localstack start

# Or start with Docker Compose (recommended)
# Create docker-compose.yml file (shown below)
docker-compose up -d
```

#### Step 3: Configure Terraform for LocalStack
```hcl
# Add to your terraform/main.tf
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    s3  = "http://localhost:4566"
    rds = "http://localhost:4566"
    iam = "http://localhost:4566"
  }
}
```

### LocalStack vs AWS Workflow

#### For Local Development (Days 1-6):
1. **Use LocalStack** for initial development
2. **Test Terraform configurations** locally
3. **Debug and iterate** quickly
4. **Learn without cost concerns**

#### For Production Testing (Days 7-13):
1. **Deploy to AWS** for real-world testing
2. **Use AWS Free Tier** resources
3. **Implement cost monitoring**
4. **Prepare for final demonstration**

## 📁 Project Structure
```
IT WORKSHOP/
├── terraform/              # Terraform configurations
│   ├── main.tf             # Main infrastructure code
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   ├── versions.tf         # Provider versions
│   └── terraform.tfvars    # Variable values (create from .example)
├── atlantis/               # Atlantis configuration
│   ├── atlantis.yaml       # Atlantis configuration
│   └── server-config.yaml  # Server configuration
├── monitoring/             # Monitoring setup
│   ├── cloudwatch.tf       # CloudWatch dashboards
│   └── cost-alerts.tf      # Cost monitoring
├── docs/                   # Hugo documentation
│   ├── config.yaml         # Hugo configuration
│   └── content/            # Documentation content
├── workshop-plan.md        # Detailed workshop plan
├── getting-started.md      # Quick start guide
└── readme.md              # This file
```

## 🎯 Success Criteria

### Technical Deliverables:
- [ ] **Working Terraform Infrastructure** - VPC, EC2, RDS deployed
- [ ] **Atlantis Approval Workflow** - PRs trigger plan/apply
- [ ] **Cost Monitoring Dashboard** - Real-time cost tracking
- [ ] **Compliance Validation** - Automated security checks
- [ ] **Hugo Documentation Site** - Complete project documentation
- [ ] **Operational Procedures** - Rollback and recovery guides

### Learning Outcomes:
- [ ] **IaC Mastery** - Can write production-ready Terraform
- [ ] **GitOps Implementation** - Understand approval workflows
- [ ] **Cost Management** - Can implement cost controls
- [ ] **Security & Compliance** - Can validate infrastructure
- [ ] **Documentation Skills** - Can create technical documentation

## 🛠️ Tools & Technologies Used

### Core Technologies:
- **Terraform** - Infrastructure as Code
- **Atlantis** - GitOps for Terraform
- **AWS** - Cloud provider
- **Git** - Version control
- **Hugo** - Documentation generator

### AWS Services:
- **VPC** - Virtual Private Cloud
- **EC2** - Elastic Compute Cloud
- **RDS** - Relational Database Service
- **S3** - Simple Storage Service
- **CloudWatch** - Monitoring and logging
- **Cost Explorer** - Cost analysis
- **Config** - Configuration compliance

## 🆘 Getting Help

### Resources:
- **Workshop Plan**: `workshop-plan.md` - Detailed 13-day breakdown
- **Getting Started**: `getting-started.md` - Quick start guide
- **Terraform Docs**: [terraform.io](https://terraform.io)
- **Atlantis Docs**: [runatlantis.io](https://runatlantis.io)
- **AWS Docs**: [docs.aws.amazon.com](https://docs.aws.amazon.com)

### Troubleshooting:
- Check AWS credentials configuration
- Verify Terraform state is not corrupted
- Ensure proper IAM permissions
- Check AWS service limits and quotas

### Community Support:
- Terraform Community Forum
- AWS Community Forums
- Stack Overflow with relevant tags
- GitHub Issues for specific tools

## 📚 Additional Learning Resources

### Books:
- "Terraform: Up & Running" by Yevgeniy Brikman
- "AWS Well-Architected Framework" (AWS Documentation)
- "Infrastructure as Code" by Kief Morris

### Online Courses:
- AWS Certified DevOps Engineer
- HashiCorp Certified Terraform Associate
- Kubernetes and DevOps courses

### Hands-on Labs:
- AWS Free Tier resources
- Terraform tutorials and examples
- Atlantis getting started guides

---

**🎓 Workshop Completion**: This workshop prepares you for AWS DevOps graduation by demonstrating mastery of infrastructure automation, GitOps workflows, cost management, and operational excellence.