# GitHub Atlantis Integration Setup Script
# Enhanced version with proper environment detection

Write-Host "🚀 Setting up GitHub Atlantis Integration..." -ForegroundColor Green

# Function to detect environment
function Test-Environment {
    Write-Host "`n🔍 Detecting Environment..." -ForegroundColor Yellow
    
    # Check if we're in AWS production environment
    try {
        $caller = aws sts get-caller-identity 2>$null | ConvertFrom-Json
        if ($caller) {
            Write-Host "✅ AWS Production Environment Detected" -ForegroundColor Green
            Write-Host "   Account ID: $($caller.Account)" -ForegroundColor Gray
            return "aws-production"
        }
    }
    catch {
        # Check if LocalStack is running
        try {
            $localstack = docker ps --filter "name=localstack" --format "table {{.Names}}" 2>$null
            if ($localstack -and $localstack.Contains("localstack")) {
                Write-Host "✅ LocalStack Development Environment Detected" -ForegroundColor Green
                return "localstack"
            }
        }
        catch {
            # Check if we have terraform state
            if (Test-Path "terraform\terraform.tfstate") {
                Write-Host "✅ Terraform State Found - Likely AWS Production" -ForegroundColor Green
                return "aws-production"
            }
        }
    }
    
    Write-Host "⚠️  Environment not clearly detected" -ForegroundColor Yellow
    return "unknown"
}

# Function to prompt for user input
function Get-UserInput {
    param($prompt, $default = "")
    if ($default) {
        Write-Host "$prompt [$default]" -ForegroundColor Yellow
    } else {
        Write-Host $prompt -ForegroundColor Yellow
    }
    $userInput = Read-Host
    if ([string]::IsNullOrEmpty($userInput) -and $default) {
        return $default
    }
    return $userInput
}

