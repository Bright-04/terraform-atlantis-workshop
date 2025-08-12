# =============================================================================
# Terraform Atlantis Workshop - Environment Setup Script
# =============================================================================
# This script automatically sets up the .env file with proper configuration
# It detects AWS credentials, GitHub settings, and creates a complete .env file
# =============================================================================

param(
    [switch]$Force,
    [switch]$Interactive
)

Write-Host "🔧 Terraform Atlantis Workshop - Environment Setup" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# =============================================================================
# Function to check if .env already exists
# =============================================================================
function Test-EnvFile {
    if (Test-Path ".env") {
        if ($Force) {
            Write-Host "⚠️  .env file exists. Overwriting due to -Force flag." -ForegroundColor Yellow
            return $false
        } else {
            Write-Host "✅ .env file already exists." -ForegroundColor Green
            Write-Host "   Use -Force to overwrite or -Interactive to update specific values." -ForegroundColor Gray
            return $true
        }
    }
    return $false
}

# =============================================================================
# Function to get AWS credentials
# =============================================================================
function Get-AWSCredentials {
    Write-Host "`n🔐 AWS Credentials Configuration" -ForegroundColor Yellow
    
    # Try to get existing AWS credentials
    try {
        $awsIdentity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
        if ($awsIdentity) {
            Write-Host "✅ Found existing AWS credentials:" -ForegroundColor Green
            Write-Host "   Account ID: $($awsIdentity.Account)" -ForegroundColor Gray
            Write-Host "   User ARN: $($awsIdentity.Arn)" -ForegroundColor Gray
            Write-Host "   User ID: $($awsIdentity.UserId)" -ForegroundColor Gray
            
            # Get AWS region
            $awsRegion = aws configure get region 2>$null
            if (-not $awsRegion) {
                $awsRegion = "ap-southeast-1"
                Write-Host "   Region: $awsRegion (default)" -ForegroundColor Gray
            } else {
                Write-Host "   Region: $awsRegion" -ForegroundColor Gray
            }
            
            return @{
                AccountId = $awsIdentity.Account
                UserArn = $awsIdentity.Arn
                UserId = $awsIdentity.UserId
                Region = $awsRegion
                AccessKeyId = "EXISTING"
                SecretAccessKey = "EXISTING"
            }
        }
    } catch {
        Write-Host "⚠️  No existing AWS credentials found." -ForegroundColor Yellow
    }
    
    if ($Interactive) {
        Write-Host "`nPlease enter your AWS credentials:" -ForegroundColor Cyan
        $accessKeyId = Read-Host "AWS Access Key ID"
        $secretAccessKey = Read-Host "AWS Secret Access Key" -AsSecureString
        $region = Read-Host "AWS Region [ap-southeast-1]"
        
        if (-not $region) { $region = "ap-southeast-1" }
        
        # Test credentials
        $env:AWS_ACCESS_KEY_ID = $accessKeyId
        $env:AWS_SECRET_ACCESS_KEY = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretAccessKey))
        $env:AWS_DEFAULT_REGION = $region
        
        try {
            $awsIdentity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
            if ($awsIdentity) {
                Write-Host "✅ AWS credentials are valid!" -ForegroundColor Green
                return @{
                    AccountId = $awsIdentity.Account
                    UserArn = $awsIdentity.Arn
                    UserId = $awsIdentity.UserId
                    Region = $region
                    AccessKeyId = $accessKeyId
                    SecretAccessKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretAccessKey))
                }
            }
        } catch {
            Write-Host "❌ Invalid AWS credentials. Please check and try again." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "⚠️  No AWS credentials found. Please run with -Interactive to enter credentials." -ForegroundColor Yellow
        return @{
            AccountId = "REQUIRED"
            UserArn = "REQUIRED"
            UserId = "REQUIRED"
            Region = "ap-southeast-1"
            AccessKeyId = "REQUIRED"
            SecretAccessKey = "REQUIRED"
        }
    }
}

