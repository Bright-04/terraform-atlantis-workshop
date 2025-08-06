#!/usr/bin/env pwsh
# Health Check Script for Terraform Atlantis Workshop
# Monitors LocalStack and infrastructure health

Write-Host "🔍 Terraform Atlantis Workshop - Health Check" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Gray

# Function to check service health
function Test-ServiceHealth {
    param([string]$ServiceName, [string]$Url, [string]$ExpectedContent = "")
    
    try {
        Write-Host "Checking $ServiceName..." -NoNewline
        $response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 10
        
        if ($ExpectedContent -and $response -notlike "*$ExpectedContent*") {
            Write-Host " ❌ UNHEALTHY" -ForegroundColor Red
            return $false
        }
        
        Write-Host " ✅ HEALTHY" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " ❌ UNHEALTHY - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Check Docker services
Write-Host "`n📦 Docker Services Status:" -ForegroundColor Yellow
$dockerServices = docker-compose ps --format "table {{.Name}}\t{{.Status}}"
Write-Host $dockerServices

# Check LocalStack health
Write-Host "`n🏥 LocalStack Health Check:" -ForegroundColor Yellow
$localstackHealthy = Test-ServiceHealth "LocalStack" "http://localhost:4566/_localstack/health"

if ($localstackHealthy) {
    try {
        $healthData = Invoke-RestMethod -Uri "http://localhost:4566/_localstack/health" -Method Get
        Write-Host "   Available Services:" -ForegroundColor Gray
        $healthData.services.PSObject.Properties | ForEach-Object {
            $status = if ($_.Value -eq "available") { "✅" } else { "❌" }
            Write-Host "   - $($_.Name): $status $($_.Value)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "   Could not retrieve detailed health info" -ForegroundColor Yellow
    }
}

# Check Atlantis health
Write-Host "`n🌊 Atlantis Health Check:" -ForegroundColor Yellow
$atlantisHealthy = Test-ServiceHealth "Atlantis" "http://localhost:4141" 

# Check infrastructure status
Write-Host "`n🏗️ Infrastructure Status:" -ForegroundColor Yellow
if (Test-Path "terraform\terraform.tfstate") {
    try {
        Set-Location terraform
        $terraformOutput = terraform output -json 2>$null | ConvertFrom-Json
        
        if ($terraformOutput) {
            Write-Host "   Deployed Resources:" -ForegroundColor Gray
            $terraformOutput.PSObject.Properties | ForEach-Object {
                Write-Host "   - $($_.Name): $($_.Value.value)" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "   No infrastructure deployed" -ForegroundColor Yellow
        }
        Set-Location ..
    }
    catch {
        Write-Host "   Could not read infrastructure status" -ForegroundColor Red
        Set-Location ..
    }
}
else {
    Write-Host "   No Terraform state found" -ForegroundColor Yellow
}

# Test AWS CLI with LocalStack
Write-Host "`n☁️ AWS CLI LocalStack Test:" -ForegroundColor Yellow
try {
    $env:AWS_ACCESS_KEY_ID = "test"
    $env:AWS_SECRET_ACCESS_KEY = "test"
    $env:AWS_DEFAULT_REGION = "us-east-1"
    
    $instances = aws --endpoint-url=http://localhost:4566 ec2 describe-instances --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType}' --output json 2>$null | ConvertFrom-Json
    
    if ($instances -and $instances.Count -gt 0) {
        Write-Host "   EC2 Instances:" -ForegroundColor Gray
        $instances | ForEach-Object {
            Write-Host "   - $($_.ID): $($_.State) ($($_.Type))" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "   No EC2 instances found" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "   AWS CLI test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n📊 Health Summary:" -ForegroundColor Magenta
$services = @(
    @{ Name = "LocalStack"; Status = $localstackHealthy },
    @{ Name = "Atlantis"; Status = $atlantisHealthy }
)

$healthyCount = ($services | Where-Object { $_.Status }).Count
$totalCount = $services.Count

Write-Host "   Healthy Services: $healthyCount/$totalCount" -ForegroundColor $(if ($healthyCount -eq $totalCount) { "Green" } else { "Yellow" })

if ($healthyCount -eq $totalCount) {
    Write-Host "`n🎉 All systems are healthy! Workshop environment is ready." -ForegroundColor Green
}
else {
    Write-Host "`n⚠️ Some services are unhealthy. Check the errors above." -ForegroundColor Yellow
    Write-Host "   Try: docker-compose restart" -ForegroundColor Gray
}

Write-Host "`n🔗 Quick Links:" -ForegroundColor Cyan
Write-Host "   - LocalStack: http://localhost:4566" -ForegroundColor Gray
Write-Host "   - Atlantis: http://localhost:4141" -ForegroundColor Gray
Write-Host "   - Health Check: curl http://localhost:4566/_localstack/health" -ForegroundColor Gray
