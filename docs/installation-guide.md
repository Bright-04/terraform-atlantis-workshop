# Installation Guide - Terraform Atlantis Workshop

## 🔧 Complete Installation Instructions

This guide provides step-by-step instructions for installing and configuring all components required for the **Environment Provisioning Automation with Terraform and Atlantis** workshop.

## 📋 Installation Overview

### Installation Phases

1. **System Preparation** - Verify system requirements
2. **Core Tools Installation** - Install required software
3. **AWS Configuration** - Set up AWS access
4. **Workshop Setup** - Clone and configure workshop
5. **Verification** - Test all components

### Estimated Time

-   **Total Time**: 30-60 minutes
-   **System Preparation**: 5 minutes
-   **Core Tools**: 15-30 minutes
-   **AWS Configuration**: 10 minutes
-   **Workshop Setup**: 5 minutes
-   **Verification**: 5 minutes

## 🖥️ Phase 1: System Preparation

### 1.1 Verify System Requirements

#### Check Operating System

```powershell
# Check Windows version
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion

# Check PowerShell version
$PSVersionTable.PSVersion

# Check available memory
Get-ComputerInfo | Select-Object TotalPhysicalMemory
```

#### Check Network Connectivity

```powershell
# Test internet connectivity
Test-NetConnection -ComputerName google.com -Port 443

# Test DNS resolution
nslookup github.com
nslookup registry.terraform.io
```

#### Check Disk Space

```powershell
# Check available disk space
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}}
```

### 1.2 Prepare System Environment

#### Set Execution Policy

```powershell
# Check current execution policy
Get-ExecutionPolicy

# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Verify change
Get-ExecutionPolicy
```

#### Create Workshop Directory

```powershell
# Create workshop directory
New-Item -ItemType Directory -Path "C:\terraform-workshop" -Force

# Navigate to directory
cd C:\terraform-workshop

# Verify directory
Get-Location
```

## 🛠️ Phase 2: Core Tools Installation

### 2.1 Install PowerShell 7

#### Download and Install

```powershell
# Download PowerShell 7
Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/PowerShell-7.4.0-win-x64.msi" -OutFile "PowerShell-7.4.0-win-x64.msi"

# Install PowerShell 7
Start-Process msiexec.exe -Wait -ArgumentList '/I PowerShell-7.4.0-win-x64.msi /quiet'

# Verify installation
pwsh --version
```

#### Alternative: Using winget

```powershell
# Install using winget
winget install Microsoft.PowerShell

# Verify installation
pwsh --version
```

### 2.2 Install Git

#### Download and Install

```powershell
# Download Git
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe" -OutFile "Git-2.43.0-64-bit.exe"

# Install Git
Start-Process -FilePath "Git-2.43.0-64-bit.exe" -ArgumentList "/VERYSILENT /NORESTART" -Wait

# Verify installation
git --version
```

#### Alternative: Using winget

```powershell
# Install using winget
winget install Git.Git

# Verify installation
git --version
```

#### Configure Git

```powershell
# Configure Git user
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify configuration
git config --global user.name
git config --global user.email
```

### 2.3 Install AWS CLI

#### Download and Install

```powershell
# Download AWS CLI
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"

# Install AWS CLI
Start-Process msiexec.exe -Wait -ArgumentList '/I AWSCLIV2.msi /quiet'

# Verify installation
aws --version
```

#### Alternative: Using winget

```powershell
# Install using winget
winget install Amazon.AWSCLI

# Verify installation
aws --version
```

### 2.4 Install Terraform

#### Download and Install

```powershell
# Create Terraform directory
New-Item -ItemType Directory -Path "C:\terraform" -Force

# Download Terraform
Invoke-WebRequest -Uri "https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_windows_amd64.zip" -OutFile "terraform.zip"

# Extract Terraform
Expand-Archive -Path "terraform.zip" -DestinationPath "C:\terraform" -Force

# Add to PATH
$env:PATH += ";C:\terraform"

# Verify installation
terraform version
```

#### Alternative: Using Chocolatey

```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Terraform
choco install terraform -y

# Verify installation
terraform version
```

### 2.5 Install Docker Desktop (Optional)

#### Download and Install

```powershell
# Download Docker Desktop
Invoke-WebRequest -Uri "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe" -OutFile "DockerDesktopInstaller.exe"

# Install Docker Desktop
Start-Process -FilePath "DockerDesktopInstaller.exe" -ArgumentList "install --quiet" -Wait

# Start Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

#### Alternative: Using winget

```powershell
# Install using winget
winget install Docker.DockerDesktop

# Start Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

#### Verify Docker Installation

```powershell
# Wait for Docker to start (may take a few minutes)
Start-Sleep -Seconds 30

# Test Docker
docker --version
docker run hello-world
```

### 2.6 Install Visual Studio Code (Recommended)

#### Download and Install

```powershell
# Download VS Code
Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user" -OutFile "VSCodeUserSetup-x64.exe"

# Install VS Code
Start-Process -FilePath "VSCodeUserSetup-x64.exe" -ArgumentList "/VERYSILENT /NORESTART" -Wait
```

#### Alternative: Using winget

