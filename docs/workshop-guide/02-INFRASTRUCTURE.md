# Terraform Infrastructure Guide

## 🎯 Overview

This guide explains the Terraform infrastructure components in the workshop. You'll learn about the project structure, main resources, and how everything works together.

## 📋 Prerequisites

Before starting this guide, ensure you have:

-   ✅ **Environment set up** (01-SETUP.md)
-   ✅ **Basic understanding** of AWS services
-   ✅ **Terraform installed** and working

## 🏗️ Project Structure

### **Directory Layout**

```
terraform-atlantis-workshop/
├── terraform/
│   ├── main.tf                 # Main infrastructure configuration
│   ├── variables.tf            # Variable definitions
│   ├── outputs.tf              # Output values
│   ├── compliance-validation.tf # Compliance policies
│   ├── test-policy-violations.tf # Test resources for compliance
│   ├── terraform.tfvars        # Variable values
│   └── terraform.tfvars.example # Example variable values
├── atlantis/
│   └── atlantis.yaml          # Atlantis configuration
├── policies/
│   ├── cost_control.rego      # Cost control policies
│   └── terraform_security.rego # Security policies
├── scripts/
│   ├── deploy-aws.ps1         # AWS deployment script
│   └── rollback.ps1           # Rollback script
└── docs/                      # Documentation
```

### **File Purposes**

#### **Main Configuration Files**

-   **`main.tf`**: Core infrastructure resources (VPC, EC2, S3, etc.)
-   **`variables.tf`**: Input variable definitions and validations
-   **`outputs.tf`**: Output values for external consumption
-   **`compliance-validation.tf`**: Policy enforcement and validation rules

#### **Configuration Files**

-   **`terraform.tfvars`**: Actual variable values for deployment
-   **`terraform.tfvars.example`**: Example values for reference

#### **Test Files**

-   **`test-policy-violations.tf`**: Resources for testing compliance policies

## 🏗️ Infrastructure Components

### **1. Networking Layer**

#### **VPC Configuration**

```hcl
# VPC with custom CIDR block
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

#### **Subnet Configuration**

```hcl
# Public subnet for web servers
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Private subnet for internal resources
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.region}b"

  tags = {
    Name        = "${var.project_name}-private-subnet"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

#### **Internet Gateway and Routing**

```hcl
# Internet Gateway for public internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

### **2. Compute Layer**

#### **EC2 Instance Configuration**

```hcl
# Web server instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "workshop-participant"
    TestTag     = "aws-production-deployment"
    Timestamp   = formatdate("YYYY-MM-DD-hhmm", timestamp())
    CostCenter  = "production"
    Backup      = "daily"
  }

  depends_on = [aws_internet_gateway.main]
}
```

#### **Security Groups**

```hcl
# Security group for web server
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

  # HTTP access
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access (restrict in production)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-web-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

### **3. Storage Layer**

#### **S3 Bucket Configuration**

```hcl
# Main workshop bucket
resource "aws_s3_bucket" "workshop" {
  bucket = "${var.project_name}-workshop-bucket"

  tags = {
    Name        = "${var.project_name}-workshop-bucket"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "workshop"
  }
}

# Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "workshop" {
  bucket = aws_s3_bucket.workshop.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "workshop" {
  bucket = aws_s3_bucket.workshop.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "workshop" {
  bucket = aws_s3_bucket.workshop.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### **4. IAM Layer**

#### **IAM Role and Policy**

```hcl
# IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

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

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM policy for CloudWatch logs
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.project_name}-cloudwatch-logs"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# Instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
```

### **5. Monitoring Layer**

#### **CloudWatch Configuration**

```hcl
# CloudWatch log group
resource "aws_cloudwatch_log_group" "workshop" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-log-group"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

## 🔧 Variables and Configuration

### **1. Variable Definitions**

#### **`variables.tf`**

```hcl
# AWS Configuration
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "workshop"

  validation {
    condition     = contains(["development", "staging", "production", "workshop"], var.environment)
    error_message = "Environment must be one of: development, staging, production, workshop."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "terraform-atlantis-workshop"
}

# Network Configuration
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR block"
  type        = string
  default     = "10.0.2.0/24"
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium for cost control."
  }
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
  default     = ""
}
```

### **2. Variable Values**

#### **`terraform.tfvars`**

```hcl
# AWS Configuration
region = "us-east-1"
environment = "production"
project_name = "terraform-atlantis-workshop"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

# EC2 Configuration
instance_type = "t3.micro"
# key_pair_name = "your-key-pair-name"  # Optional
```

## 📤 Outputs

### **`outputs.tf`**

```hcl
# Network Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

# Compute Outputs
output "instance_id" {
  description = "Web server instance ID"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Web server public IP"
  value       = aws_instance.web.public_ip
}

output "website_url" {
  description = "Website URL"
  value       = "http://${aws_instance.web.public_ip}"
}

# Storage Outputs
output "s3_bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.workshop.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.workshop.arn
}

# Compliance Outputs
output "compliance_validation_status" {
  description = "Compliance validation status"
  value = {
    total_instances = length(local.ec2_instances)
    total_buckets   = length(local.s3_buckets)
    allowed_instance_types = local.allowed_instance_types
    required_tags = local.required_tags
    message = "Compliance validation framework active"
  }
}
```

