# =============================================================================
# 01 - Environment Setup Validation Script
# =============================================================================
# This script validates the environment setup for the Terraform Atlantis Workshop
# 
# Workflow Order:
# 1. 01-validate-environment.ps1 (this script)
# 2. 02-setup-github-actions.ps1
# 3. 03-deploy-infrastructure.ps1
# 4. 04-health-monitoring.ps1
# 5. 05-cost-monitoring.ps1
# 6. 06-rollback-procedures.ps1
# 7. 07-cleanup-infrastructure.ps1
# =============================================================================

Write-Host "Step 1: Validating Environment Setup..." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Gray

$errors = @()
$warnings = @()

# Check .env file
if (-not (Test-Path ".env")) {
    $errors += ".env file not found"
} else {
    Write-Host "Environment file found" -ForegroundColor Green
}

# Check GitHub Actions workflow
if (Test-Path ".github/workflows/terraform.yml") {
    Write-Host "GitHub Actions workflow found" -ForegroundColor Green
} else {
    $warnings += "GitHub Actions workflow file not found"
}

# Check AWS CLI
try {
    $awsVersion = aws --version 2>$null
    if ($awsVersion) {
        Write-Host "AWS CLI installed" -ForegroundColor Green
    } else {
        $errors += "AWS CLI not found"
    }
} catch {
    $errors += "AWS CLI not installed"
}

# Check Terraform
try {
    $tfVersion = terraform --version 2>$null
    if ($tfVersion) {
        Write-Host "Terraform installed" -ForegroundColor Green
    } else {
        $errors += "Terraform not found"
    }
} catch {
    $errors += "Terraform not installed"
}

# Display results
if ($errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "   • $err" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`nWarnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   • $warning" -ForegroundColor Yellow
    }
}

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "`nEnvironment setup is valid!" -ForegroundColor Green
    Write-Host "`nNext Step: Run 02-setup-github-actions.ps1" -ForegroundColor Cyan
} else {
    Write-Host "`nFix the issues above, then run 02-setup-github-actions.ps1" -ForegroundColor Yellow
}