```powershell
# Install using winget
winget install Microsoft.VisualStudioCode

# Launch VS Code
code .
```

#### Install Recommended Extensions

```powershell
# Install VS Code extensions
code --install-extension ms-vscode.powershell
code --install-extension hashicorp.terraform
code --install-extension AmazonWebServices.aws-toolkit-vscode
code --install-extension eamodio.gitlens
code --install-extension redhat.vscode-yaml
```

## 🔐 Phase 3: AWS Configuration

### 3.1 Create AWS Account

#### Account Setup

1. **Visit AWS Console**: https://aws.amazon.com/
2. **Create Account**: Follow the sign-up process
3. **Verify Email**: Confirm your email address
4. **Add Payment Method**: Add credit card for billing
5. **Complete Setup**: Finish account setup

### 3.2 Create IAM User

#### Using AWS Console

1. **Login to AWS Console**
2. **Navigate to IAM**: https://console.aws.amazon.com/iam/
3. **Create User**:
    - Click "Users" → "Add user"
    - Username: `terraform-workshop`
    - Access type: "Programmatic access"
4. **Attach Policies**:
    - Attach "AdministratorAccess" (for workshop)
    - Or create custom policy with required permissions
5. **Create Access Keys**:
    - Note down Access Key ID and Secret Access Key

#### Using AWS CLI (if you have admin access)

```powershell
# Create IAM user
aws iam create-user --user-name terraform-workshop

# Create access key
aws iam create-access-key --user-name terraform-workshop

# Attach administrator policy
aws iam attach-user-policy --user-name terraform-workshop --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### 3.3 Configure AWS CLI

#### Configure Credentials

```powershell
# Configure AWS CLI
aws configure

# Enter the following information:
# AWS Access Key ID: [Your Access Key ID]
# AWS Secret Access Key: [Your Secret Access Key]
# Default region name: ap-southeast-1
# Default output format: json
```

#### Verify Configuration

```powershell
# Test AWS access
aws sts get-caller-identity

# Check region
aws configure get region

# Test AWS services
aws ec2 describe-regions --query 'Regions[0].RegionName' --output text
```

## 📦 Phase 4: Workshop Setup

### 4.1 Clone Workshop Repository

#### Clone Repository

```powershell
# Navigate to workshop directory
cd C:\terraform-workshop

# Clone repository
git clone https://github.com/your-username/terraform-atlantis-workshop.git

# Navigate to workshop directory
cd terraform-atlantis-workshop

# Verify repository
ls
```

#### Alternative: Download ZIP

```powershell
# Download workshop ZIP
Invoke-WebRequest -Uri "https://github.com/your-username/terraform-atlantis-workshop/archive/refs/heads/main.zip" -OutFile "workshop.zip"

# Extract workshop
Expand-Archive -Path "workshop.zip" -DestinationPath "." -Force

# Navigate to workshop directory
cd terraform-atlantis-workshop-main
```

### 4.2 Configure Workshop Environment

#### Set Up Environment Variables

```powershell
# Set workshop environment variables
$env:WORKSHOP_HOME = Get-Location
$env:TF_VAR_environment = "development"
$env:TF_VAR_project_name = "terraform-atlantis-workshop"

# Verify environment variables
Get-ChildItem Env: | Where-Object {$_.Name -like "*WORKSHOP*" -or $_.Name -like "*TF_VAR*"}
```

#### Initialize Terraform

```powershell
# Navigate to Terraform directory
cd terraform

# Initialize Terraform
terraform init

# Verify initialization
terraform version
terraform providers
```

### 4.3 Configure Workshop Scripts

#### Set Up PowerShell Scripts

```powershell
# Navigate back to workshop root
cd ..

# Make scripts executable (if needed)
Get-ChildItem -Path "scripts" -Filter "*.ps1" | ForEach-Object {
    Unblock-File -Path $_.FullName
}

# Test script execution
.\scripts\01-validate-environment.ps1
```

## ✅ Phase 5: Verification

### 5.1 System Verification

#### Verify All Tools

```powershell
# Create verification script
$verificationScript = @"
Write-Host "=== System Verification ===" -ForegroundColor Green

Write-Host "PowerShell Version:" -ForegroundColor Yellow
pwsh --version

Write-Host "Git Version:" -ForegroundColor Yellow
git --version

Write-Host "AWS CLI Version:" -ForegroundColor Yellow
aws --version

Write-Host "Terraform Version:" -ForegroundColor Yellow
terraform version

Write-Host "Docker Version:" -ForegroundColor Yellow
docker --version

Write-Host "VS Code Version:" -ForegroundColor Yellow
code --version
"@

# Save and run verification script
$verificationScript | Out-File -FilePath "verify-installation.ps1" -Encoding UTF8
.\verify-installation.ps1
```

### 5.2 AWS Verification

#### Test AWS Access

```powershell
# Create AWS verification script
$awsVerificationScript = @"
Write-Host "=== AWS Verification ===" -ForegroundColor Green

Write-Host "AWS Identity:" -ForegroundColor Yellow
aws sts get-caller-identity

Write-Host "AWS Region:" -ForegroundColor Yellow
aws configure get region

