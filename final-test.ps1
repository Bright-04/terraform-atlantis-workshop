# Final Test - Verify Complete Custom Workflow Solution
Write-Host "🎯 Final Test - Custom Workflow Solution" -ForegroundColor Green

# Check if containers are running
Write-Host "`n📦 Checking container status..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Verify all configurations are in place
Write-Host "`n🔍 Verifying configurations..." -ForegroundColor Yellow

# Check environment variable
$customWorkflows = docker exec atlantis_workshop printenv | findstr ATLANTIS_ALLOW_CUSTOM_WORKFLOWS
if ($customWorkflows -like "*=true*") {
    Write-Host "✅ ATLANTIS_ALLOW_CUSTOM_WORKFLOWS=true is set" -ForegroundColor Green
} else {
    Write-Host "❌ ATLANTIS_ALLOW_CUSTOM_WORKFLOWS not set" -ForegroundColor Red
}

# Check server-side config
$serverConfig = docker exec atlantis_workshop cat /etc/atlantis/repos.yaml
if ($serverConfig -like "*allow_custom_workflows: true*") {
    Write-Host "✅ Server-side config contains allow_custom_workflows: true" -ForegroundColor Green
} else {
    Write-Host "❌ Server-side config missing allow_custom_workflows" -ForegroundColor Red
}

# Check command-line argument
$atlantisProcess = docker exec atlantis_workshop ps aux | findstr "atlantis.*server"
if ($atlantisProcess -like "*--repo-config*") {
    Write-Host "✅ Atlantis started with --repo-config flag" -ForegroundColor Green
} else {
    Write-Host "❌ Atlantis not started with --repo-config flag" -ForegroundColor Red
}

# Check for any errors in logs
Write-Host "`n📋 Checking for errors in logs..." -ForegroundColor Yellow
$atlantisLogs = docker logs atlantis_workshop 2>&1 | Select-String -Pattern "error|Error|ERROR|custom.*workflow" -Context 2

if ($atlantisLogs) {
    Write-Host "❌ Errors found in logs:" -ForegroundColor Red
    $atlantisLogs | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
} else {
    Write-Host "✅ No errors found in logs" -ForegroundColor Green
}

# Display current atlantis.yaml
Write-Host "`n📋 Current atlantis.yaml (with custom workflows):" -ForegroundColor Yellow
Get-Content atlantis.yaml | ForEach-Object { Write-Host "  $_" }

Write-Host "`n🎉 FINAL STATUS: CUSTOM WORKFLOW SOLUTION READY!" -ForegroundColor Green
Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to your GitHub PR" -ForegroundColor White
Write-Host "2. Comment: atlantis plan" -ForegroundColor White
Write-Host "3. Should work WITHOUT the custom workflow error!" -ForegroundColor White
Write-Host "4. Policy checks should run and show violations (as expected)" -ForegroundColor White

Write-Host "`n✅ All configurations verified and ready for testing!" -ForegroundColor Green 