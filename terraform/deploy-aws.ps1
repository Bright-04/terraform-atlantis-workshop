# AWS Production Deployment Script for Terraform Atlantis Workshop
# This script deploys infrastructure to real AWS instead of LocalStack

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "production",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipConfirmation = $false
)

Write-Host "🚀 AWS Production Deployment for Terraform Atlantis Workshop" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Gray

# Function to check AWS credentials
function Test-AWSCredentials {
    Write-Host "`n🔐 Checking AWS Credentials..." -ForegroundColor Yellow
    
    try {
        $caller = aws sts get-caller-identity 2>$null | ConvertFrom-Json
        if ($caller) {
            Write-Host "✅ AWS Credentials Valid" -ForegroundColor Green
            Write-Host "   Account ID: $($caller.Account)" -ForegroundColor Gray
            Write-Host "   User ARN: $($caller.Arn)" -ForegroundColor Gray
            Write-Host "   User ID: $($caller.UserId)" -ForegroundColor Gray
            return $true
        }
    }
    catch {
        Write-Host "❌ AWS Credentials Invalid or Not Configured" -ForegroundColor Red
        Write-Host "   Please run: aws configure" -ForegroundColor Yellow
        Write-Host "   Or set environment variables:" -ForegroundColor Yellow
        Write-Host "   - AWS_ACCESS_KEY_ID" -ForegroundColor Gray
        Write-Host "   - AWS_SECRET_ACCESS_KEY" -ForegroundColor Gray
        Write-Host "   - AWS_DEFAULT_REGION" -ForegroundColor Gray
        return $false
    }
}

# Function to check AWS region
function Test-AWSRegion {
    Write-Host "`n🌍 Checking AWS Region..." -ForegroundColor Yellow
    
    try {
        $region = aws configure get region 2>$null
        if ($region) {
            Write-Host "✅ AWS Region: $region" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "❌ AWS Region not configured" -ForegroundColor Red
            Write-Host "   Please run: aws configure" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "❌ Could not determine AWS region" -ForegroundColor Red
        return $false
    }
}

# Function to estimate costs
function Show-CostEstimate {
    Write-Host "`n💰 Estimated Monthly Costs (approximate):" -ForegroundColor Yellow
    
    $costs = @{
        "EC2 t3.micro (2 instances)" = "$15-20"
        "S3 Storage (1GB)" = "$0.023"
        "CloudWatch Logs" = "$0.50"
        "Data Transfer" = "$0.09/GB"
        "Total Estimated" = "$20-30/month"
    }
    
    foreach ($item in $costs.GetEnumerator()) {
        Write-Host "   $($item.Key): $($item.Value)" -ForegroundColor Gray
    }
    
    Write-Host "`n⚠️  This will create real AWS resources that may incur costs!" -ForegroundColor Red
}

# Function to backup current configuration
function Backup-CurrentConfig {
    Write-Host "`n📦 Creating backup of current configuration..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = "backups\aws-deployment-$timestamp"
    
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    # Backup current main.tf if it exists
    if (Test-Path "main.tf") {
        Copy-Item "main.tf" "$backupDir\main-localstack.tf.backup"
        Write-Host "   ✅ Current main.tf backed up" -ForegroundColor Green
    }
    
    # Backup terraform state if it exists
    if (Test-Path "terraform.tfstate") {
        Copy-Item "terraform.tfstate" "$backupDir\terraform.tfstate.backup"
        Write-Host "   ✅ Terraform state backed up" -ForegroundColor Green
    }
    
    return $backupDir
}

# Function to switch to AWS configuration
function Switch-ToAWSConfig {
    Write-Host "`n🔄 Switching to AWS Production Configuration..." -ForegroundColor Yellow
    
    # Backup current config
    $backupPath = Backup-CurrentConfig
    
    # Switch to AWS configuration
    Copy-Item "main-aws.tf" "main.tf" -Force
    Write-Host "   ✅ Switched to AWS configuration" -ForegroundColor Green
    
    # Update terraform.tfvars for production
    if (Test-Path "terraform.tfvars") {
        $tfvars = Get-Content "terraform.tfvars" -Raw
        $tfvars = $tfvars -replace 'environment\s*=\s*".*"', 'environment = "production"'
        $tfvars = $tfvars -replace 'instance_type\s*=\s*".*"', 'instance_type = "t3.micro"'
        $tfvars | Set-Content "terraform.tfvars"
        Write-Host "   ✅ Updated terraform.tfvars for production" -ForegroundColor Green
    }
    
    return $backupPath
}

# Function to validate Terraform configuration
function Test-TerraformConfig {
    Write-Host "`n🔍 Validating Terraform Configuration..." -ForegroundColor Yellow
    
    # Initialize Terraform
    Write-Host "   Initializing Terraform..." -ForegroundColor Gray
    terraform init
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Terraform init failed!" -ForegroundColor Red
        return $false
    }
    
    # Validate configuration
    Write-Host "   Validating configuration..." -ForegroundColor Gray
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Terraform validation failed!" -ForegroundColor Red
        return $false
    }
    
    Write-Host "   ✅ Terraform configuration is valid" -ForegroundColor Green
    return $true
}

