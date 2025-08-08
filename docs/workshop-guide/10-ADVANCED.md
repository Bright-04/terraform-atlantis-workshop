# Advanced Topics Guide

## 🎯 Overview

This guide covers advanced concepts and best practices for scaling your Terraform Atlantis Workshop infrastructure. You'll learn about multi-environment deployments, security hardening, performance optimization, and enterprise-level features.

## 📋 Prerequisites

Before starting this guide, ensure you have:

-   ✅ **Completed all previous guides** (00-11)
-   ✅ **Understanding of basic concepts**
-   ✅ **Experience with AWS services**
-   ✅ **Familiarity with Terraform**

## 🏗️ Multi-Environment Deployments

### **1. Environment Strategy**

#### **Environment Types**

```hcl
# environments.tf
locals {
  environments = {
    development = {
      instance_type = "t3.micro"
      instance_count = 1
      environment = "development"
      cost_center = "dev"
    }
    staging = {
      instance_type = "t3.small"
      instance_count = 2
      environment = "staging"
      cost_center = "staging"
    }
    production = {
      instance_type = "t3.medium"
      instance_count = 3
      environment = "production"
      cost_center = "prod"
    }
  }
}
```

#### **Workspace-Based Approach**

```bash
# Create workspaces for each environment
terraform workspace new development
terraform workspace new staging
terraform workspace new production

# Switch between environments
terraform workspace select development
terraform plan -var-file="environments/dev.tfvars"

terraform workspace select staging
terraform plan -var-file="environments/staging.tfvars"

terraform workspace select production
terraform plan -var-file="environments/prod.tfvars"
```

### **2. Remote State Management**

#### **S3 Backend Configuration**

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-atlantis-workshop-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

#### **DynamoDB State Locking**

```hcl
# dynamodb.tf
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

### **3. Environment-Specific Configurations**

#### **Variable Files Structure**

```bash
environments/
├── development/
│   ├── terraform.tfvars
│   ├── backend.tf
│   └── providers.tf
├── staging/
│   ├── terraform.tfvars
│   ├── backend.tf
│   └── providers.tf
└── production/
    ├── terraform.tfvars
    ├── backend.tf
    └── providers.tf
```

#### **Environment-Specific Variables**

```hcl
# environments/development/terraform.tfvars
environment = "development"
instance_type = "t3.micro"
instance_count = 1
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
enable_monitoring = false
enable_backup = false

# environments/production/terraform.tfvars
environment = "production"
instance_type = "t3.medium"
instance_count = 3
vpc_cidr = "10.1.0.0/16"
public_subnet_cidr = "10.1.1.0/24"
private_subnet_cidr = "10.1.2.0/24"
enable_monitoring = true
enable_backup = true
```

## 🔒 Security Hardening

### **1. Network Security**

#### **VPC Security**

```hcl
# vpc-security.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Enable VPC Flow Logs
  enable_flow_logs = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flow-logs/${var.project_name}"
  retention_in_days = 7
}
```

#### **Enhanced Security Groups**

```hcl
# security-groups.tf
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  # HTTP access (restrict to specific IPs in production)
  ingress {
    description = "HTTP from specific IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.environment == "production" ? var.allowed_ips : ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS from specific IPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.environment == "production" ? var.allowed_ips : ["0.0.0.0/0"]
  }

  # SSH access (restrict to bastion host in production)
  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.environment == "production" ? [var.bastion_cidr] : ["0.0.0.0/0"]
  }

  # Egress rules
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

### **2. IAM Security**

#### **Enhanced IAM Roles**

```hcl
# iam-roles.tf
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
        Condition = {
          StringEquals = {
            "aws:RequestTag/Environment" = var.environment
          }
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

# Enhanced CloudWatch policy
resource "aws_iam_role_policy" "cloudwatch_enhanced" {
  name = "${var.project_name}-cloudwatch-enhanced"
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
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/${var.project_name}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "CustomMetrics"
          }
        }
      }
    ]
  })
}
```

### **3. Data Protection**

#### **Enhanced S3 Security**

```hcl
# s3-security.tf
resource "aws_s3_bucket" "workshop" {
  bucket = "${var.project_name}-workshop-bucket-${random_string.suffix.result}"

  tags = {
    Name        = "${var.project_name}-workshop-bucket"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = var.cost_center
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "workshop" {
  bucket = aws_s3_bucket.workshop.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "workshop" {
  bucket = aws_s3_bucket.workshop.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Public access blocking
resource "aws_s3_bucket_public_access_block" "workshop" {
  bucket = aws_s3_bucket.workshop.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "workshop" {
  bucket = aws_s3_bucket.workshop.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "delete_old_objects"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}
```

## ⚡ Performance Optimization

### **1. Auto Scaling**

#### **Auto Scaling Group**

```hcl
# autoscaling.tf
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-web-server"
      Environment = var.environment
      Project     = var.project_name
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  desired_capacity    = var.instance_count
  max_size           = var.max_instances
  min_size           = var.min_instances
  target_group_arns  = [aws_lb_target_group.web.arn]
  vpc_zone_identifier = [aws_subnet.public.id]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value              = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }
}

# Scale up policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# Scale down policy
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# CloudWatch alarm for scale up
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2AutoScaling"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Scale up if CPU > 80% for 4 minutes"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

# CloudWatch alarm for scale down
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2AutoScaling"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "Scale down if CPU < 20% for 4 minutes"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}
```

### **2. Load Balancer**

#### **Application Load Balancer**

