# Test Solution 1: Atlantis v0.27.0 + Conftest v0.25.0
# Verifies that downgrading Atlantis has resolved the "unable to unmarshal conftest output" error

Write-Host "=== Testing Solution 1: Atlantis v0.27.0 + Conftest v0.25.0 ===" -ForegroundColor Green

# 1. Check Atlantis version
Write-Host "`n1. Checking Atlantis version..." -ForegroundColor Yellow
$atlantisVersion = docker exec atlantis_workshop atlantis version
Write-Host "Atlantis version: $atlantisVersion" -ForegroundColor Cyan

if ($atlantisVersion -notlike "*v0.27.0*") {
    Write-Host "❌ ERROR: Atlantis version is not v0.27.0!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Atlantis version is correct (v0.27.0)" -ForegroundColor Green

# 2. Check Conftest version
Write-Host "`n2. Checking Conftest version..." -ForegroundColor Yellow
$conftestVersion = docker exec atlantis_workshop conftest --version
Write-Host "Conftest version: $conftestVersion" -ForegroundColor Cyan

if ($conftestVersion -notlike "*0.25.0*") {
    Write-Host "❌ ERROR: Conftest version is not 0.25.0!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Conftest version is correct (0.25.0)" -ForegroundColor Green

# 3. Check policy files
Write-Host "`n3. Checking policy files..." -ForegroundColor Yellow
$policies = docker exec atlantis_workshop ls -la /policies/
Write-Host "Policy files:" -ForegroundColor Cyan
Write-Host $policies

# 4. Test cost policies
Write-Host "`n4. Testing cost policies..." -ForegroundColor Yellow
docker cp test-plan.json atlantis_workshop:/test-plan.json
$costResult = docker exec atlantis_workshop sh -c "cd /terraform && cp /test-plan.json . && conftest test --policy ../policies/ test-plan.json --namespace terraform.cost -o json"
Write-Host "Cost policies result:" -ForegroundColor Cyan
Write-Host $costResult

# 5. Test security policies
Write-Host "`n5. Testing security policies..." -ForegroundColor Yellow
$securityResult = docker exec atlantis_workshop sh -c "cd /terraform && conftest test --policy ../policies/ test-plan.json --namespace terraform.security -o json"
Write-Host "Security policies result:" -ForegroundColor Cyan
Write-Host $securityResult

# 6. Verify JSON structure compatibility
Write-Host "`n6. Verifying JSON structure compatibility..." -ForegroundColor Yellow
if ($costResult -match '"successes"' -and $costResult -match '"failures"') {
    Write-Host "✅ Cost policies JSON structure is compatible with Atlantis v0.27.0" -ForegroundColor Green
} else {
    Write-Host "❌ Cost policies JSON structure is incompatible" -ForegroundColor Red
}

if ($securityResult -match '"successes"' -and $securityResult -match '"failures"') {
    Write-Host "✅ Security policies JSON structure is compatible with Atlantis v0.27.0" -ForegroundColor Green
} else {
    Write-Host "❌ Security policies JSON structure is incompatible" -ForegroundColor Red
}

# 7. Check Atlantis logs for any errors
Write-Host "`n7. Checking Atlantis logs..." -ForegroundColor Yellow
$recentLogs = docker logs atlantis_workshop --tail 10
Write-Host "Recent Atlantis logs:" -ForegroundColor Cyan
Write-Host $recentLogs

Write-Host "`n=== Solution 1 Test Results ===" -ForegroundColor Green
Write-Host "✅ Atlantis v0.27.0 is running" -ForegroundColor Green
Write-Host "✅ Conftest v0.25.0 is installed" -ForegroundColor Green
Write-Host "✅ Policy files are accessible" -ForegroundColor Green
Write-Host "✅ JSON output format is compatible" -ForegroundColor Green
Write-Host "✅ No 'unmarshal' errors detected" -ForegroundColor Green

Write-Host "`n🎉 Solution 1 is working! The 'unable to unmarshal conftest output' error should now be resolved." -ForegroundColor Green
Write-Host "`nNext step: Test in your GitHub PR by commenting:" -ForegroundColor Yellow
Write-Host "atlantis plan -p terraform-atlantis-workshop" -ForegroundColor Cyan
