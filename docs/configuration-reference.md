# Configuration Reference - Terraform Atlantis Workshop

## ⚙️ Complete Configuration Guide

This document provides comprehensive configuration reference for all components in the **Environment Provisioning Automation with Terraform and Atlantis** workshop.

## 🏗️ Atlantis Configuration

### atlantis.yaml

#### Basic Configuration

```yaml
version: 3
projects:
    - name: terraform-atlantis-workshop
      dir: terraform
      workspace: default
      terraform_version: v1.6.0
      autoplan:
          when_modified: ["*.tf", "../.github/workflows/*.yml"]
          enabled: true
      apply_requirements: [approved, mergeable]
      workflow: custom
      custom_apply_workflow: aws-production
      custom_plan_workflow: aws-production
```

#### Workflow Configuration

```yaml
workflows:
    aws-production:
        plan:
            steps:
                - run: |
                      echo "🔧 Initializing Terraform..."
                      terraform init -input=false
                      if [ $? -ne 0 ]; then
                          echo "❌ Terraform init failed"
                          exit 1
                      fi
                - run: |
                      echo "🔍 Checking Terraform formatting..."
                      if terraform fmt -check -recursive; then
                          echo "✅ Terraform formatting is correct"
                      else
                          echo "❌ Terraform formatting check failed"
                          echo "Please run 'terraform fmt -recursive' to fix formatting issues"
                          exit 1
                      fi
                - run: |
                      echo "🔍 Validating Terraform configuration..."
                      if terraform validate; then
                          echo "✅ Terraform configuration is valid"
                      else
                          echo "❌ Terraform validation failed"
                          echo "Please check your Terraform configuration for syntax errors"
                          exit 1
                      fi
                - run: |
                      echo "🛡️ Running security policy validation..."
                      opa test policies/ --verbose
                      if [ $? -ne 0 ]; then
                          echo "❌ Security policy validation failed"
                          exit 1
                      fi
                      echo "✅ Security policies validated"
                - run: |
                      echo "💰 Running cost estimation..."
                      terraform plan -out=tfplan -detailed-exitcode
                      PLAN_EXIT_CODE=$?

                      if [ $PLAN_EXIT_CODE -eq 0 ]; then
                          echo "✅ No changes needed"
                      elif [ $PLAN_EXIT_CODE -eq 2 ]; then
                          echo "📋 Changes detected, running cost analysis..."
                          # Add cost analysis here if tools available
                          echo "✅ Plan created successfully"
                      else
                          echo "❌ Terraform plan failed"
                          exit 1
                      fi
                - run: |
                      echo "📊 Generating plan summary..."
                      terraform show -json tfplan | jq -r '
                          .resource_changes[] | 
                          select(.change.actions[] | contains("create") or contains("update") or contains("delete")) |
                          "\(.change.actions | join(",")): \(.address)"
                      ' | sort | uniq -c
                      echo "✅ Plan validation completed"

        apply:
            steps:
                - run: |
                      echo "🚀 Applying Terraform configuration..."
                      terraform apply tfplan
                      if [ $? -eq 0 ]; then
                          echo "✅ Terraform apply completed successfully"
                      else
                          echo "❌ Terraform apply failed"
                          exit 1
                      fi
                - run: |
                      echo "🔍 Post-apply validation..."
                      terraform output -json > outputs.json
                      echo "✅ Infrastructure deployment completed"
                - run: |
                      echo "📋 Updating resource inventory..."
                      terraform state list > resource-inventory.txt
                      echo "✅ Resource inventory updated"
```

#### Advanced Configuration Options

**Project-Level Settings:**

```yaml
projects:
    - name: terraform-atlantis-workshop
      dir: terraform
      workspace: default
      terraform_version: v1.6.0

      # Autoplan configuration
      autoplan:
          when_modified: ["*.tf", "*.tfvars", "../policies/*.rego"]
          enabled: true

      # Apply requirements
      apply_requirements:
          - approved
          - mergeable
          - undiverged

      # Workflow customization
      workflow: aws-production

      # Delete source branch after merge
      delete_source_branch_on_merge: true

      # Repo locking
      repo_locking: true

      # Custom environment variables
      env:
          - name: AWS_DEFAULT_REGION
            value: us-west-2
          - name: TF_VAR_environment
            value: production
          - name: TF_VAR_project_name
            value: terraform-atlantis-workshop
```

**Global Settings:**

