# Environment Variable Setup Guide

## Overview
This guide explains how to set up environment variables for the Terraform Atlantis Workshop to keep sensitive information secure.

## Why Environment Variables?
- **Security**: Keeps tokens, secrets, and URLs out of your repository
- **Flexibility**: Easy to update without changing code
- **Team Collaboration**: Each team member can use their own values

## Quick Setup

### Option 1: Use the Setup Script (Recommended)
```powershell
# Run the interactive setup script
.\setup-github-integration.ps1
```

### Option 2: Manual Setup
1. Copy the example environment file:
   ```powershell
   Copy-Item .env.example .env
   ```

2. Edit `.env` with your actual values:
   ```bash
   # GitHub Configuration
   ATLANTIS_GH_USER=your-github-username
   ATLANTIS_GH_TOKEN=your-github-personal-access-token
   ATLANTIS_GH_WEBHOOK_SECRET=your-webhook-secret
   
   # Repository Configuration
   ATLANTIS_REPO_ALLOWLIST=github.com/your-username/terraform-atlantis-workshop
   
   # Atlantis URL Configuration
   ATLANTIS_ATLANTIS_URL=https://your-ngrok-url.ngrok-free.app
   ```

## Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `ATLANTIS_GH_USER` | Your GitHub username | `Bright-04` |
| `ATLANTIS_GH_TOKEN` | GitHub Personal Access Token | `ghp_xxxxx` |
| `ATLANTIS_GH_WEBHOOK_SECRET` | Webhook secret for GitHub | `my-secret-key` |
| `ATLANTIS_REPO_ALLOWLIST` | Repository whitelist | `github.com/user/repo` |
| `ATLANTIS_ATLANTIS_URL` | Public URL for Atlantis | `https://abc123.ngrok-free.app` |

## Getting Your Values

### GitHub Personal Access Token
1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Generate a new token with these scopes:
   - `repo` (Full control of private repositories)
   - `write:repo_hook` (Write repository hooks)

### Webhook Secret
- Generate a secure random string
- Use the same value in both `.env` and GitHub webhook settings

### ngrok URL
1. Install ngrok: https://ngrok.com/download
2. Run: `ngrok http 4141`
3. Copy the HTTPS URL (e.g., `https://abc123.ngrok-free.app`)

## Security Notes

- ✅ The `.env` file is already in `.gitignore`
- ✅ Never commit `.env` files to version control
- ✅ Use different secrets for different environments
- ✅ Regenerate tokens periodically
- ❌ Don't share your `.env` file with others
- ❌ Don't paste tokens in chat or documentation

## Usage

After setting up your `.env` file:

1. Restart your Docker containers:
   ```powershell
   docker-compose down
   docker-compose up -d
   ```

2. Your Atlantis instance will now use the environment variables

## Troubleshooting

### Common Issues
1. **"Variable not found"** - Make sure your `.env` file exists and has the correct format
2. **"Webhook delivery failed"** - Check your ngrok URL is current and accessible
3. **"Authentication failed"** - Verify your GitHub token has the correct permissions

### Testing Your Setup
```powershell
# Check if environment variables are loaded
docker-compose config

# Check Atlantis logs
docker-compose logs atlantis
```

## Next Steps
After setting up environment variables:
1. Configure your GitHub webhook
2. Test with a pull request
3. Verify Atlantis responds to commands
