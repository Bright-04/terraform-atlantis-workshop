# Prerequisites - Terraform Atlantis Workshop

## 📋 System Requirements and Setup

This document outlines all prerequisites required to successfully complete the **Environment Provisioning Automation with Terraform and Atlantis** workshop.

## 🖥️ System Requirements

### Operating System

-   **Windows 10/11** (recommended)
-   **Windows Server 2019/2022**
-   **macOS** (with PowerShell Core)
-   **Linux** (with PowerShell Core)

### Hardware Requirements

-   **CPU**: 2+ cores (4+ recommended)
-   **RAM**: 8GB minimum (16GB recommended)
-   **Storage**: 10GB free space
-   **Network**: Stable internet connection

### Software Requirements

#### Required Software

-   **PowerShell 7.0+** (or PowerShell Core)
-   **Git 2.30+**
-   **AWS CLI 2.0+**
-   **Terraform 1.6.0+**
-   **Docker Desktop** (optional, for Atlantis)

#### Optional Software

-   **Visual Studio Code** (recommended)
-   **AWS Toolkit for VS Code**
-   **Terraform extension for VS Code**
-   **GitHub Desktop**

## 🔧 Installation Guide

### 1. PowerShell Installation

#### Windows

```powershell
# Check current PowerShell version
$PSVersionTable.PSVersion

# Install PowerShell 7 (if needed)
# Download from: https://github.com/PowerShell/PowerShell/releases
# Or use winget
winget install Microsoft.PowerShell
```

#### macOS

```bash
# Install using Homebrew
brew install --cask powershell

# Or download from GitHub releases
```

#### Linux

```bash
# Ubuntu/Debian
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell

# CentOS/RHEL
sudo yum install powershell
```

### 2. Git Installation

#### Windows

```powershell
# Install using winget
winget install Git.Git

# Or download from: https://git-scm.com/download/win
```

#### macOS

```bash
# Install using Homebrew
brew install git

# Or download from: https://git-scm.com/download/mac
```

#### Linux

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install git

# CentOS/RHEL
sudo yum install git
```

### 3. AWS CLI Installation

#### Windows

```powershell
# Install using winget
winget install Amazon.AWSCLI

# Or download from: https://aws.amazon.com/cli/
```

#### macOS

```bash
# Install using Homebrew
brew install awscli

# Or download from AWS website
```

#### Linux

```bash
# Download and install
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### 4. Terraform Installation

#### Windows

```powershell
# Install using Chocolatey
choco install terraform

# Or download from: https://www.terraform.io/downloads.html
```

#### macOS

```bash
# Install using Homebrew
brew install terraform

# Or download from Terraform website
```

#### Linux

```bash
# Download and install
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### 5. Docker Installation (Optional)

#### Windows

```powershell
# Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop
```

#### macOS

```bash
# Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop
```

#### Linux

```bash
# Install Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

## 🔐 AWS Account Setup

### 1. AWS Account Requirements

#### Account Type

-   **AWS Free Tier** (for learning and testing)
-   **AWS Paid Account** (for production use)
-   **AWS Organizations** (for enterprise use)

#### Required Services

-   **EC2**: Elastic Compute Cloud
-   **S3**: Simple Storage Service
-   **VPC**: Virtual Private Cloud
-   **IAM**: Identity and Access Management
-   **CloudWatch**: Monitoring and Logging

### 2. IAM User Setup

#### Create IAM User

```bash
# Using AWS CLI (if you have admin access)
aws iam create-user --user-name terraform-workshop

# Create access keys
aws iam create-access-key --user-name terraform-workshop
```

#### Required Permissions

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": ["ec2:*", "s3:*", "iam:*", "cloudwatch:*", "vpc:*", "elasticloadbalancing:*", "autoscaling:*"],
			"Resource": "*"
		}
	]
}
```

### 3. AWS Configuration

#### Configure AWS CLI

```bash
# Configure AWS credentials
aws configure

# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Default output format (json)
```

#### Verify Configuration

```bash
# Test AWS access
aws sts get-caller-identity

# Check region
aws configure get region
```

## 🛠️ Development Environment Setup

### 1. Visual Studio Code (Recommended)

#### Installation

```powershell
# Install using winget
winget install Microsoft.VisualStudioCode