# =============================================================================
# Function to get GitHub configuration
# =============================================================================
function Get-GitHubConfig {
    Write-Host "`n🐙 GitHub Configuration" -ForegroundColor Yellow
    
    # Try to get GitHub username from git config
    $gitUser = git config --global user.name 2>$null
    $gitEmail = git config --global user.email 2>$null
    
    if ($gitUser) {
        Write-Host "✅ Found Git configuration:" -ForegroundColor Green
        Write-Host "   Username: $gitUser" -ForegroundColor Gray
        Write-Host "   Email: $gitEmail" -ForegroundColor Gray
    }
    
    if ($Interactive) {
        Write-Host "`nPlease enter your GitHub configuration:" -ForegroundColor Cyan
        $githubUser = Read-Host "GitHub Username [$gitUser]"
        if (-not $githubUser) { $githubUser = $gitUser }
        
        $githubToken = Read-Host "GitHub Personal Access Token" -AsSecureString
        $webhookSecret = Read-Host "GitHub Webhook Secret (optional)"
        $atlantisUrl = Read-Host "Atlantis URL [github-actions]"
        if (-not $atlantisUrl) { $atlantisUrl = "github-actions" }
        
        return @{
            Username = $githubUser
            Token = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubToken))
            WebhookSecret = $webhookSecret
            AtlantisUrl = $atlantisUrl
        }
    } else {
        return @{
            Username = $gitUser ?? "your_github_username"
            Token = "your_github_personal_access_token"
            WebhookSecret = "your_webhook_secret"
            AtlantisUrl = "github-actions"
        }
    }
}

# =============================================================================
# Function to create .env file
# =============================================================================
function New-EnvFile {
    param(
        [hashtable]$AWSConfig,
        [hashtable]$GitHubConfig
    )
    
    Write-Host "`n📝 Creating .env file..." -ForegroundColor Yellow
    
    $envContent = @"
# =============================================================================
# Environment Variables for Terraform Atlantis Workshop
# =============================================================================
# This file contains environment variables required for the workshop
# Generated automatically by setup-env.ps1
# =============================================================================

# =============================================================================
# AWS Configuration
# =============================================================================
AWS_ACCESS_KEY_ID=$($AWSConfig.AccessKeyId)
AWS_SECRET_ACCESS_KEY=$($AWSConfig.SecretAccessKey)
AWS_DEFAULT_REGION=$($AWSConfig.Region)

# =============================================================================
# GitHub Configuration (for Atlantis)
# =============================================================================
ATLANTIS_GH_USER=$($GitHubConfig.Username)
ATLANTIS_GH_TOKEN=$($GitHubConfig.Token)
ATLANTIS_GH_WEBHOOK_SECRET=$($GitHubConfig.WebhookSecret)
ATLANTIS_REPO_ALLOWLIST=github.com/$($GitHubConfig.Username)/terraform-atlantis-workshop
ATLANTIS_ATLANTIS_URL=$($GitHubConfig.AtlantisUrl)
ATLANTIS_LOG_LEVEL=info
ATLANTIS_DEFAULT_TF_VERSION=v1.6.0
ATLANTIS_ENABLE_POLICY_CHECKS=true
ATLANTIS_ENABLE_DIFF_MARKDOWN_FORMAT=true
ATLANTIS_DISABLE_APPLY_ALL=false
ATLANTIS_REQUIRE_APPROVAL=true
ATLANTIS_REQUIRE_MERGEABLE=true
ATLANTIS_ENABLE_REGEXP_CMD=true
ATLANTIS_SILENCE_FORK_PR_ERRORS=true
ATLANTIS_WRITE_GIT_CREDS=true

# =============================================================================
# Terraform Configuration
# =============================================================================
TF_VAR_region=$($AWSConfig.Region)
TF_VAR_environment=workshop
TF_VAR_project_name=terraform-atlantis-workshop
TF_VAR_instance_type=t3.micro
TF_VAR_key_pair_name=

# =============================================================================
# Workshop Configuration
# =============================================================================
WORKSHOP_NAME="Terraform Atlantis Workshop"
WORKSHOP_VERSION="1.0.0"
WORKSHOP_AUTHOR="Nguyen Nhat Quang (Bright-04)"
WORKSHOP_EMAIL="cbl.nguyennhatquang2809@gmail.com"

# =============================================================================
# Compliance Configuration
# =============================================================================
COMPLIANCE_ALLOWED_INSTANCE_TYPES="t3.micro,t3.small,t3.medium"
COMPLIANCE_REQUIRED_TAGS="Environment,Project,CostCenter"
COMPLIANCE_S3_NAMING_PATTERN="terraform-atlantis-workshop-*"

# =============================================================================
# Monitoring Configuration
# =============================================================================
MONITORING_ENABLED=true
MONITORING_RETENTION_DAYS=7
MONITORING_ALERT_EMAIL=cbl.nguyennhatquang2809@gmail.com

# =============================================================================
# Security Configuration
# =============================================================================
SECURITY_ENCRYPTION_REQUIRED=true
SECURITY_PUBLIC_ACCESS_BLOCKED=true
SECURITY_VERSIONING_ENABLED=true

# =============================================================================
# Cost Control Configuration
# =============================================================================
COST_CONTROL_ENABLED=true
COST_CONTROL_MONTHLY_BUDGET=50
COST_CONTROL_ALERT_THRESHOLD=80

# =============================================================================
# Development Configuration
# =============================================================================
DEBUG_MODE=false
LOG_LEVEL=info
BACKUP_ENABLED=true
ROLLBACK_ENABLED=true

# =============================================================================
# Auto-generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# =============================================================================
"@

    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "✅ .env file created successfully!" -ForegroundColor Green
}

