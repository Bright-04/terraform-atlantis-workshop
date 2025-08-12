# Best Practices - Terraform Atlantis Workshop

## 🎯 Recommended Practices and Patterns

This document outlines best practices for implementing **Environment Provisioning Automation with Terraform and Atlantis** based on industry standards and operational experience.

## 🏗️ Infrastructure as Code Best Practices

### 1. Code Organization

#### File Structure

```
terraform/
├── main-aws.tf              # Main infrastructure
├── variables.tf             # Variable definitions
├── outputs.tf               # Output values
├── versions.tf              # Provider requirements
├── compliance-validation.tf # Validation rules
├── user_data.sh            # EC2 initialization
└── terraform.tfvars.example # Example variables
```

#### Best Practices

-   **Modular Design**: Separate concerns into logical files
-   **Consistent Naming**: Use descriptive, consistent names
-   **Version Control**: All code in Git with proper branching
-   **Documentation**: Self-documenting code with comments

### 2. Variable Management

#### Variable Definition

```hcl
variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium for cost control."
  }
}
```

#### Best Practices

-   **Type Constraints**: Always specify variable types
-   **Validation Rules**: Use validation blocks for constraints
-   **Descriptions**: Provide clear descriptions for all variables
-   **Defaults**: Set sensible defaults where appropriate
-   **Sensitive Data**: Use `sensitive = true` for secrets

### 3. Resource Naming

#### Consistent Naming Convention

```hcl
# Use consistent naming patterns
resource "aws_instance" "web" {
  tags = {
    Name        = "${var.environment}-web-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = var.cost_center
  }
}
```

#### Best Practices

-   **Environment Prefix**: Include environment in resource names
-   **Resource Type**: Indicate resource type in name
-   **Sequential Numbers**: Use for multiple instances
-   **Consistent Tags**: Apply consistent tagging strategy

## 🔒 Security Best Practices

### 1. Network Security

#### Security Group Configuration

```hcl
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-"

  # Allow HTTP from anywhere (for web servers)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # Allow HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = var.tags
}
```

#### Best Practices

-   **Principle of Least Privilege**: Only allow necessary ports
-   **Descriptive Rules**: Add descriptions to all rules
-   **Source Restrictions**: Limit source IPs when possible
-   **Regular Review**: Periodically review security group rules

### 2. Data Protection

#### S3 Bucket Security

```hcl
resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

#### Best Practices

-   **Encryption**: Always enable server-side encryption
-   **Versioning**: Enable versioning for data protection
-   **Public Access**: Block public access by default
-   **Lifecycle Policies**: Implement data lifecycle management

### 3. IAM Best Practices

#### IAM Role Configuration

```hcl
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.environment}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "cloudwatch:PutMetricData"
        ]
        Resource = [
          "${aws_s3_bucket.data.arn}/*",
          "arn:aws:cloudwatch:*:*:metric/*"
        ]
      }
    ]
  })
}
```

#### Best Practices

-   **Least Privilege**: Grant minimum required permissions
-   **Resource-Level Permissions**: Use specific resource ARNs
-   **Role-Based Access**: Use roles instead of access keys
-   **Regular Audits**: Periodically review IAM permissions

## 💰 Cost Optimization Best Practices

### 1. Instance Selection

#### Cost-Effective Instance Types

```hcl
# Use cost-effective instance types
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # Most cost-effective for development

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Only t3.micro, t3.small, or t3.medium are allowed for cost control."
  }
}
```

#### Best Practices

-   **Right-Sizing**: Choose appropriate instance types
-   **Spot Instances**: Use spot instances for non-critical workloads
-   **Auto Scaling**: Implement auto scaling for variable loads
-   **Reserved Instances**: Use reserved instances for predictable workloads

### 2. Storage Optimization

#### S3 Lifecycle Policies

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "cost_optimization"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
```

#### Best Practices

-   **Lifecycle Policies**: Automate data lifecycle management
-   **Storage Classes**: Use appropriate storage classes
-   **Data Archival**: Archive old data to cheaper storage
-   **Cleanup**: Regularly clean up unused data

### 3. Monitoring and Alerting

#### Cost Monitoring

```hcl
resource "aws_cloudwatch_metric_alarm" "cost_alarm" {
  alarm_name          = "${var.environment}-cost-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # 24 hours
  statistic           = "Maximum"
  threshold           = "50"     # $50 threshold
  alarm_description   = "Monthly cost exceeds $50"

  dimensions = {
    Currency = "USD"
  }
}
```

#### Best Practices

-   **Cost Alerts**: Set up cost monitoring and alerts
-   **Budget Limits**: Implement budget limits and notifications
-   **Resource Tagging**: Tag resources for cost allocation
-   **Regular Reviews**: Review costs and optimize regularly

## 🔄 GitOps Best Practices

### 1. Workflow Design

#### Pull Request Workflow

```yaml
# atlantis.yaml
version: 3
projects:
    - name: terraform-atlantis-workshop
      dir: terraform
      workspace: default
      terraform_version: v1.6.0

      # Automatic planning on PR creation
      autoplan:
          when_modified: ["*.tf", "../.gitmodules"]
          enabled: true

      # Require approval before apply
      apply_requirements: [approved]

      # Environment-specific settings
      terraform_vars:
          environment: production
```

#### Best Practices

-   **Approval Requirements**: Require approvals for production changes
-   **Automatic Planning**: Enable automatic plan generation
-   **Environment Separation**: Use different workspaces for environments
-   **Change Tracking**: Track all changes through Git history

### 2. Branching Strategy

#### Git Flow

```
main (production)
├── develop (integration)
├── feature/infrastructure-update
├── feature/new-resource
└── hotfix/critical-fix
```

#### Best Practices