```hcl
# load-balancer.tf
resource "aws_lb" "web" {
  name               = "${var.project_name}-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id]

  enable_deletion_protection = var.environment == "production"

  tags = {
    Name        = "${var.project_name}-web-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

## 🔄 CI/CD Integration

### **1. GitHub Actions**

#### **Terraform CI/CD Pipeline**

```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
    push:
        branches: [main, develop]
        paths:
            - "terraform/**"
    pull_request:
        branches: [main]
        paths:
            - "terraform/**"

env:
    TF_VERSION: "1.6.0"
    AWS_REGION: "us-east-1"

jobs:
    terraform:
        name: Terraform
        runs-on: ubuntu-latest

        strategy:
            matrix:
                environment: [development, staging, production]

        steps:
            - name: Checkout
              uses: actions/checkout@v3

            - name: Setup Terraform
              uses: hashicorp/setup-terraform@v2
              with:
                  terraform_version: ${{ env.TF_VERSION }}

            - name: Configure AWS Credentials
              uses: aws-actions/configure-aws-credentials@v2
              with:
                  aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
                  aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
                  aws-region: ${{ env.AWS_REGION }}

            - name: Terraform Init
              run: |
                  cd terraform
                  terraform init

            - name: Terraform Format Check
              run: |
                  cd terraform
                  terraform fmt -check

            - name: Terraform Validate
              run: |
                  cd terraform
                  terraform validate

            - name: Terraform Plan
              run: |
                  cd terraform
                  terraform plan -var-file="environments/${{ matrix.environment }}/terraform.tfvars" -out=plan.tfplan
              env:
                  TF_VAR_environment: ${{ matrix.environment }}

            - name: Terraform Apply
              if: github.ref == 'refs/heads/main' && matrix.environment == 'production'
              run: |
                  cd terraform
                  terraform apply plan.tfplan
              env:
                  TF_VAR_environment: ${{ matrix.environment }}

            - name: Upload Plan Artifact
              uses: actions/upload-artifact@v3
              with:
                  name: terraform-plan-${{ matrix.environment }}
                  path: terraform/plan.tfplan
```

### **2. Atlantis Integration**

#### **Enhanced Atlantis Configuration**

```yaml
# atlantis/atlantis.yaml
version: 3
projects:
    - name: terraform-atlantis-workshop
      dir: terraform
      workspace: default
      terraform_version: v1.6.0
      autoplan:
          when_modified: ["*.tf", "../modules/**/*.tf"]
          enabled: true
      apply_requirements: [approved, mergeable]
      workflow: custom
      allowed_overrides: [apply_requirements, workflow]
      allow_custom_workflows: true

workflows:
    custom:
        plan:
            steps:
                - run: terraform plan -out=$PLANFILE
                - run: terraform show -json $PLANFILE > plan.json
                - run: |
                      echo "## Plan Summary" >> $COMMENT_ARGS
                      echo "Resources to be created: $(jq '.resource_changes[] | select(.change.actions[] == "create") | .address' plan.json | wc -l)" >> $COMMENT_ARGS
                      echo "Resources to be modified: $(jq '.resource_changes[] | select(.change.actions[] == "update") | .address' plan.json | wc -l)" >> $COMMENT_ARGS
                      echo "Resources to be destroyed: $(jq '.resource_changes[] | select(.change.actions[] == "delete") | .address' plan.json | wc -l)" >> $COMMENT_ARGS
        apply:
            steps:
                - run: terraform apply $PLANFILE
                - run: |
                      echo "## Apply Summary" >> $COMMENT_ARGS
                      echo "✅ Infrastructure deployed successfully!" >> $COMMENT_ARGS
                      echo "Environment: $ENVIRONMENT" >> $COMMENT_ARGS
                      echo "Resources created: $(terraform state list | wc -l)" >> $COMMENT_ARGS
```

## 📊 Advanced Monitoring

### **1. Custom Metrics**

#### **Application Metrics**

```hcl
# custom-metrics.tf
resource "aws_cloudwatch_metric_alarm" "application_health" {
  alarm_name          = "${var.project_name}-application-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApplicationHealth"
  namespace           = "CustomMetrics"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Application health check failed"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    Environment = var.environment
    Application = var.project_name
  }
}
```

### **2. Log Analytics**

#### **CloudWatch Insights**

```bash
# Query CloudWatch logs
aws logs start-query \
  --log-group-name "/aws/ec2/terraform-atlantis-workshop" \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --end-time $(date -u +%s)000 \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20'
```

## 🎯 Best Practices

### **1. Code Organization**

-   **Use modules** for reusable components
-   **Separate environments** with different configurations
-   **Version control** all infrastructure code
-   **Document** complex configurations

### **2. Security**

-   **Principle of least privilege** for all IAM roles
-   **Encrypt** all data at rest and in transit
-   **Regular security audits** and updates
-   **Monitor** for security events

### **3. Performance**

-   **Right-size resources** based on actual usage
-   **Use auto-scaling** for variable workloads
-   **Implement caching** where appropriate
-   **Monitor performance** metrics

### **4. Cost Optimization**

-   **Use spot instances** for non-critical workloads
-   **Implement lifecycle policies** for data
-   **Monitor costs** daily
-   **Optimize** based on usage patterns

## 🚀 Scaling Strategies

### **1. Horizontal Scaling**

-   **Auto Scaling Groups** for compute resources
-   **Load balancers** for traffic distribution
-   **Database read replicas** for read scaling
-   **CDN** for static content delivery

### **2. Vertical Scaling**

-   **Instance type upgrades** for increased capacity
-   **Storage optimization** for better performance
-   **Memory and CPU tuning** for applications
-   **Database optimization** for better throughput

### **3. Geographic Scaling**

-   **Multi-region deployments** for global users
-   **Route 53** for traffic routing
-   **Global Accelerator** for improved performance
-   **Edge locations** for content delivery

---

**Ready for production?** You now have a comprehensive, scalable, and secure infrastructure setup!