# =============================================================================
# Function to validate environment
# =============================================================================
function Test-Environment {
    Write-Host "`n🔍 Validating Environment Setup..." -ForegroundColor Yellow
    
    $checks = @()
    
    # Check .env file
    if (Test-Path ".env") {
        $checks += "✅ .env file exists"
    } else {
        $checks += "❌ .env file missing"
    }
    
    # Check AWS CLI
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        $checks += "✅ AWS CLI installed"
    } else {
        $checks += "❌ AWS CLI not found"
    }
    
    # Check Terraform
    if (Get-Command terraform -ErrorAction SilentlyContinue) {
        $checks += "✅ Terraform installed"
    } else {
        $checks += "❌ Terraform not found"
    }
    
    # Check Docker
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $checks += "✅ Docker installed"
    } else {
        $checks += "❌ Docker not found"
    }
    
    # Check GitHub CLI
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        $checks += "✅ GitHub CLI installed"
    } else {
        $checks += "⚠️  GitHub CLI not found (optional)"
    }
    
    # Display results
    Write-Host "`nEnvironment Validation Results:" -ForegroundColor Cyan
    foreach ($check in $checks) {
        Write-Host "   $check" -ForegroundColor $(if ($check -like "✅*") { "Green" } elseif ($check -like "⚠️*") { "Yellow" } else { "Red" })
    }
    
    # Check if all required components are present
    $requiredChecks = $checks | Where-Object { $_ -like "❌*" }
    if ($requiredChecks.Count -eq 0) {
        Write-Host "`n🎉 Environment setup is complete and ready!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "`n⚠️  Some required components are missing. Please install them and run again." -ForegroundColor Yellow
        return $false
    }
}

# =============================================================================
# Main execution
# =============================================================================

# Check if .env already exists
if (Test-EnvFile) {
    if (-not $Interactive -and -not $Force) {
        exit 0
    }
}

# Get AWS configuration
$awsConfig = Get-AWSCredentials

# Get GitHub configuration
$githubConfig = Get-GitHubConfig

# Create .env file
New-EnvFile -AWSConfig $awsConfig -GitHubConfig $githubConfig

# Validate environment
$envValid = Test-Environment

# Final instructions
Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Review the .env file and update any values if needed" -ForegroundColor Gray
Write-Host "   2. Run: .\scripts\01-validate-environment.ps1" -ForegroundColor Gray
Write-Host "   3. Run: .\scripts\02-setup-github-actions.ps1" -ForegroundColor Gray
Write-Host "   4. Run: .\scripts\03-deploy-infrastructure.ps1" -ForegroundColor Gray

if ($envValid) {
    Write-Host "`n🚀 Your environment is ready for the Terraform Atlantis Workshop!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Please fix the missing components and run this script again." -ForegroundColor Yellow
}

Write-Host "`n✅ Environment setup script completed!" -ForegroundColor Green
