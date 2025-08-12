# Terraform Fundamentals

## Overview

This guide covers the essential concepts of Terraform and Infrastructure as Code (IaC) that are fundamental to understanding and working with this workshop.

## What is Terraform?

Terraform is an open-source Infrastructure as Code tool created by HashiCorp. It allows you to define and provision infrastructure resources using declarative configuration files.

### Key Concepts

- **Declarative**: You describe the desired state of your infrastructure
- **Version Control**: Infrastructure configurations are stored in version control
- **Provider Agnostic**: Supports multiple cloud providers (AWS, Azure, GCP, etc.)
- **State Management**: Tracks the current state of your infrastructure
- **Dependency Management**: Automatically handles resource dependencies

## Core Terraform Components

### 1. Configuration Files (.tf)

Terraform uses `.tf` files to define infrastructure:

```hcl
# Example: main.tf
provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer"
  }
}
```

### 2. Providers

Providers are plugins that interact with cloud providers and services:

```hcl
# AWS Provider
provider "aws" {
  region = "us-west-2"
  profile = "default"
}

# Azure Provider
provider "azurerm" {
  features {}
}

# Local Provider (for local operations)
provider "local" {}
```

### 3. Resources

Resources are the infrastructure objects you want to create:

```hcl
# AWS EC2 Instance
resource "aws_instance" "web_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public.id
  
  tags = {
    Name = "Web Server"
    Environment = "Production"
  }
}

# AWS Security Group
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### 4. Data Sources

Data sources allow you to fetch information about existing resources:

```hcl
# Get the latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

# Use the AMI in a resource
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
}
```

### 5. Variables

Variables allow you to parameterize your configurations:

```hcl
# variables.tf
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# main.tf
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = {
    Environment = var.environment
  }
}
```

### 6. Outputs

Outputs expose specific values from your configuration:

```hcl
# outputs.tf
output "instance_id" {
  description = "ID of the created instance"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.web.public_ip
}

output "private_ip" {
  description = "Private IP of the instance"
  value       = aws_instance.web.private_ip
}
```

## Terraform Workflow

### 1. Initialize (`terraform init`)

```bash
terraform init
```

- Downloads required providers
- Initializes the working directory
- Sets up backend configuration

### 2. Plan (`terraform plan`)

```bash
terraform plan
```

- Creates an execution plan
- Shows what Terraform will do
- Validates configuration syntax
- Checks for errors

### 3. Apply (`terraform apply`)

```bash
terraform apply
```

- Executes the plan
- Creates, modifies, or destroys resources
- Updates the state file

### 4. Destroy (`terraform destroy`)

```bash
terraform destroy
```

- Removes all resources managed by Terraform
- Updates the state file

## State Management

### What is State?

Terraform state is a snapshot that maps real-world resources to your configuration:

```json
{
  "version": 4,
  "terraform_version": "1.0.0",
  "serial": 1,
  "lineage": "12345678-1234-1234-1234-123456789012",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-1234567890abcdef0",
            "instance_type": "t2.micro",
            "ami": "ami-12345678"
          }
        }
      ]
    }
  ]
}
```

### Backend Configuration

Store state remotely for team collaboration:

```hcl
# S3 Backend
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-west-2"
  }
}

# Azure Storage Backend
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate12345"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

## Best Practices

### 1. File Organization

```
project/
├── main.tf          # Main configuration
├── variables.tf     # Variable declarations
├── outputs.tf       # Output declarations
├── providers.tf     # Provider configurations
├── versions.tf      # Terraform and provider versions
├── terraform.tfvars # Variable values
└── modules/
    ├── networking/
    ├── compute/
    └── security/
```

### 2. Use Modules

```hcl
# modules/web-server/main.tf
variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
}

output "instance_id" {
  value = aws_instance.web.id
}

# main.tf
module "web_server" {
  source = "./modules/web-server"
  
  instance_type = "t2.micro"
  ami_id        = "ami-12345678"
}
```

### 3. Use Workspaces

```bash
# Create a new workspace
terraform workspace new dev

# List workspaces
terraform workspace list

# Switch to a workspace
terraform workspace select prod

# Show current workspace
terraform workspace show
```

### 4. Validate and Format

```bash
# Format code
terraform fmt

# Validate syntax
terraform validate

# Check for security issues
terraform plan -detailed-exitcode
```

## Common Patterns

### 1. Conditional Resources

```hcl
resource "aws_instance" "web" {
  count = var.create_web_server ? 1 : 0
  
  ami           = var.ami_id
  instance_type = var.instance_type
}

output "web_server_id" {
  value = var.create_web_server ? aws_instance.web[0].id : null
}
```

### 2. Data Source Dependencies

```hcl
data "aws_subnet" "selected" {
  id = var.subnet_id
}

resource "aws_instance" "web" {
  subnet_id = data.aws_subnet.selected.id
  
  depends_on = [data.aws_subnet.selected]
}
```

### 3. Dynamic Blocks

```hcl
resource "aws_security_group" "web" {
  name = "web-sg"
  
  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

## Error Handling

### Common Errors and Solutions

1. **Provider Not Found**
   ```bash
   Error: provider "aws" is not available
   ```
   Solution: Run `terraform init`

2. **State Lock**
   ```bash
   Error: Error acquiring the state lock
   ```
   Solution: Check for running Terraform processes or force unlock

3. **Resource Already Exists**
   ```bash
   Error: resource already exists
   ```
   Solution: Import existing resource or destroy and recreate

## Next Steps

After understanding these fundamentals:

1. **Practice**: Create simple resources in a test environment
2. **Modules**: Learn to create reusable modules
3. **State Management**: Set up remote state storage
4. **CI/CD**: Integrate with Atlantis or other CI/CD tools
5. **Advanced Features**: Explore workspaces, data sources, and dynamic blocks

## Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform Registry](https://registry.terraform.io/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)
