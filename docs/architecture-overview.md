# Architecture Overview - Terraform Atlantis Workshop

## 🏗️ System Architecture

This document provides a comprehensive overview of the **Environment Provisioning Automation with Terraform and Atlantis** architecture, including system components, data flow, and design decisions.

## 📊 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Repository                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Terraform     │  │   Atlantis      │  │   Compliance    │ │
│  │   Configs       │  │   Workflows     │  │   Policies      │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Atlantis Server                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Webhook       │  │   Terraform     │  │   Validation    │ │
│  │   Handler       │  │   Executor      │  │   Engine        │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Production Environment                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   VPC &         │  │   EC2           │  │   S3 &          │ │
│  │   Networking    │  │   Instances     │  │   Storage       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Security      │  │   CloudWatch    │  │   IAM &         │ │
│  │   Groups        │  │   Monitoring    │  │   Access        │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Core Components

### 1. Infrastructure as Code (Terraform)

#### Terraform Configuration Structure
```
terraform/
├── main-aws.tf              # Main AWS infrastructure
├── variables.tf             # Variable definitions
├── outputs.tf               # Output values
├── versions.tf              # Provider requirements
├── compliance-validation.tf # Compliance validation rules
├── test-policy-violations.tf # Test resources
└── user_data.sh            # EC2 initialization script
```

#### Key Infrastructure Components

**VPC and Networking**
- **VPC**: 10.0.0.0/16 CIDR block
- **Public Subnet**: 10.0.1.0/24 (for web servers)
- **Private Subnet**: 10.0.2.0/24 (for future use)
- **Internet Gateway**: For public internet access
- **Route Tables**: Proper routing configuration

**Compute Resources**
- **EC2 Instances**: Amazon Linux 2 with Apache web server
- **Instance Types**: t3.micro (compliant with cost controls)
- **Auto Scaling**: Ready for future scaling needs
- **Load Balancer**: Application Load Balancer (ALB)

**Storage and Data**
- **S3 Buckets**: Encrypted storage with versioning
- **Naming Convention**: terraform-atlantis-workshop-*
- **Lifecycle Policies**: Cost optimization
- **Public Access Blocking**: Security enhancement

**Security and Access**
- **Security Groups**: Restrictive access controls
- **IAM Roles**: Least privilege access
- **Encryption**: AES256 encryption for S3
- **Key Management**: AWS KMS integration ready

### 2. GitOps Workflow (Atlantis)

#### Atlantis Configuration
```yaml
# atlantis.yaml
version: 3
projects:
- name: terraform-atlantis-workshop
  dir: terraform
  workspace: default
  terraform_version: v1.6.0
  autoplan:
    when_modified: ["*.tf", "../.gitmodules"]
    enabled: true
  apply_requirements: [approved]
```

#### Workflow Process
1. **Pull Request Creation**: Developer creates PR with infrastructure changes
2. **Webhook Trigger**: GitHub webhook notifies Atlantis
3. **Automatic Planning**: Atlantis runs `terraform plan`
4. **Compliance Validation**: Validation rules check for violations
5. **Plan Review**: Team reviews plan output in PR comments
6. **Approval Process**: Required approvals before apply
7. **Infrastructure Apply**: Atlantis applies approved changes
8. **Status Update**: Results posted back to PR

### 3. Compliance Validation System

#### Validation Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                Terraform Configuration                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Resource      │  │   Validation    │  │   Error     │ │
│  │   Definitions   │  │   Blocks        │  │   Messages  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                Validation Engine                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Instance      │  │   Tag           │  │   S3        │ │
│  │   Type Check    │  │   Validation    │  │   Naming    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                Output Processing                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Violation     │  │   Success       │  │   GitHub    │ │
│  │   Detection     │  │   Confirmation  │  │   Comments  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Validation Rules

**Instance Type Validation**
```hcl
lifecycle {
  precondition {
    condition = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium for cost control."
  }
}
```

**Tag Validation**
```hcl
lifecycle {
  precondition {
    condition = alltrue([
      contains(keys(var.tags), "Environment"),
      contains(keys(var.tags), "Project"),
      contains(keys(var.tags), "CostCenter")
    ])
    error_message = "Required tags: Environment, Project, CostCenter must be present."
  }
}
```

**S3 Naming Validation**
```hcl
lifecycle {
  precondition {
    condition = can(regex("^terraform-atlantis-workshop-", var.bucket_name))
    error_message = "S3 bucket must follow naming convention: terraform-atlantis-workshop-*"
  }
}
```

### 4. Monitoring and Observability

