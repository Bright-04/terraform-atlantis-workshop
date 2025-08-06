# Test Policy Fix - Verify Conftest is Working
Write-Host "🔧 Testing Policy Fix..." -ForegroundColor Green

# Check if containers are running
Write-Host "`n📦 Checking container status..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test conftest with cost policies
Write-Host "`n💰 Testing Cost Policies..." -ForegroundColor Yellow
$costResult = docker exec atlantis_workshop conftest test --policy policies/ /test-plan.json --namespace terraform.cost
Write-Host "Cost Policy Results:" -ForegroundColor Cyan
$costResult | ForEach-Object { Write-Host "  $_" }

# Test conftest with security policies
Write-Host "`n🔒 Testing Security Policies..." -ForegroundColor Yellow
$securityResult = docker exec atlantis_workshop conftest test --policy policies/ /test-plan.json --namespace terraform.security
Write-Host "Security Policy Results:" -ForegroundColor Cyan
$securityResult | ForEach-Object { Write-Host "  $_" }

# Test conftest with all namespaces
Write-Host "`n🎯 Testing All Policies..." -ForegroundColor Yellow
$allResult = docker exec atlantis_workshop conftest test --policy policies/ /test-plan.json --all-namespaces
Write-Host "All Policy Results:" -ForegroundColor Cyan
$allResult | ForEach-Object { Write-Host "  $_" }

# Check Atlantis logs for policy check errors
Write-Host "`n📋 Checking Atlantis logs for policy errors..." -ForegroundColor Yellow
$atlantisLogs = docker logs atlantis_workshop 2>&1 | Select-String -Pattern "policy|conftest|unmarshal" -Context 2

if ($atlantisLogs) {
    Write-Host "❌ Policy errors found in logs:" -ForegroundColor Red
    $atlantisLogs | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
} else {
    Write-Host "✅ No policy errors found in logs" -ForegroundColor Green
}

Write-Host "`n✅ Policy fix test completed!" -ForegroundColor Green
Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to your GitHub PR" -ForegroundColor White
Write-Host "2. Comment: atlantis plan" -ForegroundColor White
Write-Host "3. Policy checks should now work without 'unmarshal' errors!" -ForegroundColor White
Write-Host "4. You should see policy violations in the output" -ForegroundColor White 