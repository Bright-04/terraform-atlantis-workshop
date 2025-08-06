# Test Server-Side Configuration for Custom Workflows
Write-Host "🔧 Testing Server-Side Configuration..." -ForegroundColor Green

# Check if containers are running
Write-Host "`n📦 Checking container status..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Verify server-side configuration is mounted
Write-Host "`n🔍 Verifying server-side configuration..." -ForegroundColor Yellow
$serverConfig = docker exec atlantis_workshop cat /etc/atlantis/repos.yaml
if ($serverConfig -like "*allow_custom_workflows: true*") {
    Write-Host "✅ Server-side configuration is mounted and contains allow_custom_workflows: true" -ForegroundColor Green
} else {
    Write-Host "❌ Server-side configuration not found or incorrect" -ForegroundColor Red
}

# Verify environment variable is still set
Write-Host "`n🔍 Verifying ATLANTIS_ALLOW_CUSTOM_WORKFLOWS..." -ForegroundColor Yellow
$customWorkflows = docker exec atlantis_workshop printenv | findstr ATLANTIS_ALLOW_CUSTOM_WORKFLOWS
if ($customWorkflows -like "*=true*") {
    Write-Host "✅ ATLANTIS_ALLOW_CUSTOM_WORKFLOWS=true is set" -ForegroundColor Green
} else {
    Write-Host "❌ ATLANTIS_ALLOW_CUSTOM_WORKFLOWS not set correctly" -ForegroundColor Red
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

# Display current configurations
Write-Host "`n📋 Server-side configuration:" -ForegroundColor Yellow
docker exec atlantis_workshop cat /etc/atlantis/repos.yaml | ForEach-Object { Write-Host "  $_" }

Write-Host "`n📋 Repository atlantis.yaml configuration:" -ForegroundColor Yellow
Get-Content atlantis.yaml | ForEach-Object { Write-Host "  $_" }

Write-Host "`n✅ Server-side configuration test completed!" -ForegroundColor Green
Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to your GitHub PR" -ForegroundColor White
Write-Host "2. Comment: atlantis plan" -ForegroundColor White
Write-Host "3. The custom workflow error should now be resolved with server-side config" -ForegroundColor White
Write-Host "4. Atlantis should successfully parse your atlantis.yaml" -ForegroundColor White 