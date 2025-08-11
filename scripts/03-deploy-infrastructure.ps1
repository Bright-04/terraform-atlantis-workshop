# =============================================================================
# 03 - Production Infrastructure Deployment Script
# =============================================================================
# This script deploys the complete production infrastructure to AWS
# 
# Workflow Order:
# 1. 01-validate-environment.ps1
# 2. 02-setup-github-actions.ps1
# 3. 03-deploy-infrastructure.ps1 (this script)
# 4. 04-health-monitoring.ps1
# 5. 05-cost-monitoring.ps1
# 6. 06-rollback-procedures.ps1
# 7. 07-cleanup-infrastructure.ps1
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "production",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipConfirmation = $false
)

Write-Host "🚀 Step 3: Production Deployment for Terraform Atlantis Workshop" -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Gray

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "`n🔍 Checking Prerequisites..." -ForegroundColor Yellow
    
    # Check AWS CLI
    try {
        $awsVersion = aws --version 2>$null
        if ($awsVersion) {
            Write-Host "✅ AWS CLI installed" -ForegroundColor Green
        } else {
            Write-Host "❌ AWS CLI not found" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ AWS CLI not installed" -ForegroundColor Red
        return $false
    }
    
    # Check Terraform
    try {
        $tfVersion = terraform --version 2>$null
        if ($tfVersion) {
            Write-Host "✅ Terraform installed" -ForegroundColor Green
        } else {
            Write-Host "❌ Terraform not found" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Terraform not installed" -ForegroundColor Red
        return $false
    }
    
    # Check Docker (for Atlantis)
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion) {
            Write-Host "✅ Docker installed" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Docker not found (required for Atlantis)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠️ Docker not installed (required for Atlantis)" -ForegroundColor Yellow
    }
    
    return $true
}

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

# Function to show production cost estimate
function Show-ProductionCostEstimate {
    Write-Host "`n💰 Production Cost Estimate (monthly):" -ForegroundColor Yellow
    
    $costs = @{
        "EC2 t3.micro (2 instances)" = "$15-20"
        "S3 Storage (1GB)" = "$0.023"
        "CloudWatch Logs" = "$0.50"
        "Data Transfer" = "$0.09/GB"
        "VPC & Networking" = "$0.00"
        "IAM & Security" = "$0.00"
        "Total Estimated" = "$20-30/month"
    }
    
    foreach ($item in $costs.GetEnumerator()) {
        Write-Host "   $($item.Key): $($item.Value)" -ForegroundColor Gray
    }
    
    Write-Host "`n⚠️  This will create real AWS production resources!" -ForegroundColor Red
    Write-Host "   Ensure you have proper AWS permissions and budget." -ForegroundColor Yellow
}

# Function to validate Terraform configuration
function Test-TerraformConfig {
    Write-Host "`n🔍 Validating Terraform Configuration..." -ForegroundColor Yellow
    
    Set-Location terraform
    
    # Initialize Terraform
    Write-Host "   Initializing Terraform..." -ForegroundColor Gray
    terraform init
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Terraform init failed!" -ForegroundColor Red
        Set-Location ..
        return $false
    }
    
    # Validate configuration
    Write-Host "   Validating configuration..." -ForegroundColor Gray
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Terraform validation failed!" -ForegroundColor Red
        Set-Location ..
        return $false
    }
    
    # Format check
    Write-Host "   Checking format..." -ForegroundColor Gray
    terraform fmt -check
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ⚠️ Terraform format issues found" -ForegroundColor Yellow
    }
    
    Set-Location ..
    Write-Host "   ✅ Terraform configuration is valid" -ForegroundColor Green
    return $true
}

# Function to plan production deployment
function Plan-ProductionDeployment {
    Write-Host "`n📋 Planning Production Deployment..." -ForegroundColor Yellow
    
    Set-Location terraform
    
    $planFile = "production-deployment-plan.tfplan"
    
    terraform plan -out=$planFile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Terraform plan failed!" -ForegroundColor Red
        Set-Location ..
        return $false
    }
    
    Set-Location ..
    Write-Host "   ✅ Production plan created: $planFile" -ForegroundColor Green
    return $planFile
}

# Function to apply production deployment
function Apply-ProductionDeployment {
    param([string]$PlanFile)
    
    Write-Host "`n🔨 Applying Production Deployment..." -ForegroundColor Yellow
    
    if (-not $SkipConfirmation) {
        Write-Host "`n🚨 PRODUCTION DEPLOYMENT WARNING:" -ForegroundColor Red
        Write-Host "   This will create real AWS production resources!" -ForegroundColor Red
        Write-Host "   Make sure you have proper AWS permissions and budget." -ForegroundColor Yellow
        Write-Host "   This deployment will incur real AWS costs." -ForegroundColor Red
        
        $confirmation = Read-Host "   Do you want to proceed with production deployment? (type 'yes' to continue)"
        if ($confirmation -ne 'yes') {
            Write-Host "   ❌ Deployment cancelled by user" -ForegroundColor Yellow
            Remove-Item "terraform/$PlanFile" -ErrorAction SilentlyContinue
            return $false
        }
    }
    
    Set-Location terraform
    terraform apply $PlanFile
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Production deployment completed successfully!" -ForegroundColor Green
        Set-Location ..
        return $true
    } else {
        Write-Host "   ❌ Production deployment failed!" -ForegroundColor Red
        Set-Location ..
        return $false
    }
}

