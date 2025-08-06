# Test Custom Workflow Configuration
Write-Host "🔧 Testing Custom Workflow Configuration..." -ForegroundColor Green

# Check if containers are running
Write-Host "`n📦 Checking container status..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Verify environment variable is set
Write-Host "`n🔍 Verifying ATLANTIS_ALLOW_CUSTOM_WORKFLOWS..." -ForegroundColor Yellow
$customWorkflows = docker exec atlantis_workshop printenv | findstr ATLANTIS_ALLOW_CUSTOM_WORKFLOWS
if ($customWorkflows -like "*=true*") {
    Write-Host "✅ ATLANTIS_ALLOW_CUSTOM_WORKFLOWS=true is set" -ForegroundColor Green
} else {
    Write-Host "❌ ATLANTIS_ALLOW_CUSTOM_WORKFLOWS not set correctly" -ForegroundColor Red
    Write-Host "Current value: $customWorkflows" -ForegroundColor Red
}

# Check Atlantis logs for any configuration errors
Write-Host "`n📋 Checking Atlantis logs for configuration errors..." -ForegroundColor Yellow
$atlantisLogs = docker logs atlantis_workshop 2>&1 | Select-String -Pattern "error|Error|ERROR|parsing|config|custom.*workflow" -Context 2

if ($atlantisLogs) {
    Write-Host "❌ Configuration errors found:" -ForegroundColor Red
    $atlantisLogs | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
} else {
    Write-Host "✅ No configuration errors found in logs" -ForegroundColor Green
}

# Display current atlantis.yaml configuration
Write-Host "`n📋 Current atlantis.yaml configuration:" -ForegroundColor Yellow
Get-Content atlantis.yaml | ForEach-Object { Write-Host "  $_" }

Write-Host "`n✅ Custom workflow test completed!" -ForegroundColor Green
Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to your GitHub PR" -ForegroundColor White
Write-Host "2. Comment: atlantis plan" -ForegroundColor White
Write-Host "3. The custom workflow error should now be resolved" -ForegroundColor White
Write-Host "4. Atlantis should successfully parse your atlantis.yaml" -ForegroundColor White 