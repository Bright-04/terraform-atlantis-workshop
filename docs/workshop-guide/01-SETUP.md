# Environment Setup Guide

## 🛠️ Prerequisites Installation

This guide will help you set up your development environment for the Terraform Atlantis Workshop.

### **1. AWS Account Setup**

#### **Create AWS Account**

1. Go to [AWS Console](https://aws.amazon.com/)
2. Click "Create an AWS Account"
3. Follow the registration process
4. **Important**: Set up billing alerts to avoid unexpected charges

#### **Create IAM User**

1. Go to AWS IAM Console
2. Create a new user with programmatic access
3. Attach the following policies:
    - `AmazonEC2FullAccess`
    - `AmazonS3FullAccess`
    - `IAMFullAccess`
    - `CloudWatchFullAccess`
    - `AmazonVPCFullAccess`

#### **Generate Access Keys**

1. Select your IAM user
2. Go to "Security credentials" tab
3. Create access key
4. **Save the Access Key ID and Secret Access Key securely**

### **2. AWS CLI Installation**

#### **Windows (PowerShell)**

```powershell
# Download and install AWS CLI
# Visit: https://aws.amazon.com/cli/
# Or use winget:
winget install Amazon.AWSCLI

# Verify installation
aws --version
```

#### **macOS**

```bash
# Using Homebrew
brew install awscli

# Verify installation
aws --version
```

#### **Linux (Ubuntu/Debian)**

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

#### **Configure AWS CLI**

```bash
aws configure
# Enter your Access Key ID
# Enter your Secret Access Key
# Enter your default region (e.g., us-east-1)
# Enter your output format (json)
```

### **3. Terraform Installation**

#### **Windows (PowerShell)**

```powershell
# Using Chocolatey
choco install terraform

# Or download from: https://www.terraform.io/downloads
# Extract to a directory in your PATH

# Verify installation
terraform --version
```

#### **macOS**

```bash
# Using Homebrew
brew install terraform

# Verify installation
terraform --version
```

#### **Linux**

```bash
# Download and install
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify installation
terraform --version
```

### **4. Git Installation**

#### **Windows**

```powershell
# Download from: https://git-scm.com/download/win
# Or use winget:
winget install Git.Git

# Verify installation
git --version
```

#### **macOS**

```bash
# Using Homebrew
brew install git

# Verify installation
git --version
```

#### **Linux**

```bash
# Ubuntu/Debian
sudo apt install git

# CentOS/RHEL
sudo yum install git

# Verify installation
git --version
```

### **5. Docker Installation**

#### **Windows**

```powershell
# Download Docker Desktop from: https://www.docker.com/products/docker-desktop
# Install and start Docker Desktop

# Verify installation
docker --version
```

#### **macOS**

```bash
# Download Docker Desktop from: https://www.docker.com/products/docker-desktop
# Install and start Docker Desktop

# Verify installation
docker --version
```

#### **Linux**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Verify installation
docker --version
```

## 🔧 Environment Configuration

### **1. AWS Credentials Verification**

```bash
# Test AWS credentials
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDAX...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-username"
# }
```

### **2. Terraform Configuration**

```bash
# Create workspace directory
mkdir terraform-workshop
cd terraform-workshop

# Initialize Terraform (when you have .tf files)
terraform init
```

### **3. GitHub Repository Setup**

#### **Create Repository**

1. Go to [GitHub](https://github.com)
2. Create a new repository
3. Clone it locally:

```bash
git clone https://github.com/yourusername/terraform-atlantis-workshop.git
cd terraform-atlantis-workshop
```

#### **Configure Git**

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### **4. Project Structure Setup**

#### **Windows (PowerShell)**

```powershell
# Create project structure
New-Item -ItemType Directory -Path "terraform", "atlantis", "policies", "scripts", "docs" -Force

# Create initial files
New-Item -ItemType File -Path "terraform/main.tf" -Force
New-Item -ItemType File -Path "terraform/variables.tf" -Force
New-Item -ItemType File -Path "terraform/outputs.tf" -Force
New-Item -ItemType File -Path "atlantis/atlantis.yaml" -Force
New-Item -ItemType File -Path "README.md" -Force
```

#### **Linux/macOS**

```bash
# Create project structure
mkdir -p terraform atlantis policies scripts docs

# Create initial files
touch terraform/main.tf
touch terraform/variables.tf
touch terraform/outputs.tf
touch atlantis/atlantis.yaml
touch README.md
```

## 🧪 Verification Steps

### **1. Tool Verification**

Run these commands to verify all tools are installed:

```bash
# Check AWS CLI
aws --version

# Check Terraform
terraform --version

# Check Git
git --version

# Check Docker
docker --version
```

### **2. AWS Connection Test**

```bash
# Test AWS connectivity
aws sts get-caller-identity

# Test AWS region
aws configure get region

# List S3 buckets (should work even if empty)
aws s3 ls
```

### **3. Terraform Test**

#### **Windows (PowerShell)**

```powershell
# Create a simple test file
@"
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

output "test" {
  value = "Terraform is working!"
}
"@ | Out-File -FilePath "test.tf" -Encoding UTF8

# Initialize and test
terraform init
terraform plan

# Clean up
Remove-Item "test.tf" -Force
Remove-Item ".terraform" -Recurse -Force
```

#### **Linux/macOS**

```bash
# Create a simple test file
cat > test.tf << EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

output "test" {
  value = "Terraform is working!"
}
EOF

# Initialize and test
terraform init
terraform plan

# Clean up
rm test.tf
rm -rf .terraform
```

## 🔐 Security Best Practices

### **1. AWS Security**

-   **Use IAM Users**: Don't use root credentials
-   **Principle of Least Privilege**: Only grant necessary permissions
-   **Rotate Access Keys**: Regularly rotate your access keys
-   **Enable MFA**: Use multi-factor authentication
-   **Monitor Usage**: Set up CloudTrail and billing alerts

### **2. Local Security**

-   **Secure Credentials**: Store AWS credentials securely
-   **Environment Variables**: Use environment variables for sensitive data
-   **Git Ignore**: Add sensitive files to .gitignore
-   **Regular Updates**: Keep tools updated

### **3. Network Security**

-   **VPN**: Use VPN for secure connections
-   **Firewall**: Configure local firewall
-   **HTTPS**: Use HTTPS for all web connections

## 📋 Setup Checklist

Before proceeding to the next section, ensure you have:

-   [ ] **AWS Account** created and configured
-   [ ] **IAM User** with appropriate permissions
-   [ ] **AWS CLI** installed and configured
-   [ ] **Terraform** installed (v1.6.0+)
-   [ ] **Git** installed and configured
-   [ ] **Docker** installed and running
-   [ ] **GitHub Repository** created
-   [ ] **Project Structure** set up
-   [ ] **All Tools Verified** working correctly

## 🚨 Common Issues

### **AWS CLI Issues**

```bash
# If aws command not found
# Windows: Add AWS CLI to PATH
# Linux/macOS: Check installation path

# If credentials not working
aws configure list
aws sts get-caller-identity
```

### **Terraform Issues**

```bash
# If terraform command not found
# Check PATH environment variable
# Verify installation directory

# If provider issues
terraform init -upgrade
```

### **Docker Issues**

```bash
# If Docker not running
# Windows/macOS: Start Docker Desktop
# Linux: sudo systemctl start docker

# If permission denied
# Linux: sudo usermod -aG docker $USER
```

## 📞 Support

If you encounter issues:

1. **Check the troubleshooting guide** (09-TROUBLESHOOTING.md)
2. **Verify all prerequisites** are installed correctly
3. **Check AWS permissions** and credentials
4. **Review error messages** carefully
5. **Search online** for similar issues
6. **Create an issue** in the workshop repository

---

**Ready for the next step?** Continue to [02-INFRASTRUCTURE.md](02-INFRASTRUCTURE.md) to understand the Terraform infrastructure!
