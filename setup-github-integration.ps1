# GitHub Atlantis Integration Setup Script
# Run this script to configure Atlantis with GitHub using environment variables

Write-Host "🚀 Setting up GitHub Atlantis Integration with Environment Variables..." -ForegroundColor Green

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

# Check if .env already exists
if (Test-Path ".env") {
    $overwrite = Get-UserInput "⚠️  .env file already exists. Overwrite? (y/N)" "N"
    if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
        Write-Host "✅ Using existing .env file" -ForegroundColor Green
        exit 0
    }
}

# Collect GitHub credentials
$githubUser = Get-UserInput "Enter your GitHub username" "Bright-04"
$githubToken = Get-UserInput "Enter your GitHub Personal Access Token"
$repoName = Get-UserInput "Enter your repository name" "terraform-atlantis-workshop"
$webhookSecret = Get-UserInput "Enter your GitHub webhook secret (or leave blank to generate)"

if ([string]::IsNullOrEmpty($webhookSecret)) {
    # Generate a secure webhook secret
    $webhookSecret = [System.Web.Security.Membership]::GeneratePassword(32, 8)
    Write-Host "Generated webhook secret: $webhookSecret" -ForegroundColor Cyan
}

$ngrokUrl = Get-UserInput "Enter your ngrok URL (e.g., https://abc123.ngrok-free.app)"

# Create environment file
$envContent = @"
# GitHub Integration Configuration
# This file is ignored by git and won't be committed

# GitHub Configuration
ATLANTIS_GH_USER=$githubUser
ATLANTIS_GH_TOKEN=$githubToken
ATLANTIS_GH_WEBHOOK_SECRET=$webhookSecret

# Repository Configuration
ATLANTIS_REPO_ALLOWLIST=github.com/$githubUser/$repoName

# Atlantis URL Configuration
ATLANTIS_ATLANTIS_URL=$ngrokUrl

# Optional: Environment-specific variables
ATLANTIS_LOG_LEVEL=info
ATLANTIS_DEFAULT_TF_VERSION=v1.6.0
"@

$envContent | Out-File -FilePath ".env" -Encoding utf8
Write-Host "✅ Created .env file with GitHub configuration" -ForegroundColor Green

# Instructions for GitHub webhook setup
Write-Host "`n🔧 Next steps for GitHub webhook setup:" -ForegroundColor Magenta
Write-Host "1. Go to your GitHub repository settings" -ForegroundColor White
Write-Host "2. Navigate to Settings → Webhooks" -ForegroundColor White
Write-Host "3. Click 'Add webhook'" -ForegroundColor White
Write-Host "4. Configure the webhook:" -ForegroundColor White
Write-Host "   - Payload URL: $ngrokUrl/events" -ForegroundColor Gray
Write-Host "   - Content type: application/json" -ForegroundColor Gray
Write-Host "   - Secret: $webhookSecret" -ForegroundColor Gray
Write-Host "   - Events: Pull requests, Pull request reviews, Push, Issue comments" -ForegroundColor Gray
Write-Host "5. Click 'Add webhook'" -ForegroundColor White

Write-Host "`n🌐 To expose Atlantis locally for testing:" -ForegroundColor Magenta
Write-Host "1. Install ngrok: https://ngrok.com/download" -ForegroundColor White
Write-Host "2. Run: ngrok http 4141" -ForegroundColor White
Write-Host "3. Use the ngrok URL as your webhook endpoint" -ForegroundColor White

Write-Host "`n🔄 To restart Atlantis with new configuration:" -ForegroundColor Magenta
Write-Host "docker-compose down && docker-compose up -d" -ForegroundColor White

Write-Host "`n✅ Setup complete! Check the .env file for your configuration." -ForegroundColor Green
