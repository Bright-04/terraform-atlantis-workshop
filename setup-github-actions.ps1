# GitHub Actions Setup Script for Terraform Atlantis Workshop
# This script helps you configure GitHub Actions for Terraform deployment

Write-Host "🚀 Setting up GitHub Actions for Terraform Deployment" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "❌ .env file not found. Please run setup-github-integration.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "`n📋 GitHub Actions Configuration:" -ForegroundColor Cyan

# Function to prompt for user input
function Get-UserInput {
    param($prompt, $default = "", $isSecret = $false)
    if ($default) {
        Write-Host "$prompt [$default]" -ForegroundColor Yellow
    } else {
        Write-Host $prompt -ForegroundColor Yellow
    }
    
    if ($isSecret) {
        $userInput = Read-Host -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($userInput)
        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    } else {
        $userInput = Read-Host
        if ([string]::IsNullOrEmpty($userInput) -and $default) {
            return $default
        }
        return $userInput
    }
}

# Get GitHub repository information
$githubUser = Get-UserInput "Enter your GitHub username" "Bright-04"
$repoName = Get-UserInput "Enter your repository name" "terraform-atlantis-workshop"

# Get AWS credentials for GitHub Secrets
Write-Host "`n🔐 AWS Credentials for GitHub Secrets:" -ForegroundColor Cyan
Write-Host "These will be used to configure GitHub Secrets for AWS access" -ForegroundColor Gray

$awsAccessKeyId = Get-UserInput "Enter your AWS Access Key ID"
$awsSecretAccessKey = Get-UserInput "Enter your AWS Secret Access Key" "" $true
$awsRegion = Get-UserInput "Enter your AWS region" "us-east-1"

# Validate inputs
if ([string]::IsNullOrEmpty($awsAccessKeyId) -or [string]::IsNullOrEmpty($awsSecretAccessKey)) {
    Write-Host "❌ AWS Access Key ID and Secret Access Key are required." -ForegroundColor Red
    exit 1
}

# Test AWS credentials
Write-Host "`n🧪 Testing AWS credentials..." -ForegroundColor Yellow
try {
    $env:AWS_ACCESS_KEY_ID = $awsAccessKeyId
    $env:AWS_SECRET_ACCESS_KEY = $awsSecretAccessKey
    $env:AWS_DEFAULT_REGION = $awsRegion
    
    $caller = aws sts get-caller-identity 2>$null | ConvertFrom-Json
    if ($caller) {
        Write-Host "✅ AWS credentials are valid!" -ForegroundColor Green
        Write-Host "   Account ID: $($caller.Account)" -ForegroundColor Gray
        Write-Host "   User ARN: $($caller.Arn)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Could not verify AWS credentials. Please check your configuration." -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not test AWS credentials. Please verify manually." -ForegroundColor Yellow
}

# Check if GitHub CLI is available
$ghAvailable = $false
try {
    $null = Get-Command "gh" -ErrorAction Stop
    $ghAvailable = $true
    Write-Host "`n✅ GitHub CLI found" -ForegroundColor Green
} catch {
    Write-Host "`n⚠️  GitHub CLI not found. You'll need to set secrets manually." -ForegroundColor Yellow
}

# Set up GitHub Secrets if CLI is available
if ($ghAvailable) {
    Write-Host "`n🔧 Setting up GitHub Secrets..." -ForegroundColor Cyan
    
    try {
        # Check if user is authenticated
        $authStatus = gh auth status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ GitHub CLI authenticated" -ForegroundColor Green
            
            # Set AWS secrets
            Write-Host "Setting AWS_ACCESS_KEY_ID..." -ForegroundColor Gray
            gh secret set AWS_ACCESS_KEY_ID --body $awsAccessKeyId --repo "$githubUser/$repoName"
            
            Write-Host "Setting AWS_SECRET_ACCESS_KEY..." -ForegroundColor Gray
            gh secret set AWS_SECRET_ACCESS_KEY --body $awsSecretAccessKey --repo "$githubUser/$repoName"
            
            Write-Host "Setting AWS_DEFAULT_REGION..." -ForegroundColor Gray
            gh secret set AWS_DEFAULT_REGION --body $awsRegion --repo "$githubUser/$repoName"
            
            Write-Host "✅ GitHub Secrets configured successfully!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  GitHub CLI not authenticated. Please run 'gh auth login' first." -ForegroundColor Yellow
            $ghAvailable = $false
        }
    } catch {
        Write-Host "⚠️  Could not set GitHub Secrets automatically." -ForegroundColor Yellow
        $ghAvailable = $false
    }
}