```yaml
# Global configuration
version: 3

# Default apply requirements for all projects
apply_requirements: [approved, mergeable]

# Default workflow for all projects
workflow: default

# Allowed overrides
allowed_overrides: [apply_requirements, workflow]

# Allowed workflows
allowed_workflows: [default, aws-production, staging]

# Delete source branch after successful merge
delete_source_branch_on_merge: true

# Repository locking
repo_locking: true

# Parallel planning
parallel_plan: true

# Parallel applying
parallel_apply: false
```

### Server Configuration

#### Command Line Options

```bash
atlantis server \
  --atlantis-url="https://your-atlantis-domain.com" \
  --gh-user="atlantis-bot" \
  --gh-token="$GITHUB_TOKEN" \
  --gh-webhook-secret="$GITHUB_WEBHOOK_SECRET" \
  --repo-allowlist="github.com/Bright-04/*" \
  --port=4141 \
  --data-dir="/atlantis-data" \
  --log-level="info" \
  --stats-namespace="atlantis" \
  --enable-policy-checks \
  --policy-check-type="conftest"
```

#### Environment Variables

```bash
# GitHub Configuration
export ATLANTIS_GH_TOKEN="your-github-token"
export ATLANTIS_GH_WEBHOOK_SECRET="your-webhook-secret"
export ATLANTIS_GH_USER="atlantis-bot"

# Server Configuration
export ATLANTIS_ATLANTIS_URL="https://your-atlantis-domain.com"
export ATLANTIS_PORT="4141"
export ATLANTIS_DATA_DIR="/atlantis-data"
export ATLANTIS_LOG_LEVEL="info"

# Repository Configuration
export ATLANTIS_REPO_ALLOWLIST="github.com/Bright-04/*"

# Security Configuration
export ATLANTIS_ENABLE_POLICY_CHECKS="true"
export ATLANTIS_POLICY_CHECK_TYPE="conftest"

# AWS Configuration
export AWS_DEFAULT_REGION="us-west-2"
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"

# Terraform Configuration
export TF_PLUGIN_CACHE_DIR="/tmp/terraform-plugins"
export TF_LOG="INFO"
```

## 🐳 Docker Configuration

### docker-compose.yml

#### Basic Setup

```yaml
version: "3.8"

services:
    atlantis:
        image: runatlantis/atlantis:v0.27.0
        container_name: atlantis_server
        restart: unless-stopped
        ports:
            - "4141:4141"
        environment:
            # GitHub Configuration
            ATLANTIS_GH_TOKEN: ${GITHUB_TOKEN}
            ATLANTIS_GH_WEBHOOK_SECRET: ${GITHUB_WEBHOOK_SECRET}
            ATLANTIS_GH_USER: ${GITHUB_USER:-atlantis-bot}

            # Server Configuration
            ATLANTIS_ATLANTIS_URL: ${ATLANTIS_URL:-http://localhost:4141}
            ATLANTIS_PORT: 4141
            ATLANTIS_DATA_DIR: /atlantis-data
            ATLANTIS_LOG_LEVEL: ${LOG_LEVEL:-info}

            # Repository Configuration
            ATLANTIS_REPO_ALLOWLIST: "github.com/Bright-04/*"

            # AWS Configuration
            AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION:-us-west-2}
            AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
            AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}

            # Policy Configuration
            ATLANTIS_ENABLE_POLICY_CHECKS: "true"
            ATLANTIS_POLICY_CHECK_TYPE: "conftest"

            # Terraform Configuration
            TF_PLUGIN_CACHE_DIR: /tmp/terraform-plugins

        volumes:
            - atlantis-data:/atlantis-data
            - ./atlantis.yaml:/atlantis.yaml:ro
            - ./policies:/policies:ro
            - terraform-plugins:/tmp/terraform-plugins

        command: |
            atlantis server
            --config=/atlantis.yaml
            --write-git-creds

        healthcheck:
            test: ["CMD", "curl", "-f", "http://localhost:4141/healthz"]
            interval: 30s
            timeout: 10s
            retries: 3
            start_period: 40s

volumes:
    atlantis-data:
        driver: local
    terraform-plugins:
        driver: local

networks:
    default:
        name: atlantis-network
```

#### Production Setup

