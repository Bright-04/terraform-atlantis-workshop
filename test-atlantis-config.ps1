# Test Atlantis Configuration
Write-Host "🔧 Testing Atlantis Configuration..." -ForegroundColor Green

# Check if containers are running
Write-Host "`n📦 Checking container status..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test Atlantis configuration parsing
Write-Host "`n🔍 Testing atlantis.yaml configuration..." -ForegroundColor Yellow

# Check if Atlantis can parse the configuration
$atlantisLogs = docker logs atlantis_workshop 2>&1 | Select-String -Pattern "error|Error|ERROR|parsing|config" -Context 2

if ($atlantisLogs) {
    Write-Host "❌ Configuration errors found:" -ForegroundColor Red
    $atlantisLogs | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
} else {
    Write-Host "✅ No configuration errors found in logs" -ForegroundColor Green
}

# Check if Atlantis is listening on port 4141
Write-Host "`n🌐 Testing Atlantis web interface..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:4141" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Atlantis web interface is accessible" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Atlantis web interface test failed (this might be normal for webhook-only setup)" -ForegroundColor Yellow
}

# Display current configuration
Write-Host "`n📋 Current atlantis.yaml configuration:" -ForegroundColor Yellow
Get-Content atlantis.yaml | ForEach-Object { Write-Host "  $_" }

Write-Host "`n✅ Configuration test completed!" -ForegroundColor Green
Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to your GitHub PR" -ForegroundColor White
Write-Host "2. Comment: atlantis plan" -ForegroundColor White
Write-Host "3. Atlantis should now work without the custom workflow error" -ForegroundColor White 