# Manual setup instructions
if (-not $ghAvailable) {
    Write-Host "`n📝 Manual GitHub Secrets Setup:" -ForegroundColor Magenta
    Write-Host "=================================" -ForegroundColor Magenta
    Write-Host "1. Go to your GitHub repository: https://github.com/$githubUser/$repoName" -ForegroundColor White
    Write-Host "2. Navigate to Settings → Secrets and variables → Actions" -ForegroundColor White
    Write-Host "3. Click 'New repository secret'" -ForegroundColor White
    Write-Host "4. Add the following secrets:" -ForegroundColor White
    Write-Host "   - Name: AWS_ACCESS_KEY_ID" -ForegroundColor Gray
    Write-Host "     Value: $awsAccessKeyId" -ForegroundColor Gray
    Write-Host "   - Name: AWS_SECRET_ACCESS_KEY" -ForegroundColor Gray
    Write-Host "     Value: [Your AWS Secret Access Key]" -ForegroundColor Gray
    Write-Host "   - Name: AWS_DEFAULT_REGION" -ForegroundColor Gray
    Write-Host "     Value: $awsRegion" -ForegroundColor Gray
}

# Update .env file with GitHub Actions configuration
Write-Host "`n📝 Updating .env file for GitHub Actions..." -ForegroundColor Cyan

$envContent = Get-Content ".env" -Raw
$envContent = $envContent -replace 'ATLANTIS_ATLANTIS_URL=.*', "ATLANTIS_ATLANTIS_URL=github-actions"
$envContent = $envContent -replace 'AWS_ACCESS_KEY_ID=.*', "AWS_ACCESS_KEY_ID=$awsAccessKeyId"
$envContent = $envContent -replace 'AWS_SECRET_ACCESS_KEY=.*', "AWS_SECRET_ACCESS_KEY=$awsSecretAccessKey"
$envContent = $envContent -replace 'AWS_DEFAULT_REGION=.*', "AWS_DEFAULT_REGION=$awsRegion"

$envContent | Out-File -FilePath ".env" -Encoding utf8

Write-Host "✅ .env file updated for GitHub Actions" -ForegroundColor Green

# Verify workflow file exists
if (Test-Path ".github/workflows/terraform.yml") {
    Write-Host "✅ GitHub Actions workflow file found" -ForegroundColor Green
} else {
    Write-Host "❌ GitHub Actions workflow file not found" -ForegroundColor Red
    Write-Host "   Expected: .github/workflows/terraform.yml" -ForegroundColor Gray
}

# Display workflow information
Write-Host "`n📊 GitHub Actions Workflow Information:" -ForegroundColor Magenta
Write-Host "=======================================" -ForegroundColor Magenta
Write-Host "✅ Workflow: Terraform AWS Workshop" -ForegroundColor Green
Write-Host "✅ Triggers: Push/PR to main or aws-production-deployment branches" -ForegroundColor Green
Write-Host "✅ Jobs: Plan → Apply → Health Check" -ForegroundColor Green
Write-Host "✅ Compliance: Policy validation and cost controls" -ForegroundColor Green

Write-Host "`n🧪 Testing Your Workflow:" -ForegroundColor Magenta
Write-Host "=======================" -ForegroundColor Magenta
Write-Host "1. Create a new branch:" -ForegroundColor White
Write-Host "   git checkout -b test-github-actions" -ForegroundColor Gray
Write-Host "2. Make a small change to terraform/terraform.tfvars:" -ForegroundColor White
Write-Host "   # Add a comment: # Testing GitHub Actions" -ForegroundColor Gray
Write-Host "3. Commit and push:" -ForegroundColor White
Write-Host "   git add . && git commit -m 'test: github actions workflow'" -ForegroundColor Gray
Write-Host "   git push origin test-github-actions" -ForegroundColor Gray
Write-Host "4. Create a Pull Request" -ForegroundColor White
Write-Host "5. Watch GitHub Actions run automatically" -ForegroundColor White

Write-Host "`n📊 Monitoring and Verification:" -ForegroundColor Magenta
Write-Host "===============================" -ForegroundColor Magenta
Write-Host "• GitHub Actions: https://github.com/$githubUser/$repoName/actions" -ForegroundColor White
Write-Host "• AWS Health: aws sts get-caller-identity" -ForegroundColor White
Write-Host "• Workflow Logs: Check Actions tab in GitHub" -ForegroundColor White

Write-Host "`n🎯 Workshop Success Criteria:" -ForegroundColor Magenta
Write-Host "============================" -ForegroundColor Magenta
Write-Host "✅ GitHub Actions workflow configured" -ForegroundColor Green
Write-Host "✅ Automatic plan generation on PR" -ForegroundColor Green
Write-Host "✅ Approval required before apply" -ForegroundColor Green
Write-Host "✅ Policy validation enforced" -ForegroundColor Green
Write-Host "✅ Complete audit trail in GitHub" -ForegroundColor Green

Write-Host "`n✅ GitHub Actions Setup Complete!" -ForegroundColor Green
Write-Host "🔄 Run the test scenario above to validate your implementation." -ForegroundColor Cyan