## 🔍 Data Sources

### **AMI Selection**

```hcl
# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

## 🚀 User Data Script

### **`user_data.sh`**

```bash
#!/bin/bash
# User data script for web server

# Update system
yum update -y

# Install Apache
yum install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create custom webpage
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>${project_name}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #f8f9fa; padding: 20px; border-radius: 5px; }
        .info { margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Hello from ${project_name} on AWS!</h1>
        </div>
        <div class="info">
            <h2>Instance Information</h2>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
            <p><strong>Instance Type:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</p>
            <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
            <p><strong>Launch Time:</strong> $(date)</p>
        </div>
        <div class="info">
            <h2>This instance was created with Terraform on AWS Production.</h2>
            <p>Features:</p>
            <ul>
                <li>Infrastructure as Code with Terraform</li>
                <li>Compliance validation framework</li>
                <li>GitOps workflow with Atlantis</li>
                <li>Security best practices</li>
                <li>Cost optimization</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Configure CloudWatch logs
yum install -y awslogs

# Configure AWS CLI region
aws configure set region us-east-1

# Start and enable CloudWatch logs
systemctl start awslogsd
systemctl enable awslogsd
```

## 🔄 Resource Dependencies

### **Dependency Graph**

```
aws_vpc.main
├── aws_subnet.public
├── aws_subnet.private
├── aws_internet_gateway.main
│   └── aws_route_table.public
│       └── aws_route_table_association.public
└── aws_security_group.web
    └── aws_instance.web
        └── aws_iam_instance_profile.ec2_profile
            └── aws_iam_role.ec2_role
                └── aws_iam_role_policy.cloudwatch_logs

aws_s3_bucket.workshop
├── aws_s3_bucket_server_side_encryption_configuration.workshop
├── aws_s3_bucket_versioning.workshop
└── aws_s3_bucket_public_access_block.workshop
```

## 🧪 Testing Infrastructure

### **1. Local Testing**

```bash
# Validate configuration
terraform validate

# Format code
terraform fmt

# Plan deployment
terraform plan

# Apply changes
terraform apply
```

### **2. Testing Individual Components**

```bash
# Test VPC configuration
terraform plan -target=aws_vpc.main

# Test EC2 instance
terraform plan -target=aws_instance.web

# Test S3 bucket
terraform plan -target=aws_s3_bucket.workshop
```

### **3. Testing Compliance**

```bash
# Test compliance policies
terraform plan

# Look for compliance validation outputs
terraform output compliance_validation_status
```

## 📊 Resource Costs

### **Estimated Monthly Costs**

```
Resource Type          | Monthly Cost | Notes
----------------------|--------------|------------------
EC2 t3.micro (2x)     | ~$16-20      | Main cost driver
S3 Storage (1GB)      | ~$0.023      | Minimal cost
CloudWatch Logs       | ~$0.50       | Minimal cost
Data Transfer         | ~$0.09/GB    | Usage-based
Total Estimated       | ~$20-30      | Per month
```

## 🎯 Best Practices

### **1. Security**

-   **Use security groups** to restrict access
-   **Enable S3 encryption** for data protection
-   **Use IAM roles** instead of access keys
-   **Implement least privilege** access

### **2. Cost Optimization**

-   **Use appropriate instance types** for workload
-   **Enable S3 lifecycle policies** for old data
-   **Monitor usage** with CloudWatch
-   **Use spot instances** for non-critical workloads

### **3. Maintainability**

-   **Use variables** for configuration
-   **Implement tagging** for resource management
-   **Use data sources** for dynamic values
-   **Document dependencies** clearly

## 🚨 Troubleshooting

### **1. Common Issues**

#### **Instance Not Starting**

```bash
# Check instance status
aws ec2 describe-instances --instance-ids i-1234567890abcdef0

# Check system logs
aws ec2 get-console-output --instance-id i-1234567890abcdef0
```

#### **Security Group Issues**

```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-1234567890abcdef0
```

#### **S3 Access Issues**

```bash
# Check bucket permissions
aws s3api get-bucket-policy --bucket terraform-atlantis-workshop-workshop-bucket
```

### **2. Debugging Commands**

```bash
# Check Terraform state
terraform state list
terraform state show aws_instance.web

# Check AWS resources directly
aws ec2 describe-instances --filters "Name=tag:Project,Values=terraform-atlantis-workshop"

# Check CloudWatch logs
aws logs describe-log-streams --log-group-name "/aws/ec2/terraform-atlantis-workshop"
```

## 📞 Support

If you encounter infrastructure issues:

1. **Check the troubleshooting guide** (09-TROUBLESHOOTING.md)
2. **Verify AWS permissions** and credentials
3. **Review Terraform configuration** for syntax errors
4. **Check resource dependencies** and order
5. **Monitor CloudWatch logs** for application issues

---

**Infrastructure understood?** Continue to [03-LOCALSTACK.md](03-LOCALSTACK.md) to test locally!