#### Monitoring Stack
```
┌─────────────────────────────────────────────────────────────┐
│                CloudWatch Monitoring                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Metrics       │  │   Logs          │  │   Alarms    │ │
│  │   Collection    │  │   Aggregation   │  │   &         │ │
│  │   & Storage     │  │   & Analysis    │  │   Notifications │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                Health Monitoring Scripts                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Infrastructure│  │   Application   │  │   Cost      │ │
│  │   Health Check  │  │   Health Check  │  │   Monitoring│ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Key Metrics
- **EC2 Instance Health**: CPU, memory, disk usage
- **Application Health**: Web server response times
- **Infrastructure Status**: VPC, subnet, security group health
- **Cost Metrics**: Resource utilization and cost trends

### 5. Security Architecture

#### Security Layers
```
┌─────────────────────────────────────────────────────────────┐
│                Security Architecture                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Network       │  │   Application   │  │   Data      │ │
│  │   Security      │  │   Security      │  │   Security  │ │
│  │   (VPC, SG)     │  │   (IAM, WAF)    │  │   (Encryption) │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                Compliance & Governance                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Policy        │  │   Audit         │  │   Access    │ │
│  │   Enforcement   │  │   Logging       │  │   Control   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Security Features
- **Network Isolation**: VPC with public/private subnets
- **Access Control**: Security groups with minimal required access
- **Data Protection**: S3 encryption and versioning
- **Identity Management**: IAM roles with least privilege
- **Compliance**: Automated policy validation

## 🔄 Data Flow

### 1. Infrastructure Deployment Flow
```
Developer → GitHub PR → Atlantis Webhook → Terraform Plan → 
Compliance Validation → Plan Review → Approval → Terraform Apply → 
Infrastructure Update → Status Report
```

### 2. Compliance Validation Flow
```
Terraform Config → Validation Blocks → Rule Engine → 
Violation Check → Error Messages → GitHub Comments → 
Developer Action → Re-validation
```

### 3. Monitoring Flow
```
AWS Resources → CloudWatch Metrics → Health Scripts → 
Status Reports → Alerts → Operational Response
```

## 🎯 Design Principles

### 1. Infrastructure as Code
- **Version Controlled**: All infrastructure in Git
- **Reproducible**: Consistent deployments across environments
- **Testable**: Validation and testing capabilities
- **Documented**: Self-documenting configurations

### 2. GitOps Workflow
- **Pull Request Based**: All changes through PR workflow
- **Automated**: Minimal manual intervention
- **Auditable**: Complete change history
- **Approval Based**: Required reviews before apply

### 3. Security First
- **Least Privilege**: Minimal required permissions
- **Defense in Depth**: Multiple security layers
- **Compliance**: Automated policy enforcement
- **Monitoring**: Continuous security monitoring

### 4. Cost Optimization
- **Resource Efficiency**: Right-sized instances
- **Automated Controls**: Policy-based cost management
- **Monitoring**: Cost tracking and alerting
- **Optimization**: Continuous cost improvement

## 📈 Scalability Considerations

### Horizontal Scaling
- **Auto Scaling Groups**: Ready for dynamic scaling
- **Load Balancers**: Traffic distribution
- **Multi-AZ**: High availability across zones

### Vertical Scaling
- **Instance Types**: Upgrade path available
- **Storage**: Expandable storage options
- **Performance**: Monitoring-driven optimization

### Operational Scaling
- **Automation**: Scripts for common tasks
- **Documentation**: Comprehensive procedures
- **Training**: Knowledge transfer capabilities

## 🔧 Technology Stack

### Core Technologies
- **Terraform**: Infrastructure as Code
- **AWS**: Cloud infrastructure provider
- **Atlantis**: GitOps workflow automation
- **GitHub**: Version control and collaboration

### Supporting Technologies
- **PowerShell**: Automation scripting
- **Docker**: Containerization (optional)
- **CloudWatch**: Monitoring and logging
- **IAM**: Identity and access management

### Development Tools
- **VS Code**: Development environment
- **Git**: Version control
- **AWS CLI**: AWS management
- **Terraform CLI**: Infrastructure management

## 🚀 Deployment Architecture

### Environment Strategy
```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Development   │  │   Staging       │  │   Production    │
│   Environment   │  │   Environment   │  │   Environment   │
│   (Local/Dev)   │  │   (Pre-prod)    │  │   (Live)        │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Deployment Pipeline
1. **Development**: Local testing and validation
2. **Staging**: Pre-production validation
3. **Production**: Live deployment with approval

## 📊 Performance Characteristics

### Expected Performance
- **Deployment Time**: 5-10 minutes for full infrastructure
- **Validation Time**: 30-60 seconds for compliance checks
- **Response Time**: <2 seconds for web server responses
- **Availability**: 99.9% uptime target

### Resource Utilization
- **CPU**: 10-20% average utilization
- **Memory**: 30-50% average utilization
- **Storage**: Minimal usage with lifecycle policies
- **Network**: Low bandwidth requirements

## 🔍 Monitoring and Alerting

### Key Metrics
- **Infrastructure Health**: Resource status and availability
- **Application Performance**: Response times and error rates
- **Security Events**: Access attempts and policy violations
- **Cost Metrics**: Resource utilization and spending

### Alerting Strategy
- **Critical**: Immediate response required
- **Warning**: Attention needed within hours
- **Info**: Monitoring and tracking

---

**📚 Related Documentation**
- [Quick Start Guide](quick-start-guide.md)
- [Deployment Procedures](deployment-procedures.md)
- [Compliance Validation](compliance-validation.md)
- [Troubleshooting Guide](troubleshooting-guide.md)