# Function to show deployment outputs
function Show-DeploymentOutputs {
    Write-Host "`n📊 Production Infrastructure Outputs:" -ForegroundColor Yellow
    
    Set-Location terraform
    
    try {
        $outputs = terraform output -json | ConvertFrom-Json
        foreach ($output in $outputs.PSObject.Properties) {
            Write-Host "   $($output.Name): $($output.Value.value)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "   Could not retrieve outputs" -ForegroundColor Yellow
    }
    
    Set-Location ..
}

# Function to run production health check
function Test-ProductionHealth {
    Write-Host "`n🔍 Running Production Health Check..." -ForegroundColor Yellow
    
    if (Test-Path "monitoring\health-check-aws.ps1") {
        & ".\monitoring\health-check-aws.ps1"
    } else {
        Write-Host "   ⚠️ Health check script not found" -ForegroundColor Yellow
    }
}

# Function to show production next steps
function Show-ProductionNextSteps {
    Write-Host "`n🎯 Production Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Verify resources in AWS Console" -ForegroundColor White
    Write-Host "   2. Test web server accessibility" -ForegroundColor White
    Write-Host "   3. Monitor CloudWatch logs" -ForegroundColor White
    Write-Host "   4. Set up monitoring and alerting" -ForegroundColor White
    Write-Host "   5. Configure backup strategies" -ForegroundColor White
    Write-Host "   6. Review security configurations" -ForegroundColor White
    Write-Host "   7. Set up GitHub Actions secrets" -ForegroundColor White
    Write-Host "   8. Configure Atlantis webhooks" -ForegroundColor White
    
    Write-Host "`n🔗 Production Console Links:" -ForegroundColor Cyan
    $region = aws configure get region 2>$null
    Write-Host "   - EC2 Instances: https://console.aws.amazon.com/ec2/v2/home?region=$region" -ForegroundColor Gray
    Write-Host "   - VPC Dashboard: https://console.aws.amazon.com/vpc/home?region=$region" -ForegroundColor Gray
    Write-Host "   - S3 Buckets: https://console.aws.amazon.com/s3/home" -ForegroundColor Gray
    Write-Host "   - CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=$region" -ForegroundColor Gray
    Write-Host "   - IAM Console: https://console.aws.amazon.com/iam/home" -ForegroundColor Gray
}

# Main execution
Write-Host "`n🎯 Environment: $Environment (Production)" -ForegroundColor Magenta

# Check prerequisites
$prerequisitesMet = Test-Prerequisites
if (-not $prerequisitesMet) {
    Write-Host "`n❌ Prerequisites not met. Please install required software." -ForegroundColor Red
    exit 1
}

# Check AWS credentials
$credentialsValid = Test-AWSCredentials
$regionValid = Test-AWSRegion

if (-not $credentialsValid -or -not $regionValid) {
    Write-Host "`n❌ AWS configuration not complete. Please configure AWS credentials and region." -ForegroundColor Red
    exit 1
}

# Show cost estimate
Show-ProductionCostEstimate

# Validate configuration
if (-not (Test-TerraformConfig)) {
    Write-Host "`n❌ Configuration validation failed!" -ForegroundColor Red
    exit 1
}

# Plan deployment
$planFile = Plan-ProductionDeployment
if (-not $planFile) {
    Write-Host "`n❌ Deployment planning failed!" -ForegroundColor Red
    exit 1
}

# Apply deployment
$deploymentSuccess = Apply-ProductionDeployment -PlanFile $planFile

# Show results
if ($deploymentSuccess) {
    Write-Host "`n🎉 Production Deployment Successful!" -ForegroundColor Green
    Show-DeploymentOutputs
    Test-ProductionHealth
    Show-ProductionNextSteps
} else {
    Write-Host "`n❌ Production Deployment Failed!" -ForegroundColor Red
    Write-Host "   Check the error messages above and try again." -ForegroundColor Yellow
    exit 1
}

# Cleanup plan file
Remove-Item "terraform/$planFile" -ErrorAction SilentlyContinue

Write-Host "`n✅ Production Deployment Script Completed!" -ForegroundColor Green
Write-Host "🔄 Your infrastructure is now ready for production use!" -ForegroundColor Cyan
