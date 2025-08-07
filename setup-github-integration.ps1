# GitHub Atlantis Integration Setup Script
# Enhanced version with approval workflow configuration

Write-Host "🚀 Setting up Enhanced GitHub Atlantis Integration..." -ForegroundColor Green

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

# Check if .env already exists
if (Test-Path ".env") {
    $overwrite = Get-UserInput "⚠️  .env file already exists. Overwrite? (y/N)" "N"
    if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
        Write-Host "✅ Using existing .env file" -ForegroundColor Green
        Write-Host "Current configuration:" -ForegroundColor Cyan
        Get-Content ".env" | Where-Object { $_ -notmatch "TOKEN|SECRET" }
        exit 0
    }
}

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

# Check if ngrok is available and offer to start it
Write-Host "`n🌐 Ngrok Configuration:" -ForegroundColor Cyan
if (Test-NgrokAvailable) {
    $startNgrok = Get-UserInput "Start ngrok tunnel automatically? (Y/n)" "Y"
    if ($startNgrok -eq 'Y' -or $startNgrok -eq 'y' -or [string]::IsNullOrEmpty($startNgrok)) {
        Write-Host "🚀 Starting ngrok tunnel..." -ForegroundColor Yellow
        Start-Process "ngrok" -ArgumentList "http", "4141" -PassThru
        Start-Sleep 3
        
        try {
            $ngrokApi = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
            $ngrokUrl = $ngrokApi.tunnels[0].public_url
            Write-Host "✅ Ngrok tunnel started: $ngrokUrl" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Could not auto-detect ngrok URL. Please enter manually." -ForegroundColor Yellow
            $ngrokUrl = Get-UserInput "Enter your ngrok URL"
        }
    } else {
        $ngrokUrl = Get-UserInput "Enter your ngrok URL (e.g., https://abc123.ngrok-free.app)"
    }
} else {
    Write-Host "⚠️  ngrok not found. Please install ngrok and start it manually." -ForegroundColor Yellow
    $ngrokUrl = Get-UserInput "Enter your ngrok URL (e.g., https://abc123.ngrok-free.app)"
}

# Create enhanced environment file
$envContent = @"
# Enhanced GitHub Integration Configuration for Approval Workflows
# This file is ignored by git and won't be committed

# GitHub Configuration
ATLANTIS_GH_USER=$githubUser
ATLANTIS_GH_TOKEN=$githubToken
ATLANTIS_GH_WEBHOOK_SECRET=$webhookSecret

# Repository Configuration
ATLANTIS_REPO_ALLOWLIST=github.com/$githubUser/$repoName

# Atlantis URL Configuration
ATLANTIS_ATLANTIS_URL=$ngrokUrl

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
"@

$envContent | Out-File -FilePath ".env" -Encoding utf8
Write-Host "✅ Created enhanced .env file with approval workflow configuration" -ForegroundColor Green

# Enhanced instructions for GitHub webhook setup and testing
Write-Host "`n🔧 Step-by-Step GitHub Webhook Setup:" -ForegroundColor Magenta
Write-Host "1. Go to your GitHub repository: https://github.com/$githubUser/$repoName" -ForegroundColor White
Write-Host "2. Navigate to Settings → Webhooks" -ForegroundColor White
Write-Host "3. Click 'Add webhook'" -ForegroundColor White
Write-Host "4. Configure the webhook:" -ForegroundColor White
Write-Host "   - Payload URL: $ngrokUrl/events" -ForegroundColor Gray
Write-Host "   - Content type: application/json" -ForegroundColor Gray
Write-Host "   - Secret: $webhookSecret" -ForegroundColor Gray
Write-Host "   - Events: Pull requests, Pull request reviews, Push, Issue comments" -ForegroundColor Gray
Write-Host "5. Click 'Add webhook'" -ForegroundColor White

Write-Host "`n🧪 Testing Your Approval Workflow:" -ForegroundColor Magenta
Write-Host "1. Restart Atlantis with new configuration:" -ForegroundColor White
Write-Host "   docker-compose down && docker-compose up -d" -ForegroundColor Gray
Write-Host "2. Create a new branch:" -ForegroundColor White
Write-Host "   git checkout -b test-approval-workflow" -ForegroundColor Gray
Write-Host "3. Make a small change to terraform/terraform.tfvars:" -ForegroundColor White
Write-Host "   # Add a comment: # Testing approval workflow" -ForegroundColor Gray
Write-Host "4. Commit and push:" -ForegroundColor White
Write-Host "   git add . && git commit -m 'test: approval workflow'" -ForegroundColor Gray
Write-Host "   git push origin test-approval-workflow" -ForegroundColor Gray
Write-Host "5. Create a Pull Request" -ForegroundColor White
Write-Host "6. Watch Atlantis automatically comment with plan" -ForegroundColor White
Write-Host "7. Approve the PR" -ForegroundColor White
Write-Host "8. Comment 'atlantis apply' to execute" -ForegroundColor White

Write-Host "`n📊 Monitoring and Verification:" -ForegroundColor Magenta
Write-Host "• Atlantis UI: $ngrokUrl" -ForegroundColor White
Write-Host "• Atlantis Logs: docker-compose logs atlantis" -ForegroundColor White
Write-Host "• AWS Health: aws sts get-caller-identity" -ForegroundColor White
Write-Host "• Test Policy Validation: policies/ directory contains security and cost controls" -ForegroundColor White

Write-Host "`n🎯 Workshop Success Criteria:" -ForegroundColor Magenta
Write-Host "✅ GitHub integration working" -ForegroundColor Green
Write-Host "✅ Automatic plan generation on PR" -ForegroundColor Green
Write-Host "✅ Approval required before apply" -ForegroundColor Green
Write-Host "✅ Policy validation enforced" -ForegroundColor Green
Write-Host "✅ Complete audit trail in GitHub" -ForegroundColor Green

Write-Host "`n🚀 Next Steps for Workshop Completion:" -ForegroundColor Magenta
Write-Host "Phase 2: Implement Cost Controls (Infracost integration)" -ForegroundColor Yellow
Write-Host "Phase 3: Add Monitoring & Alerting" -ForegroundColor Yellow
Write-Host "Phase 4: Implement Compliance Validation" -ForegroundColor Yellow
Write-Host "Phase 5: Create Rollback Procedures" -ForegroundColor Yellow

Write-Host "`n✅ Enhanced Approval Workflow Setup Complete!" -ForegroundColor Green
Write-Host "🔄 Run the test scenario above to validate your implementation." -ForegroundColor Cyan
