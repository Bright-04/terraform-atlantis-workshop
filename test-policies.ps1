# Policy Testing Script for Terraform Atlantis Workshop
# This script tests OPA/Conftest policies against Terraform plans

Write-Host "🔍 Testing Terraform Policies with Conftest..." -ForegroundColor Green

# Check if conftest is installed
try {
    $conftestVersion = conftest --version 2>$null
    Write-Host "✅ Conftest is installed: $conftestVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Conftest not found. Installing Conftest..." -ForegroundColor Yellow
    
    # Download and install conftest for Windows
    $downloadUrl = "https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Windows_x86_64.zip"
    $zipPath = "$env:TEMP\conftest.zip"
    $extractPath = "$env:TEMP\conftest"
    
    Write-Host "📦 Downloading Conftest..." -ForegroundColor Blue
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
    
    Write-Host "📂 Extracting Conftest..." -ForegroundColor Blue
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    
    # Move to a permanent location
    $conftestDir = "C:\tools\conftest"
    if (-not (Test-Path $conftestDir)) {
        New-Item -ItemType Directory -Path $conftestDir -Force
    }
    Copy-Item "$extractPath\conftest.exe" "$conftestDir\conftest.exe" -Force
    
    # Add to PATH for current session
    $env:PATH += ";$conftestDir"
    
    Write-Host "✅ Conftest installed successfully!" -ForegroundColor Green
    Write-Host "💡 Add C:\tools\conftest to your system PATH for permanent access" -ForegroundColor Yellow
}

# Navigate to terraform directory
Set-Location "terraform"

Write-Host "`n🏗️ Generating Terraform plan for policy testing..." -ForegroundColor Blue

# Initialize and plan
terraform init -upgrade > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform init failed!" -ForegroundColor Red
    exit 1
}

# Generate plan in JSON format for policy testing
terraform plan -out=tfplan.binary > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform plan failed!" -ForegroundColor Red
    exit 1
}

terraform show -json tfplan.binary > tfplan.json
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to convert plan to JSON!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Terraform plan generated successfully!" -ForegroundColor Green

Write-Host "`n🔍 Testing Security Policies..." -ForegroundColor Magenta
try {
    conftest test --policy ..\policies\terraform_security.rego tfplan.json
    Write-Host "✅ Security policy test completed!" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Security policy test had issues - check output above" -ForegroundColor Yellow
}

Write-Host "`n💰 Testing Cost Control Policies..." -ForegroundColor Magenta
try {
    conftest test --policy ..\policies\cost_control.rego tfplan.json
    Write-Host "✅ Cost control policy test completed!" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Cost control policy test had issues - check output above" -ForegroundColor Yellow
}

Write-Host "`n🔧 Testing All Policies Together..." -ForegroundColor Magenta
try {
    conftest test --policy ..\policies\ tfplan.json
    Write-Host "✅ All policy tests completed!" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Some policy tests failed - check output above" -ForegroundColor Yellow
}

# Clean up
Remove-Item tfplan.binary -ErrorAction SilentlyContinue
Remove-Item tfplan.json -ErrorAction SilentlyContinue

Write-Host "`n✨ Policy testing complete!" -ForegroundColor Green
Write-Host "💡 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review policy test results above" -ForegroundColor White
Write-Host "  2. Create a test branch with policy violations" -ForegroundColor White
Write-Host "  3. Open a PR to test Atlantis policy enforcement" -ForegroundColor White

Set-Location ".."
