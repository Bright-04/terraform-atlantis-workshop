# Environment Setup Validation Script
Write-Host "Validating Environment Setup..." -ForegroundColor Green

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

# Display results
if ($errors.Count -gt 0) {
    Write-Host "Errors:" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "   • $err" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "Warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   • $warning" -ForegroundColor Yellow
    }
}

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "Environment setup is valid!" -ForegroundColor Green
} else {
    Write-Host "Run setup-github-actions.ps1 to fix issues" -ForegroundColor Yellow
}