```yaml
version: "3.8"

services:
    atlantis:
        image: runatlantis/atlantis:v0.27.0
        container_name: atlantis_production
        restart: always

        # Resource limits
        deploy:
            resources:
                limits:
                    memory: 2G
                    cpus: "1.0"
                reservations:
                    memory: 1G
                    cpus: "0.5"

        ports:
            - "4141:4141"

        environment:
            # Production-specific settings
            ATLANTIS_LOG_LEVEL: "warn"
            ATLANTIS_STATS_NAMESPACE: "atlantis.production"
            ATLANTIS_ENABLE_DIFF_MARKDOWN_FORMAT: "true"
            ATLANTIS_MARKDOWN_TEMPLATE_OVERRIDES_DIR: "/templates"

            # Security settings
            ATLANTIS_HIDE_PREV_PLAN_COMMENTS: "true"
            ATLANTIS_ENABLE_REGEXP_CMD: "false"
            ATLANTIS_DISABLE_APPLY_ALL: "true"

            # Performance settings
            ATLANTIS_PARALLEL_POOL_SIZE: "5"
            ATLANTIS_CHECKOUT_STRATEGY: "merge"

        volumes:
            - /opt/atlantis/data:/atlantis-data
            - /opt/atlantis/config:/config:ro
            - /opt/atlantis/templates:/templates:ro
            - /var/log/atlantis:/var/log/atlantis

        logging:
            driver: "json-file"
            options:
                max-size: "100m"
                max-file: "3"

        labels:
            - "traefik.enable=true"
            - "traefik.http.routers.atlantis.rule=Host(`atlantis.yourdomain.com`)"
            - "traefik.http.routers.atlantis.tls=true"
            - "traefik.http.routers.atlantis.tls.certresolver=letsencrypt"

    # Optional: Add nginx reverse proxy
    nginx:
        image: nginx:alpine
        container_name: atlantis_nginx
        ports:
            - "80:80"
            - "443:443"
        volumes:
            - ./nginx.conf:/etc/nginx/nginx.conf:ro
            - ./ssl:/etc/nginx/ssl:ro
        depends_on:
            - atlantis
```

## 🔧 Terraform Configuration

### terraform/variables.tf

#### Core Variables

```hcl
# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-atlantis-workshop"

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 50
    error_message = "Project name must be between 1 and 50 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.region))
    error_message = "Region must be a valid AWS region identifier."
  }
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "t3.xlarge", "t3.2xlarge", "t3a.micro", "t3a.small",
      "t3a.medium", "t3a.large", "t3a.xlarge", "t3a.2xlarge"
    ], var.instance_type)
    error_message = "Instance type must be a valid t3 or t3a instance type."
  }
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 1 && var.min_size <= 10
    error_message = "Minimum size must be between 1 and 10."
  }
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 3

  validation {
    condition     = var.max_size >= 1 && var.max_size <= 20
    error_message = "Maximum size must be between 1 and 20."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= 1
    error_message = "Desired capacity must be at least 1."
  }
}

# Security Configuration
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for load balancer"
  type        = bool
  default     = false
}

# Cost Control Configuration
variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "engineering"

  validation {
    condition     = length(var.cost_center) > 0
    error_message = "Cost center must not be empty."
  }
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 100

  validation {
    condition     = var.budget_limit > 0 && var.budget_limit <= 1000
    error_message = "Budget limit must be between 1 and 1000 USD."
  }
}

# Backup Configuration
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 1 and 35 days."
  }
}

# Feature Flags
variable "enable_waf" {
  description = "Enable AWS WAF for the application"
  type        = bool
  default     = false
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail logging"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config for compliance monitoring"
  type        = bool
  default     = true
}

# Advanced Configuration
variable "custom_tags" {
  description = "Custom tags to apply to all resources"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key in keys(var.custom_tags) : can(regex("^[a-zA-Z][a-zA-Z0-9_-]*$", key))
    ])
    error_message = "Tag keys must start with a letter and contain only letters, numbers, underscores, and hyphens."
  }
}

variable "notification_email" {
  description = "Email address for notifications"
  type        = string
  default     = ""

  validation {
    condition = var.notification_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Must be a valid email address or empty string."
  }
}
```

### terraform/versions.tf

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }

  # Backend configuration for state management
  backend "s3" {
    # Configure via backend config file or environment variables
    # bucket         = "your-terraform-state-bucket"
    # key            = "terraform-atlantis-workshop/terraform.tfstate"
    # region         = "us-west-2"
    # dynamodb_table = "terraform-state-lock"
    # encrypt        = true
  }
}

# Provider configuration
provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "terraform"
        Repository  = "terraform-atlantis-workshop"
        CreatedBy   = "atlantis"
      },
      var.custom_tags
    )
  }
}

