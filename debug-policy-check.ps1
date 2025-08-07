# Debug Policy Check Script
# Comprehensive analysis of why Atlantis still gets "unable to unmarshal conftest output"

Write-Host "=== Debugging Policy Check Issues ===" -ForegroundColor Green

# 1. Check Conftest version
Write-Host "`n1. Checking Conftest version..." -ForegroundColor Yellow
$version = docker exec atlantis_workshop conftest --version
Write-Host "Conftest version: $version" -ForegroundColor Cyan

# 2. Check policy files
Write-Host "`n2. Checking policy files in container..." -ForegroundColor Yellow
$policies = docker exec atlantis_workshop ls -la /policies/
Write-Host "Policies found:" -ForegroundColor Cyan
Write-Host $policies

# 3. Check policy files from terraform directory
Write-Host "`n3. Checking policy files from terraform directory..." -ForegroundColor Yellow
$policiesFromTerraform = docker exec atlantis_workshop sh -c "cd /terraform && ls -la ../policies/"
Write-Host "Policies from terraform directory:" -ForegroundColor Cyan
Write-Host $policiesFromTerraform

# 4. Copy test plan and test cost policies
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

# 6. Test without namespace (all policies)
Write-Host "`n6. Testing all policies without namespace..." -ForegroundColor Yellow
$allResult = docker exec atlantis_workshop sh -c "cd /terraform && conftest test --policy ../policies/ test-plan.json -o json"
Write-Host "All policies result:" -ForegroundColor Cyan
Write-Host $allResult

# 7. Check Atlantis environment variables
Write-Host "`n7. Checking Atlantis environment variables..." -ForegroundColor Yellow
$envVars = docker exec atlantis_workshop env | findstr -i "conftest\|policy"
Write-Host "Relevant environment variables:" -ForegroundColor Cyan
Write-Host $envVars

# 8. Check Atlantis logs for recent policy check attempts
Write-Host "`n8. Checking recent Atlantis logs..." -ForegroundColor Yellow
$recentLogs = docker logs atlantis_workshop --tail 20
Write-Host "Recent logs:" -ForegroundColor Cyan
Write-Host $recentLogs

# 9. Test JSON validity
Write-Host "`n9. Testing JSON validity..." -ForegroundColor Yellow
$jsonTest = docker exec atlantis_workshop sh -c "cd /terraform && conftest test --policy ../policies/ test-plan.json --namespace terraform.cost -o json | head -c 1000"
Write-Host "JSON output sample:" -ForegroundColor Cyan
Write-Host $jsonTest

# 10. Check if there are any syntax errors in policies
Write-Host "`n10. Checking policy syntax..." -ForegroundColor Yellow
$syntaxCheck = docker exec atlantis_workshop sh -c "cd /terraform && conftest test --policy ../policies/ test-plan.json --namespace terraform.cost --no-fail"
Write-Host "Syntax check result:" -ForegroundColor Cyan
Write-Host $syntaxCheck

Write-Host "`n=== Analysis Complete ===" -ForegroundColor Green
Write-Host "Check the output above for any errors or inconsistencies." -ForegroundColor Yellow
