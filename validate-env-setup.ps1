# Environment Setup Validation Script
Write-Host "🔍 Validating Environment Setup..." -ForegroundColor Green

$errors = @()
$warnings = @()

# Check .env file
if (-not (Test-Path ".env")) {
    $errors += ".env file not found"
} else {
    $envContent = Get-Content ".env" -Raw
    
    # Check required variables
    $requiredVars = @("ATLANTIS_GH_USER", "ATLANTIS_GH_TOKEN", "ATLANTIS_REPO_ALLOWLIST", "ATLANTIS_ATLANTIS_URL", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY")
    
    # Check if using GitHub Actions
    $usingGitHubActions = $envContent -match "ATLANTIS_ATLANTIS_URL=github-actions"
    
    foreach ($var in $requiredVars) {
        if ($envContent -match "$var=") {
            $value = ($envContent -split "`n" | Where-Object { $_ -match "^$var=" } | ForEach-Object { ($_ -split "=", 2)[1] }).Trim()
            if ([string]::IsNullOrEmpty($value) -or $value -like "*your-*") {
                $warnings += "$var needs actual value"
            }
        } else {
            $errors += "Missing $var"
        }
    }
    
    # Check repository format
    if ($envContent -match "ATLANTIS_REPO_ALLOWLIST=github\.com/[^/]+/[^/]+") {
        Write-Host "✅ Repository format correct" -ForegroundColor Green
    } else {
        $errors += "Invalid repository allowlist format"
    }
    
    # Check GitHub Actions configuration
    if ($usingGitHubActions) {
        Write-Host "✅ Using GitHub Actions for deployment" -ForegroundColor Green
        
        # Check if GitHub Actions workflow exists
        if (Test-Path ".github/workflows/terraform.yml") {
            Write-Host "✅ GitHub Actions workflow found" -ForegroundColor Green
        } else {
            $warnings += "GitHub Actions workflow file not found (.github/workflows/terraform.yml)"
        }
    } else {
        Write-Host "⚠️  Using external Atlantis hosting" -ForegroundColor Yellow
        if ($envContent -match "ATLANTIS_ATLANTIS_URL=https?://") {
            Write-Host "✅ Atlantis URL format correct" -ForegroundColor Green
        } else {
            $warnings += "Atlantis URL may not be properly configured"
        }
    }
}

# Display results
if ($errors.Count -gt 0) {
    Write-Host "`n❌ Errors:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "   • $error" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   • $warning" -ForegroundColor Yellow
    }
}

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "`n✅ Environment setup is valid!" -ForegroundColor Green
} else {
    Write-Host "`n🔧 Run setup-github-actions.ps1 to fix issues" -ForegroundColor Yellow
}