-   **Feature Branches**: Use feature branches for changes
-   **Pull Requests**: All changes through pull requests
-   **Code Review**: Require code reviews before merging
-   **Testing**: Test changes in non-production first

### 3. State Management

#### Remote State Configuration

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-atlantis-workshop-state"
    key    = "terraform.tfstate"
    region = "ap-southeast-1"

    # Enable state locking
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

#### Best Practices

-   **Remote State**: Use remote state storage (S3)
-   **State Locking**: Enable state locking (DynamoDB)
-   **State Encryption**: Encrypt state files
-   **State Backup**: Regularly backup state files

## 📊 Monitoring Best Practices

### 1. Infrastructure Monitoring

#### CloudWatch Alarms

```hcl
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"  # 5 minutes
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CPU utilization exceeds 80%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}
```

#### Best Practices

-   **Key Metrics**: Monitor CPU, memory, disk, network
-   **Alerting**: Set up appropriate alerting thresholds
-   **Escalation**: Implement escalation procedures
-   **Documentation**: Document monitoring and alerting procedures

### 2. Application Monitoring

#### Health Checks

```hcl
resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}
```

#### Best Practices

-   **Health Endpoints**: Implement health check endpoints
-   **Response Time**: Monitor application response times
-   **Error Rates**: Track error rates and types
-   **User Experience**: Monitor from user perspective

## 🧪 Testing Best Practices

### 1. Infrastructure Testing

#### Terraform Testing

```hcl
# Test configuration
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~5.100"
    }
  }
}

# Validate configuration
terraform validate
terraform fmt -check
terraform plan
```

#### Best Practices

-   **Validation**: Always validate Terraform configuration
-   **Formatting**: Use consistent formatting
-   **Planning**: Review plans before applying
-   **Testing**: Test in non-production environments

### 2. Compliance Testing

#### Policy Testing

```hcl
# Test compliance validation
resource "aws_instance" "test_violation" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "m5.large"  # This should fail validation

  tags = {
    Name = "test-violation"
    # Missing required tags
  }
}
```

#### Best Practices

-   **Policy Testing**: Test compliance policies regularly
-   **Violation Testing**: Test violation detection
-   **Policy Updates**: Keep policies up to date
-   **Documentation**: Document all policies and their purposes

## 📚 Documentation Best Practices

### 1. Code Documentation

#### Inline Documentation

```hcl
# VPC for the workshop infrastructure
# This VPC provides network isolation and security
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.environment}-vpc"
  })
}
```

#### Best Practices

-   **Comments**: Add comments for complex logic
-   **Descriptions**: Use descriptive resource names
-   **Documentation**: Keep documentation up to date
-   **Examples**: Provide usage examples

### 2. Operational Documentation

#### Runbook Structure

```markdown
# Operational Runbook

## Overview

Brief description of the infrastructure

## Architecture

High-level architecture diagram

## Procedures

Step-by-step operational procedures

## Troubleshooting

Common issues and solutions

## Contacts

Emergency contact information
```

#### Best Practices

-   **Comprehensive**: Document all operational procedures
-   **Step-by-Step**: Provide detailed step-by-step instructions
-   **Regular Updates**: Keep documentation current
-   **Accessibility**: Make documentation easily accessible

## 🔄 Continuous Improvement

### 1. Regular Reviews

#### Infrastructure Reviews

-   **Monthly**: Review infrastructure costs and performance
-   **Quarterly**: Review security configurations
-   **Annually**: Review architecture and scalability

#### Best Practices

-   **Scheduled Reviews**: Schedule regular review meetings
-   **Metrics Tracking**: Track key performance indicators
-   **Feedback Loop**: Implement feedback from operations
-   **Continuous Learning**: Stay updated with best practices

### 2. Automation

#### CI/CD Pipeline

```yaml
# GitHub Actions workflow
name: Terraform CI/CD
on:
    push:
        branches: [main]
    pull_request:
        branches: [main]

jobs:
    terraform:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v2
            - name: Setup Terraform
              uses: hashicorp/setup-terraform@v1
            - name: Terraform Init
              run: terraform init
            - name: Terraform Validate
              run: terraform validate
            - name: Terraform Plan
              run: terraform plan
```

#### Best Practices

-   **Automation**: Automate repetitive tasks
-   **Testing**: Include testing in CI/CD pipeline
-   **Security**: Implement security scanning
-   **Monitoring**: Monitor pipeline performance

## 📞 Support and Maintenance

### 1. Support Procedures

#### Escalation Matrix

1. **Level 1**: Check documentation and troubleshooting guides
2. **Level 2**: Contact DevOps team lead
3. **Level 3**: Escalate to infrastructure architect
4. **Level 4**: Contact AWS support (if applicable)

#### Best Practices

-   **Clear Procedures**: Define clear escalation procedures
-   **Contact Information**: Maintain up-to-date contact information
-   **Response Times**: Define response time expectations
-   **Documentation**: Document all support procedures

### 2. Maintenance Procedures

#### Regular Maintenance

-   **Security Updates**: Apply security patches regularly
-   **Backup Verification**: Verify backups are working
-   **Performance Monitoring**: Monitor performance metrics
-   **Capacity Planning**: Plan for capacity needs

#### Best Practices

-   **Scheduled Maintenance**: Schedule regular maintenance windows
-   **Change Management**: Follow change management procedures
-   **Testing**: Test changes in non-production first
-   **Communication**: Communicate maintenance schedules

---

**📚 Related Documentation**

-   [Quick Start Guide](quick-start-guide.md)
-   [Deployment Procedures](deployment-procedures.md)
-   [Compliance Validation](compliance-validation.md)
-   [Troubleshooting Guide](troubleshooting-guide.md)