# Function to plan deployment
function Plan-Deployment {
    Write-Host "`n📋 Planning AWS Deployment..." -ForegroundColor Yellow
    
    $planFile = "aws-deployment-plan.tfplan"
    
    terraform plan -out=$planFile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Terraform plan failed!" -ForegroundColor Red
        return $false
    }
    
    Write-Host "   ✅ Deployment plan created: $planFile" -ForegroundColor Green
    return $planFile
}

# Function to apply deployment
function Apply-Deployment {
    param([string]$PlanFile)
    
    Write-Host "`n🔨 Applying AWS Deployment..." -ForegroundColor Yellow
    
    if (-not $SkipConfirmation) {
        Write-Host "`n⚠️  PRODUCTION DEPLOYMENT WARNING:" -ForegroundColor Red
        Write-Host "   This will create real AWS resources that may incur costs!" -ForegroundColor Red
        Write-Host "   Make sure you have proper AWS permissions and budget." -ForegroundColor Yellow
        
        $confirmation = Read-Host "   Do you want to proceed with AWS deployment? (type 'yes' to continue)"
        if ($confirmation -ne 'yes') {
            Write-Host "   ❌ Deployment cancelled by user" -ForegroundColor Yellow
            Remove-Item $PlanFile -ErrorAction SilentlyContinue
            return $false
        }
    }
    
    terraform apply $PlanFile
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ AWS deployment completed successfully!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "   ❌ AWS deployment failed!" -ForegroundColor Red
        return $false
    }
}

# Function to show deployment outputs
function Show-DeploymentOutputs {
    Write-Host "`n📊 AWS Infrastructure Outputs:" -ForegroundColor Yellow
    
    try {
        $outputs = terraform output -json | ConvertFrom-Json
        foreach ($output in $outputs.PSObject.Properties) {
            Write-Host "   $($output.Name): $($output.Value.value)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "   Could not retrieve outputs" -ForegroundColor Yellow
    }
}

# Function to show next steps
function Show-NextSteps {
    Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Verify resources in AWS Console" -ForegroundColor White
    Write-Host "   2. Test web server accessibility" -ForegroundColor White
    Write-Host "   3. Monitor CloudWatch logs" -ForegroundColor White
    Write-Host "   4. Set up monitoring and alerting" -ForegroundColor White
    Write-Host "   5. Configure backup strategies" -ForegroundColor White
    Write-Host "   6. Review security configurations" -ForegroundColor White
    
    Write-Host "`n🔗 Useful AWS Console Links:" -ForegroundColor Cyan
    Write-Host "   - EC2 Instances: https://console.aws.amazon.com/ec2/v2/home" -ForegroundColor Gray
    Write-Host "   - VPC Dashboard: https://console.aws.amazon.com/vpc/home" -ForegroundColor Gray
    Write-Host "   - S3 Buckets: https://console.aws.amazon.com/s3/home" -ForegroundColor Gray
    Write-Host "   - CloudWatch: https://console.aws.amazon.com/cloudwatch/home" -ForegroundColor Gray
}

# Main execution
Write-Host "`n🎯 Environment: $Environment" -ForegroundColor Magenta

# Check prerequisites
$credentialsValid = Test-AWSCredentials
$regionValid = Test-AWSRegion

if (-not $credentialsValid -or -not $regionValid) {
    Write-Host "`n❌ Prerequisites not met. Please configure AWS credentials and region." -ForegroundColor Red
    exit 1
}

# Show cost estimate
Show-CostEstimate

# Switch to AWS configuration
$backupPath = Switch-ToAWSConfig
Write-Host "   Backup location: $backupPath" -ForegroundColor Gray

# Validate configuration
if (-not (Test-TerraformConfig)) {
    Write-Host "`n❌ Configuration validation failed!" -ForegroundColor Red
    exit 1
}

# Plan deployment
$planFile = Plan-Deployment
if (-not $planFile) {
    Write-Host "`n❌ Deployment planning failed!" -ForegroundColor Red
    exit 1
}

# Apply deployment
$deploymentSuccess = Apply-Deployment -PlanFile $planFile

# Show results
if ($deploymentSuccess) {
    Write-Host "`n🎉 AWS Production Deployment Successful!" -ForegroundColor Green
    Show-DeploymentOutputs
    Show-NextSteps
} else {
    Write-Host "`n❌ AWS Production Deployment Failed!" -ForegroundColor Red
    Write-Host "   Check the error messages above and try again." -ForegroundColor Yellow
    Write-Host "   Backup location: $backupPath" -ForegroundColor Yellow
    exit 1
}

# Cleanup plan file
Remove-Item $planFile -ErrorAction SilentlyContinue

Write-Host "`n✅ AWS Production Deployment Script Completed!" -ForegroundColor Green