# Or download from: https://code.visualstudio.com/
```

#### Recommended Extensions

-   **AWS Toolkit**
-   **Terraform**
-   **GitLens**
-   **PowerShell**
-   **YAML**

### 2. GitHub Account

#### Account Setup

-   Create GitHub account at https://github.com
-   Enable two-factor authentication
-   Create personal access token for API access

#### Repository Access

-   Fork the workshop repository
-   Clone to local machine
-   Set up remote tracking

## 🔍 Verification Checklist

### Pre-Workshop Verification

#### System Check

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check Git version
git --version

# Check AWS CLI version
aws --version

# Check Terraform version
terraform version

# Check Docker version (if installed)
docker --version
```

#### AWS Access Check

```powershell
# Verify AWS credentials
aws sts get-caller-identity

# Test AWS services
aws ec2 describe-regions --query 'Regions[0].RegionName' --output text
aws s3 ls
```

#### Network Check

```powershell
# Test internet connectivity
Test-NetConnection -ComputerName registry.terraform.io -Port 443
Test-NetConnection -ComputerName github.com -Port 443
```

### Environment Validation

#### PowerShell Execution Policy

```powershell
# Check execution policy
Get-ExecutionPolicy

# Set if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Git Configuration

```bash
# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Test Git
git init
git status
```

#### Terraform Test

```bash
# Test Terraform
terraform version
terraform -help
```

## 🚨 Common Issues and Solutions

### Issue: PowerShell Execution Policy

```powershell
# Solution: Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: AWS Credentials Not Found

```bash
# Solution: Configure AWS credentials
aws configure
```

### Issue: Terraform Not Found

```bash
# Solution: Add Terraform to PATH
# Windows: Add to system PATH
# Linux/macOS: Add to ~/.bashrc or ~/.zshrc
export PATH=$PATH:/usr/local/bin
```

### Issue: Docker Not Starting

```bash
# Solution: Start Docker service
# Windows: Start Docker Desktop
# Linux: sudo systemctl start docker
```

## 📚 Additional Resources

### Documentation

-   **PowerShell Documentation**: https://docs.microsoft.com/en-us/powershell/
-   **Git Documentation**: https://git-scm.com/doc
-   **AWS CLI Documentation**: https://docs.aws.amazon.com/cli/
-   **Terraform Documentation**: https://www.terraform.io/docs
-   **Docker Documentation**: https://docs.docker.com/

### Learning Resources

-   **PowerShell Tutorial**: https://docs.microsoft.com/en-us/powershell/scripting/overview
-   **Git Tutorial**: https://git-scm.com/docs/gittutorial
-   **AWS Getting Started**: https://aws.amazon.com/getting-started/
-   **Terraform Getting Started**: https://learn.hashicorp.com/terraform

### Support

-   **PowerShell Community**: https://powershell.org/
-   **Git Community**: https://git-scm.com/community
-   **AWS Support**: https://aws.amazon.com/support/
-   **Terraform Community**: https://www.terraform.io/community

## ✅ Final Checklist

Before starting the workshop, ensure you have:

-   ✅ **PowerShell 7.0+** installed and working
-   ✅ **Git 2.30+** installed and configured
-   ✅ **AWS CLI 2.0+** installed and configured
-   ✅ **Terraform 1.6.0+** installed and working
-   ✅ **Docker Desktop** installed (optional)
-   ✅ **AWS Account** with appropriate permissions
-   ✅ **GitHub Account** with repository access
-   ✅ **Stable Internet Connection** for downloads and AWS access
-   ✅ **Sufficient Disk Space** (10GB+ free)
-   ✅ **Administrative Access** (for software installation)

## 🚀 Next Steps

After completing the prerequisites:

1. **Clone the Workshop Repository**
2. **Follow the Quick Start Guide**
3. **Complete the Workshop Exercises**
4. **Practice with Different Configurations**
5. **Explore Advanced Features**

---

**📚 Related Documentation**

-   [Quick Start Guide](quick-start-guide.md)
-   [Installation Guide](installation-guide.md)
-   [Troubleshooting Guide](troubleshooting-guide.md)
-   [FAQ](faq.md)
