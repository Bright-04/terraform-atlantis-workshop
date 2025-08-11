# Security Fix Script for Terraform Atlantis Workshop
# This script helps fix security issues found in the codebase

Write-Host "🔒 Security Fix Script for Terraform Atlantis Workshop" -ForegroundColor Red
Write-Host "=====================================================" -ForegroundColor Gray

Write-Host "`n🚨 CRITICAL SECURITY ISSUES DETECTED:" -ForegroundColor Red
Write-Host "=====================================" -ForegroundColor Red

Write-Host "1. AWS Credentials exposed in .env file" -ForegroundColor Yellow
Write-Host "2. GitHub Token exposed in .env file" -ForegroundColor Yellow
Write-Host "3. Credentials should be stored as secrets, not in plain text" -ForegroundColor Yellow

Write-Host "`n📋 Recommended Actions:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

Write-Host "1. IMMEDIATELY rotate your AWS credentials:" -ForegroundColor White
Write-Host "   - Go to AWS IAM Console" -ForegroundColor Gray
Write-Host "   - Deactivate the exposed access key" -ForegroundColor Gray
Write-Host "   - Create a new access key" -ForegroundColor Gray
Write-Host "   - Update your AWS configuration" -ForegroundColor Gray

Write-Host "`n2. Rotate your GitHub token:" -ForegroundColor White
Write-Host "   - Go to GitHub Settings > Developer settings > Personal access tokens" -ForegroundColor Gray
Write-Host "   - Revoke the exposed token" -ForegroundColor Gray
Write-Host "   - Generate a new token" -ForegroundColor Gray

Write-Host "`n3. Use environment variables instead of .env file:" -ForegroundColor White
Write-Host "   - Set AWS_ACCESS_KEY_ID as environment variable" -ForegroundColor Gray
Write-Host "   - Set AWS_SECRET_ACCESS_KEY as environment variable" -ForegroundColor Gray
Write-Host "   - Set AWS_DEFAULT_REGION as environment variable" -ForegroundColor Gray

Write-Host "`n4. For GitHub Actions, use repository secrets:" -ForegroundColor White
Write-Host "   - Go to your repository Settings > Secrets and variables > Actions" -ForegroundColor Gray
Write-Host "   - Add AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION" -ForegroundColor Gray

Write-Host "`n🔧 Creating secure .env template..." -ForegroundColor Yellow

# Create a secure .env template
$secureEnvContent = @"
# SECURE GitHub Integration Configuration
# DO NOT commit this file with real credentials
# Use environment variables or GitHub secrets instead

# GitHub Configuration (use GitHub secrets in production)
ATLANTIS_GH_USER=your-github-username
ATLANTIS_GH_TOKEN=your-github-personal-access-token
ATLANTIS_GH_WEBHOOK_SECRET=your-webhook-secret

# Repository Configuration
ATLANTIS_REPO_ALLOWLIST=github.com/your-username/terraform-atlantis-workshop

# Atlantis URL Configuration
ATLANTIS_ATLANTIS_URL=github-actions

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

# AWS Configuration (use environment variables or GitHub secrets)
# DO NOT put real credentials here
AWS_ACCESS_KEY_ID=your-aws-access-key-id
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
AWS_DEFAULT_REGION=ap-southeast-1
"@

# Backup current .env file
if (Test-Path ".env") {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item ".env" ".env.backup-$timestamp"
    Write-Host "   ✅ Current .env backed up to .env.backup-$timestamp" -ForegroundColor Green
}

# Create secure template
$secureEnvContent | Out-File -FilePath ".env.secure-template" -Encoding utf8
Write-Host "   ✅ Created .env.secure-template" -ForegroundColor Green

Write-Host "`n📝 Next Steps:" -ForegroundColor Cyan
Write-Host "=============" -ForegroundColor Cyan

Write-Host "1. Update .env file with placeholder values:" -ForegroundColor White
Write-Host "   Copy .env.secure-template to .env and update with your values" -ForegroundColor Gray

Write-Host "`n2. Set up GitHub Actions secrets:" -ForegroundColor White
Write-Host "   - Go to your repository Settings > Secrets and variables > Actions" -ForegroundColor Gray
Write-Host "   - Add the following secrets:" -ForegroundColor Gray
Write-Host "     * AWS_ACCESS_KEY_ID" -ForegroundColor Gray
Write-Host "     * AWS_SECRET_ACCESS_KEY" -ForegroundColor Gray
Write-Host "     * AWS_DEFAULT_REGION" -ForegroundColor Gray

Write-Host "`n3. For production deployment, use environment variables:" -ForegroundColor White
Write-Host "   `$env:AWS_ACCESS_KEY_ID = 'your-key'" -ForegroundColor Gray
Write-Host "   `$env:AWS_SECRET_ACCESS_KEY = 'your-secret'" -ForegroundColor Gray
Write-Host "   `$env:AWS_DEFAULT_REGION = 'ap-southeast-1'" -ForegroundColor Gray

Write-Host "`n4. Test your configuration:" -ForegroundColor White
Write-Host "   aws sts get-caller-identity" -ForegroundColor Gray

Write-Host "`n⚠️  IMPORTANT: Never commit real credentials to version control!" -ForegroundColor Red
Write-Host "   Use .gitignore to exclude .env files with real credentials" -ForegroundColor Yellow

Write-Host "`n✅ Security fix script completed!" -ForegroundColor Green
Write-Host "🔄 Please follow the steps above to secure your credentials" -ForegroundColor Cyan