# Function to test if ngrok is available
function Test-NgrokAvailable {
    try {
        $null = Get-Command "ngrok" -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Detect environment first
$environment = Test-Environment

# Collect GitHub credentials
Write-Host "`n📋 GitHub Configuration:" -ForegroundColor Cyan
$githubUser = Get-UserInput "Enter your GitHub username" "Bright-04"
$githubToken = Get-UserInput "Enter your GitHub Personal Access Token (requires repo, admin:repo_hook permissions)"
$repoName = Get-UserInput "Enter your repository name" "terraform-atlantis-workshop"
$webhookSecret = Get-UserInput "Enter your GitHub webhook secret (or leave blank to generate)"

if ([string]::IsNullOrEmpty($webhookSecret)) {
    # Generate a secure webhook secret
    $webhookSecret = [System.Web.Security.Membership]::GeneratePassword(32, 8)
    Write-Host "✨ Generated webhook secret: $webhookSecret" -ForegroundColor Cyan
}

# Environment-specific configuration
if ($environment -eq "aws-production") {
    Write-Host "`n🌐 AWS Production Configuration:" -ForegroundColor Cyan
    Write-Host "✅ Running in AWS Production - No ngrok needed!" -ForegroundColor Green
    
    # For AWS production, we need a public endpoint for Atlantis
    Write-Host "`n📡 Atlantis Public Endpoint Configuration:" -ForegroundColor Yellow
    Write-Host "For AWS production, you need to deploy Atlantis with a public endpoint:" -ForegroundColor White
    Write-Host "1. Deploy Atlantis on EC2 with public IP" -ForegroundColor Gray
    Write-Host "2. Use Application Load Balancer" -ForegroundColor Gray
    Write-Host "3. Use AWS App Runner or ECS" -ForegroundColor Gray
    Write-Host "4. Use GitHub Actions instead of Atlantis" -ForegroundColor Gray
    
    $deploymentOption = Get-UserInput "Choose deployment option (1-4)" "4"
    
    switch ($deploymentOption) {
        "1" { 
            $atlantisUrl = Get-UserInput "Enter your EC2 public IP/domain for Atlantis" "http://your-ec2-ip:4141"
            Write-Host "✅ Using EC2 deployment: $atlantisUrl" -ForegroundColor Green
        }
        "2" { 
            $atlantisUrl = Get-UserInput "Enter your ALB domain for Atlantis" "https://your-alb-domain.com"
            Write-Host "✅ Using ALB deployment: $atlantisUrl" -ForegroundColor Green
        }
        "3" { 
            $atlantisUrl = Get-UserInput "Enter your App Runner/ECS domain for Atlantis" "https://your-app-runner-domain.com"
            Write-Host "✅ Using App Runner/ECS deployment: $atlantisUrl" -ForegroundColor Green
        }
        "4" { 
            Write-Host "✅ Using GitHub Actions - No external endpoint needed!" -ForegroundColor Green
            $atlantisUrl = "github-actions"
        }
        default { 
            Write-Host "✅ Using GitHub Actions (default)" -ForegroundColor Green
            $atlantisUrl = "github-actions"
        }
    }
}
elseif ($environment -eq "localstack") {
    Write-Host "`n🌐 LocalStack Development Configuration:" -ForegroundColor Cyan
    Write-Host "⚠️  LocalStack detected - ngrok needed for webhook tunneling" -ForegroundColor Yellow
    
    # Check if ngrok is available and offer to start it
    if (Test-NgrokAvailable) {
        $startNgrok = Get-UserInput "Start ngrok tunnel automatically? (Y/n)" "Y"
        if ($startNgrok -eq 'Y' -or $startNgrok -eq 'y' -or [string]::IsNullOrEmpty($startNgrok)) {
            Write-Host "🚀 Starting ngrok tunnel..." -ForegroundColor Yellow
            Start-Process "ngrok" -ArgumentList "http", "4141" -PassThru
            Start-Sleep 3
            
            try {
                $ngrokApi = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
                $atlantisUrl = $ngrokApi.tunnels[0].public_url
                Write-Host "✅ Ngrok tunnel started: $atlantisUrl" -ForegroundColor Green
            } catch {
                Write-Host "⚠️  Could not auto-detect ngrok URL. Please enter manually." -ForegroundColor Yellow
                $atlantisUrl = Get-UserInput "Enter your ngrok URL"
            }
        } else {
            $atlantisUrl = Get-UserInput "Enter your ngrok URL (e.g., https://abc123.ngrok-free.app)"
        }
    } else {
        Write-Host "⚠️  ngrok not found. Please install ngrok and start it manually." -ForegroundColor Yellow
        $atlantisUrl = Get-UserInput "Enter your ngrok URL (e.g., https://abc123.ngrok-free.app)"
    }
}
else {
    Write-Host "`n🌐 Unknown Environment Configuration:" -ForegroundColor Cyan
    Write-Host "⚠️  Environment not detected - assuming local development" -ForegroundColor Yellow
    $atlantisUrl = Get-UserInput "Enter your Atlantis URL (or 'github-actions' for GitHub Actions)" "github-actions"
}

# Create enhanced environment file
$envContent = @"
# Enhanced GitHub Integration Configuration
# Environment: $environment
# Generated: $(Get-Date)

# GitHub Configuration
ATLANTIS_GH_USER=$githubUser
ATLANTIS_GH_TOKEN=$githubToken
ATLANTIS_GH_WEBHOOK_SECRET=$webhookSecret

# Repository Configuration
ATLANTIS_REPO_ALLOWLIST=github.com/$githubUser/$repoName

# Atlantis URL Configuration
ATLANTIS_ATLANTIS_URL=$atlantisUrl

# Enhanced Workflow Configuration
ATLANTIS_LOG_LEVEL=info
ATLANTIS_DEFAULT_TF_VERSION=v1.6.0
ATLANTIS_ENABLE_POLICY_CHECKS=true
ATLANTIS_ENABLE_DIFF_MARKDOWN_FORMAT=true
ATLANTIS_DISABLE_APPLY_ALL=true
ATLANTIS_REQUIRE_APPROVAL=true
ATLANTIS_REQUIRE_MERGEABLE=true

# Security Configuration
ATLANTIS_SSL_CERT_FILE=
ATLANTIS_SSL_KEY_FILE=
ATLANTIS_DATA_DIR=/atlantis

# Workshop-specific Configuration
ATLANTIS_ENABLE_REGEXP_CMD=false
ATLANTIS_SILENCE_FORK_PR_ERRORS=false
ATLANTIS_WRITE_GIT_CREDS=false

# AWS Configuration (for Atlantis to access AWS)
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
"@

$envContent | Out-File -FilePath ".env" -Encoding utf8
Write-Host "✅ Created enhanced .env file with environment-specific configuration" -ForegroundColor Green

# Environment-specific instructions
if ($environment -eq "aws-production") {
    if ($deploymentOption -eq "4") {
        Write-Host "`n🔧 GitHub Actions Setup Instructions:" -ForegroundColor Magenta
        Write-Host "1. Create .github/workflows/terraform.yml" -ForegroundColor White
        Write-Host "2. Configure GitHub Secrets:" -ForegroundColor White
        Write-Host "   - AWS_ACCESS_KEY_ID" -ForegroundColor Gray
        Write-Host "   - AWS_SECRET_ACCESS_KEY" -ForegroundColor Gray
        Write-Host "   - AWS_DEFAULT_REGION" -ForegroundColor Gray
        Write-Host "3. No webhook setup needed - GitHub Actions runs automatically" -ForegroundColor White
    } else {
        Write-Host "`n🔧 AWS Production Webhook Setup:" -ForegroundColor Magenta
        Write-Host "1. Go to your GitHub repository: https://github.com/$githubUser/$repoName" -ForegroundColor White
        Write-Host "2. Navigate to Settings → Webhooks" -ForegroundColor White
        Write-Host "3. Click 'Add webhook'" -ForegroundColor White
        Write-Host "4. Configure the webhook:" -ForegroundColor White
        Write-Host "   - Payload URL: $atlantisUrl/events" -ForegroundColor Gray
        Write-Host "   - Content type: application/json" -ForegroundColor Gray
        Write-Host "   - Secret: $webhookSecret" -ForegroundColor Gray
        Write-Host "   - Events: Pull requests, Pull request reviews, Push, Issue comments" -ForegroundColor Gray
        Write-Host "5. Click 'Add webhook'" -ForegroundColor White
    }
} else {
    Write-Host "`n🔧 Local Development Webhook Setup:" -ForegroundColor Magenta
    Write-Host "1. Go to your GitHub repository: https://github.com/$githubUser/$repoName" -ForegroundColor White
    Write-Host "2. Navigate to Settings → Webhooks" -ForegroundColor White
    Write-Host "3. Click 'Add webhook'" -ForegroundColor White
    Write-Host "4. Configure the webhook:" -ForegroundColor White
    Write-Host "   - Payload URL: $atlantisUrl/events" -ForegroundColor Gray
    Write-Host "   - Content type: application/json" -ForegroundColor Gray
    Write-Host "   - Secret: $webhookSecret" -ForegroundColor Gray
    Write-Host "   - Events: Pull requests, Pull request reviews, Push, Issue comments" -ForegroundColor Gray
    Write-Host "5. Click 'Add webhook'" -ForegroundColor White
}

Write-Host "`n🧪 Testing Your Workflow:" -ForegroundColor Magenta
Write-Host "1. Create a new branch:" -ForegroundColor White
Write-Host "   git checkout -b test-workflow" -ForegroundColor Gray
Write-Host "2. Make a small change to terraform/terraform.tfvars:" -ForegroundColor White
Write-Host "   # Add a comment: # Testing workflow" -ForegroundColor Gray
Write-Host "3. Commit and push:" -ForegroundColor White
Write-Host "   git add . && git commit -m 'test: workflow'" -ForegroundColor Gray
Write-Host "   git push origin test-workflow" -ForegroundColor Gray
Write-Host "4. Create a Pull Request" -ForegroundColor White
Write-Host "5. Watch for automated plan/apply" -ForegroundColor White

Write-Host "`n📊 Monitoring and Verification:" -ForegroundColor Magenta
if ($deploymentOption -eq "4") {
    Write-Host "• GitHub Actions: https://github.com/$githubUser/$repoName/actions" -ForegroundColor White
    Write-Host "• AWS Health: aws sts get-caller-identity" -ForegroundColor White
} else {
    Write-Host "• Atlantis UI: $atlantisUrl" -ForegroundColor White
    Write-Host "• Atlantis Logs: docker-compose logs atlantis" -ForegroundColor White
    Write-Host "• AWS Health: aws sts get-caller-identity" -ForegroundColor White
}
Write-Host "• Test Policy Validation: policies/ directory contains security and cost controls" -ForegroundColor White

Write-Host "`n🎯 Workshop Success Criteria:" -ForegroundColor Magenta
Write-Host "✅ GitHub integration working" -ForegroundColor Green
Write-Host "✅ Automatic plan generation on PR" -ForegroundColor Green
Write-Host "✅ Approval required before apply" -ForegroundColor Green
Write-Host "✅ Policy validation enforced" -ForegroundColor Green
Write-Host "✅ Complete audit trail in GitHub" -ForegroundColor Green

Write-Host "`n✅ Enhanced Setup Complete!" -ForegroundColor Green
Write-Host "🔄 Run the test scenario above to validate your implementation." -ForegroundColor Cyan
