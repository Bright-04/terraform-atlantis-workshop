# AWS Production Setup

## Overview

This guide provides comprehensive instructions for setting up a production-ready AWS infrastructure using Terraform and Atlantis. It covers security best practices, high availability, monitoring, and operational considerations for production environments.

## Production Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Production Environment                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐ │
│  │   Public Zone   │    │  Private Zone   │    │  Database   │ │
│  │                 │    │                 │    │    Zone     │ │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────┐ │ │
│  │ │ Application │ │    │ │ Application │ │    │ │ RDS     │ │ │
│  │ │ Load        │ │    │ │ Servers     │ │    │ │ Cluster │ │ │
│  │ │ Balancer    │ │    │ │ (Auto       │ │    │ └─────────┘ │ │
│  │ └─────────────┘ │    │ │ Scaling)    │ │    │             │ │
│  │                 │    │ └─────────────┘ │    │ ┌─────────┐ │ │
│  │ ┌─────────────┐ │    │                 │    │ │ Elasti  │ │ │
│  │ │ Bastion     │ │    │ ┌─────────────┐ │    │ │ Cache   │ │ │
│  │ │ Host        │ │    │ │ Monitoring  │ │    │ └─────────┘ │ │
│  │ └─────────────┘ │    │ │ & Logging   │ │    │             │ │
│  └─────────────────┘    │ └─────────────┘ │    └─────────────┘ │
│                         └─────────────────┘                    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    Shared Services                          │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │ │
│  │  │ S3 State    │  │ CloudWatch  │  │ VPC Flow    │         │ │
│  │  │ Bucket      │  │ Logs        │  │ Logs        │         │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘         │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Multi-AZ Deployment

```hcl
# terraform/production/main.tf
locals {
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  environment        = "production"
}

# VPC with multiple AZs
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${local.environment}-vpc"
    Environment = local.environment
  }
}

# Public subnets across AZs
resource "aws_subnet" "public" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = local.availability_zones[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${local.environment}-public-${local.availability_zones[count.index]}"
    Environment = local.environment
  }
}

# Private subnets across AZs
resource "aws_subnet" "private" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = local.availability_zones[count.index]
  
  tags = {
    Name        = "${local.environment}-private-${local.availability_zones[count.index]}"
    Environment = local.environment
  }
}
```

## Security Configuration

### 1. Network Security

#### VPC Configuration

```hcl
# terraform/production/network.tf
# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "${local.environment}-igw"
    Environment = local.environment
  }
}

# NAT Gateway for private subnets
resource "aws_eip" "nat" {
  count = length(local.availability_zones)
  vpc   = true
  
  tags = {
    Name        = "${local.environment}-nat-eip-${count.index}"
    Environment = local.environment
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(local.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name        = "${local.environment}-nat-${count.index}"
    Environment = local.environment
  }
  
  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name        = "${local.environment}-public-rt"
    Environment = local.environment
  }
}

resource "aws_route_table" "private" {
  count  = length(local.availability_zones)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = {
    Name        = "${local.environment}-private-rt-${count.index}"
    Environment = local.environment
  }
}
```

#### Security Groups

```hcl
# terraform/production/security.tf
# Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  name        = "${local.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
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
    Name        = "${local.environment}-alb-sg"
    Environment = local.environment
  }
}

# Application Server Security Group
resource "aws_security_group" "app" {
  name        = "${local.environment}-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${local.environment}-app-sg"
    Environment = local.environment
  }
}

# Bastion Host Security Group
resource "aws_security_group" "bastion" {
  name        = "${local.environment}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_bastion_cidrs
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${local.environment}-bastion-sg"
    Environment = local.environment
  }
}
```

### 2. IAM Configuration

#### IAM Roles and Policies

```hcl
# terraform/production/iam.tf
# EC2 Instance Role
resource "aws_iam_role" "ec2_role" {
  name = "${local.environment}-ec2-role"
  
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
    Name        = "${local.environment}-ec2-role"
    Environment = local.environment
  }
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Policy
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${local.environment}-ec2-policy"
  role = aws_iam_role.ec2_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Atlantis Role for Terraform Operations
resource "aws_iam_role" "atlantis_role" {
  name = "${local.environment}-atlantis-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.atlantis_account_id}:role/atlantis-role"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${local.environment}-atlantis-role"
    Environment = local.environment
  }
}

# Atlantis Policy
resource "aws_iam_role_policy" "atlantis_policy" {
  name = "${local.environment}-atlantis-policy"
  role = aws_iam_role.atlantis_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "vpc:*",
          "s3:*",
          "rds:*",
          "iam:*",
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## Application Infrastructure

### 1. Load Balancer Configuration

```hcl
# terraform/production/alb.tf
# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${local.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = true
  
  tags = {
    Name        = "${local.environment}-alb"
    Environment = local.environment
  }
}

# ALB Target Group
resource "aws_lb_target_group" "main" {
  name     = "${local.environment}-tg"
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
  
  tags = {
    Name        = "${local.environment}-tg"
    Environment = local.environment
  }
}

# ALB Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
```

### 2. Auto Scaling Group

```hcl
# terraform/production/asg.tf
# Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${local.environment}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = local.environment
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${local.environment}-instance"
      Environment = local.environment
    }
  }
  
  tags = {
    Name        = "${local.environment}-launch-template"
    Environment = local.environment
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "${local.environment}-asg"
  desired_capacity    = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  target_group_arns  = [aws_lb_target_group.main.arn]
  vpc_zone_identifier = aws_subnet.private[*].id
  
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value              = "${local.environment}-asg"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Environment"
    value              = local.environment
    propagate_at_launch = true
  }
}