Write-Host "EC2 Regions:" -ForegroundColor Yellow
aws ec2 describe-regions --query 'Regions[0].RegionName' --output text

Write-Host "S3 Access:" -ForegroundColor Yellow
aws s3 ls
"@

# Save and run AWS verification script
$awsVerificationScript | Out-File -FilePath "verify-aws.ps1" -Encoding UTF8
.\verify-aws.ps1
```

### 5.3 Workshop Verification

#### Test Workshop Components

```powershell
# Create workshop verification script
$workshopVerificationScript = @"
Write-Host "=== Workshop Verification ===" -ForegroundColor Green

Write-Host "Workshop Directory:" -ForegroundColor Yellow
Get-Location

Write-Host "Workshop Files:" -ForegroundColor Yellow
Get-ChildItem -Recurse | Select-Object Name, Length | Format-Table

Write-Host "Terraform Configuration:" -ForegroundColor Yellow
cd terraform
terraform validate
terraform plan -out=tfplan
"@

# Save and run workshop verification script
$workshopVerificationScript | Out-File -FilePath "verify-workshop.ps1" -Encoding UTF8
.\verify-workshop.ps1
```

## 🚨 Troubleshooting Installation Issues

### Common Issues and Solutions

#### Issue: PowerShell Execution Policy

```powershell
# Solution: Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

#### Issue: Terraform Not Found

```powershell
# Solution: Add Terraform to PATH permanently
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\terraform", "User")
```

#### Issue: AWS CLI Not Found

```powershell
# Solution: Restart PowerShell after AWS CLI installation
# Or add AWS CLI to PATH manually
```

#### Issue: Docker Not Starting

```powershell
# Solution: Enable WSL 2 (Windows)
wsl --set-default-version 2
wsl --install

# Restart computer and try again
```

#### Issue: Git Configuration

```powershell
# Solution: Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## 📚 Post-Installation Setup

### 1. Configure VS Code

#### Open Workshop in VS Code

```powershell
# Open workshop in VS Code
code .

# Install recommended extensions
code --install-extension ms-vscode.powershell
code --install-extension hashicorp.terraform
code --install-extension AmazonWebServices.aws-toolkit-vscode
```

#### Configure VS Code Settings

```json
{
	"terraform.languageServer.enable": true,
	"terraform.languageServer.experimentalFeatures": {
		"validateOnSave": true,
		"prefillRequiredFields": true
	},
	"files.associations": {
		"*.tf": "terraform",
		"*.tfvars": "terraform"
	}
}
```

### 2. Set Up Git Repository

#### Configure Git Repository

```powershell
# Initialize Git repository (if not already done)
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial workshop setup"

# Add remote repository (if you have one)
git remote add origin https://github.com/your-username/terraform-atlantis-workshop.git
```

### 3. Create Workshop Configuration

#### Create terraform.tfvars

```powershell
# Copy example configuration
Copy-Item terraform\terraform.tfvars.example terraform\terraform.tfvars

# Edit configuration
notepad terraform\terraform.tfvars
```

#### Example terraform.tfvars

```hcl
# AWS Configuration
aws_region = "ap-southeast-1"
environment = "development"

# Instance Configuration
instance_type = "t3.micro"
instance_count = 2

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

# Tags
tags = {
  Environment = "development"
  Project     = "terraform-atlantis-workshop"
  CostCenter  = "IT-001"
  Owner       = "Your Name"
}
```

## ✅ Final Verification Checklist

After completing the installation, verify:

-   ✅ **PowerShell 7.0+** installed and working
-   ✅ **Git 2.30+** installed and configured
-   ✅ **AWS CLI 2.0+** installed and configured
-   ✅ **Terraform 1.6.0+** installed and working
-   ✅ **Docker Desktop** installed and running (optional)
-   ✅ **VS Code** installed with extensions
-   ✅ **AWS Account** created and configured
-   ✅ **IAM User** created with appropriate permissions
-   ✅ **Workshop Repository** cloned and configured
-   ✅ **Terraform** initialized and validated
-   ✅ **All Verification Scripts** passed

## 🚀 Next Steps

After successful installation:

1. **Follow Quick Start Guide**: [Quick Start Guide](quick-start-guide.md)
2. **Complete Workshop Exercises**: [Deployment Procedures](deployment-procedures.md)
3. **Learn Best Practices**: [Best Practices](best-practices.md)
4. **Explore Advanced Features**: [Architecture Overview](architecture-overview.md)
5. **Get Help When Needed**: [Troubleshooting Guide](troubleshooting-guide.md)

## 📞 Support

If you encounter issues during installation:

1. **Check Troubleshooting Guide**: [Troubleshooting Guide](troubleshooting-guide.md)
2. **Review FAQ**: [FAQ](faq.md)
3. **Create GitHub Issue**: Include detailed error information
4. **Contact Support**: cbl.nguyennhatquang2809@gmail.com

---

**📚 Related Documentation**

-   [Prerequisites](prerequisites.md)
-   [Quick Start Guide](quick-start-guide.md)
-   [Troubleshooting Guide](troubleshooting-guide.md)
-   [FAQ](faq.md)
