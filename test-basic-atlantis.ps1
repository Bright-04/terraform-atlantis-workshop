# Test Basic Atlantis Functionality (without custom workflows)
Write-Host "🔧 Testing Basic Atlantis Functionality..." -ForegroundColor Green

# Check if containers are running
Write-Host "`n📦 Checking container status..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check Atlantis logs for any errors
Write-Host "`n📋 Checking Atlantis logs for errors..." -ForegroundColor Yellow
$atlantisLogs = docker logs atlantis_workshop 2>&1 | Select-String -Pattern "error|Error|ERROR" -Context 2

if ($atlantisLogs) {
    Write-Host "❌ Errors found in logs:" -ForegroundColor Red
    $atlantisLogs | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
} else {
    Write-Host "✅ No errors found in logs" -ForegroundColor Green
}

# Display current atlantis.yaml configuration
Write-Host "`n📋 Current atlantis.yaml configuration:" -ForegroundColor Yellow
Get-Content atlantis.yaml | ForEach-Object { Write-Host "  $_" }

Write-Host "`n✅ Basic Atlantis test completed!" -ForegroundColor Green
Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to your GitHub PR" -ForegroundColor White
Write-Host "2. Comment: atlantis plan" -ForegroundColor White
Write-Host "3. This should work without custom workflow errors" -ForegroundColor White
Write-Host "4. If this works, we can add custom workflows back" -ForegroundColor White 