# Auto Scaling Policy
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${local.environment}-cpu-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

# CloudWatch Alarm for CPU
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${local.environment}-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
  
  alarm_description = "This metric monitors EC2 CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.cpu.arn]
}
```

### 3. Database Configuration

```hcl
# terraform/production/rds.tf
# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${local.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = {
    Name        = "${local.environment}-db-subnet-group"
    Environment = local.environment
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "${local.environment}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  
  tags = {
    Name        = "${local.environment}-rds-sg"
    Environment = local.environment
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${local.environment}-db"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class
  
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  multi_az = true
  
  skip_final_snapshot = false
  final_snapshot_identifier = "${local.environment}-db-final-snapshot"
  
  tags = {
    Name        = "${local.environment}-db"
    Environment = local.environment
  }
}
```

## Monitoring and Logging

### 1. CloudWatch Configuration

```hcl
# terraform/production/monitoring.tf
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${local.environment}-app"
  retention_in_days = 30
  
  tags = {
    Name        = "${local.environment}-app-logs"
    Environment = local.environment
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.environment}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Metrics"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main.id],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeableMemory", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Metrics"
        }
      }
    ]
  })
}
```

### 2. VPC Flow Logs

```hcl
# terraform/production/flow-logs.tf
# VPC Flow Logs
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  
  tags = {
    Name        = "${local.environment}-flow-logs"
    Environment = local.environment
  }
}

# Flow Logs IAM Role
resource "aws_iam_role" "flow_log_role" {
  name = "${local.environment}-flow-log-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# Flow Logs Policy
resource "aws_iam_role_policy" "flow_log_policy" {
  name = "${local.environment}-flow-log-policy"
  role = aws_iam_role.flow_log_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Flow Logs CloudWatch Log Group
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flowlogs/${local.environment}"
  retention_in_days = 30
  
  tags = {
    Name        = "${local.environment}-flow-logs"
    Environment = local.environment
  }
}
```

## Backup and Disaster Recovery

### 1. S3 Backup Configuration

```hcl
# terraform/production/backup.tf
# S3 Bucket for Backups
resource "aws_s3_bucket" "backup" {
  bucket = "${var.project_name}-${local.environment}-backup-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "${local.environment}-backup-bucket"
    Environment = local.environment
  }
}

# Random string for bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  
  rule {
    id     = "backup_lifecycle"
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

### 2. RDS Backup Configuration

```hcl
# terraform/production/rds-backup.tf
# RDS Snapshot Schedule
resource "aws_db_instance" "main" {
  # ... existing configuration ...
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  
  copy_tags_to_snapshot = true
  
  # Enable automated backups
  delete_automated_backups = false
  
  # Enable point-in-time recovery
  storage_encrypted = true
  
  # ... rest of configuration ...
}
```

## Deployment Configuration

### 1. Variables

```hcl
# terraform/production/variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "RDS maximum allocated storage in GB"
  type        = number
  default     = 100
}

variable "allowed_bastion_cidrs" {
  description = "Allowed CIDR blocks for bastion access"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}
```

### 2. Outputs

```hcl
# terraform/production/outputs.tf
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = aws_instance.bastion.public_ip
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.main.name
}
```

## Deployment Commands

### 1. Initial Deployment

```bash
# Navigate to production directory
cd terraform/production

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var-file="production.tfvars"

# Apply the configuration
terraform apply -var-file="production.tfvars"
```

### 2. Atlantis Deployment

```bash
# Create a pull request with changes
git checkout -b production-deployment
git add .
git commit -m "Deploy production infrastructure"
git push origin production-deployment

# Atlantis will automatically run plan
# Review the plan and approve with:
atlantis apply
```

## Security Checklist

- [ ] VPC with private subnets configured
- [ ] Security groups with minimal required access
- [ ] IAM roles with least privilege access
- [ ] RDS encryption enabled
- [ ] S3 bucket encryption enabled
- [ ] VPC Flow Logs enabled
- [ ] CloudWatch monitoring configured
- [ ] Backup and retention policies set
- [ ] Bastion host for secure access
- [ ] Multi-AZ deployment for high availability

## Cost Optimization

### 1. Instance Scheduling

```hcl
# terraform/production/scheduling.tf
# Auto Scaling Schedule for non-business hours
resource "aws_autoscaling_schedule" "scale_down" {
  count                  = var.enable_scheduling ? 1 : 0
  scheduled_action_name  = "scale-down-night"
  min_size              = 1
  max_size              = 1
  desired_capacity      = 1
  recurrence           = "0 22 * * MON-FRI"
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_autoscaling_schedule" "scale_up" {
  count                  = var.enable_scheduling ? 1 : 0
  scheduled_action_name  = "scale-up-morning"
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
  recurrence           = "0 6 * * MON-FRI"
  autoscaling_group_name = aws_autoscaling_group.main.name
}
```

### 2. Reserved Instances

Consider purchasing Reserved Instances for predictable workloads to reduce costs by up to 75%.

## Next Steps

After production deployment:

1. **Monitor Performance**: Set up CloudWatch dashboards and alerts
2. **Security Auditing**: Regular security assessments and penetration testing
3. **Backup Testing**: Test backup and recovery procedures
4. **Load Testing**: Perform load testing to validate performance
5. **Documentation**: Update runbooks and procedures

## Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/security/security-learning/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