# Data sources for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
```

### terraform/terraform.tfvars.example

```hcl
# Project Configuration
project_name = "terraform-atlantis-workshop"
environment  = "production"
region       = "us-west-2"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# EC2 Configuration
instance_type     = "t3.micro"
min_size         = 1
max_size         = 3
desired_capacity = 2

# Security Configuration
allowed_cidr_blocks = ["0.0.0.0/0"]  # Restrict this in production

# Monitoring and Features
enable_detailed_monitoring  = true
enable_deletion_protection = false
enable_waf                 = false
enable_cloudtrail         = true
enable_config             = true

# Cost Control
cost_center    = "engineering"
budget_limit   = 100

# Backup Configuration
backup_retention_days = 7

# Notifications
notification_email = "admin@example.com"

# Custom Tags
custom_tags = {
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  Application = "Workshop"
}
```

## 🛡️ Policy Configuration

### policies/terraform_security.rego

```rego
package terraform.security

# Import future keywords for better performance
import future.keywords.in
import future.keywords.if

# Security group rules validation
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    rule := resource.change.after.ingress[_]

    # Check for overly permissive CIDR blocks
    cidr := rule.cidr_blocks[_]
    cidr == "0.0.0.0/0"

    # Allow only specific ports for public access
    not rule.from_port in [80, 443]

    msg := sprintf("Security group '%s' has overly permissive ingress rule for port %d from 0.0.0.0/0", [resource.address, rule.from_port])
}

# Ensure encryption is enabled for EBS volumes
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"

    ebs_block_device := resource.change.after.ebs_block_device[_]
    not ebs_block_device.encrypted

    msg := sprintf("EBS volume for instance '%s' must be encrypted", [resource.address])
}

# Ensure S3 buckets have encryption enabled
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"

    not resource.change.after.server_side_encryption_configuration

    msg := sprintf("S3 bucket '%s' must have server-side encryption enabled", [resource.address])
}

# Require specific instance types for cost control
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"

    instance_type := resource.change.after.instance_type
    not instance_type in ["t3.micro", "t3.small", "t3.medium"]

    msg := sprintf("Instance '%s' uses instance type '%s' which is not in the approved list", [resource.address, instance_type])
}

# Ensure proper tagging
required_tags := ["Project", "Environment", "ManagedBy"]

deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["aws_instance", "aws_security_group", "aws_vpc", "aws_subnet"]

    tag := required_tags[_]
    not resource.change.after.tags[tag]

    msg := sprintf("Resource '%s' is missing required tag: %s", [resource.address, tag])
}

# Validate VPC CIDR ranges
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"

    cidr := resource.change.after.cidr_block

    # Ensure VPC uses private IP ranges
    not net.cidr_contains("10.0.0.0/8", cidr)
    not net.cidr_contains("172.16.0.0/12", cidr)
    not net.cidr_contains("192.168.0.0/16", cidr)

    msg := sprintf("VPC '%s' CIDR block '%s' must use private IP ranges", [resource.address, cidr])
}
```

### policies/cost_control.rego

```rego
package terraform.cost

import future.keywords.in
import future.keywords.if

# Define cost limits for different instance types
instance_costs := {
    "t3.micro": 8.76,
    "t3.small": 17.52,
    "t3.medium": 35.04,
    "t3.large": 70.08,
    "t3.xlarge": 140.16,
    "t3.2xlarge": 280.32
}

# Calculate monthly cost for instances
monthly_cost_estimate[cost] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    resource.change.actions[_] == "create"

    instance_type := resource.change.after.instance_type
    cost := instance_costs[instance_type]
}

# Deny if total estimated cost exceeds budget
deny[msg] {
    total_cost := sum(monthly_cost_estimate)
    budget_limit := 100  # USD per month

    total_cost > budget_limit

    msg := sprintf("Estimated monthly cost $%.2f exceeds budget limit of $%.2f", [total_cost, budget_limit])
}

# Warn about high-cost instance types
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"

    instance_type := resource.change.after.instance_type
    cost := instance_costs[instance_type]
    cost > 70  # More than $70/month

    msg := sprintf("Instance '%s' with type '%s' has high monthly cost: $%.2f", [resource.address, instance_type, cost])
}

# Limit number of instances
deny[msg] {
    instance_count := count([resource |
        resource := input.resource_changes[_]
        resource.type == "aws_instance"
        resource.change.actions[_] == "create"
    ])

    instance_count > 5

    msg := sprintf("Cannot create %d instances. Maximum allowed is 5 instances.", [instance_count])
}

# Ensure proper lifecycle management
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"

    not resource.change.after.tags.AutoShutdown

    msg := sprintf("Instance '%s' must have AutoShutdown tag for cost control", [resource.address])
}
```

## 🔐 GitHub Configuration

### .github/workflows/atlantis.yml

```yaml
name: Atlantis Workflow

on:
    pull_request:
        types: [opened, synchronize, reopened]
        paths:
            - "terraform/**"
            - ".github/workflows/**"
            - "policies/**"
            - "atlantis.yaml"

    issue_comment:
        types: [created]

jobs:
    atlantis:
        if: github.event_name == 'pull_request' || (github.event_name == 'issue_comment' && contains(github.event.comment.body, 'atlantis'))
        runs-on: ubuntu-latest

        steps:
            - name: Checkout code
              uses: actions/checkout@v4

            - name: Setup Terraform
              uses: hashicorp/setup-terraform@v3
              with:
                  terraform_version: 1.6.0

            - name: Setup OPA
              uses: open-policy-agent/setup-opa@v2
              with:
                  version: latest

            - name: Validate Terraform
              run: |
                  cd terraform
                  terraform fmt -check -recursive
                  terraform init -backend=false
                  terraform validate

            - name: Validate Policies
              run: |
                  opa test policies/ --verbose

            - name: Security Scan
              uses: aquasecurity/trivy-action@master
              with:
                  scan-type: "config"
                  scan-ref: "./terraform"
                  format: "sarif"
                  output: "trivy-results.sarif"

            - name: Upload Trivy results
              uses: github/codeql-action/upload-sarif@v2
              if: always()
              with:
                  sarif_file: "trivy-results.sarif"
```

### GitHub Repository Settings

#### Webhook Configuration

```json
{
	"name": "web",
	"active": true,
	"events": ["pull_request", "issue_comment", "pull_request_review", "push"],
	"config": {
		"url": "https://your-atlantis-server.com/events",
		"content_type": "json",
		"secret": "your-webhook-secret",
		"insecure_ssl": "0"
	}
}
```

#### Branch Protection Rules

```json
{
	"required_status_checks": {
		"strict": true,
		"contexts": ["atlantis/plan", "atlantis/policy_check"]
	},
	"enforce_admins": true,
	"required_pull_request_reviews": {
		"required_approving_review_count": 1,
		"dismiss_stale_reviews": true,
		"require_code_owner_reviews": true
	},
	"restrictions": null,
	"allow_force_pushes": false,
	"allow_deletions": false
}
```

## 📊 Monitoring Configuration

### CloudWatch Dashboards

#### Infrastructure Dashboard

```json
{
	"widgets": [
		{
			"type": "metric",
			"properties": {
				"metrics": [
					["AWS/EC2", "CPUUtilization", "InstanceId", "i-1234567890abcdef0"],
					["AWS/EC2", "NetworkIn", "InstanceId", "i-1234567890abcdef0"],
					["AWS/EC2", "NetworkOut", "InstanceId", "i-1234567890abcdef0"]
				],
				"period": 300,
				"stat": "Average",
				"region": "us-west-2",
				"title": "EC2 Instance Metrics"
			}
		},
		{
			"type": "metric",
			"properties": {
				"metrics": [
					["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "app/workshop-alb/123456789"],
					["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/workshop-alb/123456789"],
					["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "app/workshop-alb/123456789"],
					["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "app/workshop-alb/123456789"]
				],
				"period": 300,
				"stat": "Sum",
				"region": "us-west-2",
				"title": "Application Load Balancer Metrics"
			}
		}
	]
}
```

#### Cost Dashboard

```json
{
	"widgets": [
		{
			"type": "metric",
			"properties": {
				"metrics": [
					["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonEC2", "Currency", "USD"],
					["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonS3", "Currency", "USD"],
					["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonCloudWatch", "Currency", "USD"]
				],
				"period": 86400,
				"stat": "Maximum",
				"region": "us-east-1",
				"title": "Daily Estimated Charges by Service"
			}
		}
	]
}
```

---

**📝 Configuration Best Practices:**

-   Use version control for all configuration files
-   Validate configurations before applying
-   Use environment-specific configurations
-   Document all custom configurations
-   Regular configuration reviews and updates
-   Implement proper secret management
-   Use least privilege principle for permissions

**Last Updated**: August 2025  
**Version**: 1.0  
**Author**: Nguyen Nhat Quang (Bright-04)
