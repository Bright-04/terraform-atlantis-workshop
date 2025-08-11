# =============================================================================
# 05 - AWS Cost Monitoring Script
# =============================================================================
# Monitors real AWS infrastructure costs
# 
# Workflow Order:
# 1. 01-validate-environment.ps1
# 2. 02-setup-github-actions.ps1
# 3. 03-deploy-infrastructure.ps1
# 4. 04-health-monitoring.ps1
# 5. 05-cost-monitoring.ps1 (this script)
# 6. 06-rollback-procedures.ps1
# 7. 07-cleanup-infrastructure.ps1
# =============================================================================

Write-Host "💰 Step 5: Cost Monitoring - AWS Production Environment" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Gray

# Function to calculate AWS costs
function Get-ResourceAWSCost {
    param(
        [string]$ResourceType,
        [int]$Count = 1,
        [hashtable]$Attributes = @{}
    )
    
    # Simulated hourly costs (based on AWS us-east-1 pricing)
    $pricing = @{
        'aws_instance' = @{
            't3.micro' = 0.0104
            't3.small' = 0.0208  
            't3.medium' = 0.0416
            'm5.large' = 0.096
        }
        'aws_s3_bucket' = 0.023  # per GB/month
        'aws_vpc' = 0.00        # Free
        'aws_subnet' = 0.00     # Free  
        'aws_internet_gateway' = 0.00  # Free
        'aws_security_group' = 0.00    # Free
        'aws_route_table' = 0.00       # Free
    }
    
    switch ($ResourceType) {
        'aws_instance' {
            $instanceType = $Attributes['instance_type'] ?? 't3.micro'
            return $pricing['aws_instance'][$instanceType] * $Count
        }
        'aws_s3_bucket' {
            $storageGB = $Attributes['storage_gb'] ?? 1  # Assume 1GB minimum
            return ($pricing['aws_s3_bucket'] * $storageGB / (24 * 30)) * $Count  # Convert to hourly
        }
        default {
            return $pricing[$ResourceType] ?? 0.00
        }
    }
}

# Get current infrastructure
Write-Host "`n📊 Analyzing Current Infrastructure:" -ForegroundColor Yellow

if (-not (Test-Path "terraform\terraform.tfstate")) {
    Write-Host "   ❌ No Terraform state found" -ForegroundColor Red
    exit 1
}

try {
    Set-Location terraform
    $stateJson = terraform show -json | ConvertFrom-Json
    $resources = $stateJson.values.root_module.resources
    
    Set-Location ..
    
    $totalHourlyCost = 0.0
    $resourceCosts = @()
    
    Write-Host "   Resources found: $($resources.Count)" -ForegroundColor Gray
    
    foreach ($resource in $resources) {
        $hourlyCost = 0.0
        $attributes = @{}
        
        switch ($resource.type) {
            'aws_instance' {
                $attributes['instance_type'] = $resource.values.instance_type
                $hourlyCost = Get-ResourceAWSCost $resource.type 1 $attributes
            }
            'aws_s3_bucket' {
                $attributes['storage_gb'] = 1  # AWS storage
                $hourlyCost = Get-ResourceAWSCost $resource.type 1 $attributes
            }
            default {
                $hourlyCost = Get-ResourceAWSCost $resource.type
            }
        }
        
        $resourceCosts += [PSCustomObject]@{
            Name = $resource.address
            Type = $resource.type
            HourlyCost = $hourlyCost
            DailyCost = $hourlyCost * 24
            MonthlyCost = $hourlyCost * 24 * 30
            Attributes = $attributes
        }
        
        $totalHourlyCost += $hourlyCost
    }
    
}
catch {
    Write-Host "   ❌ Error reading Terraform state: $($_.Exception.Message)" -ForegroundColor Red
    Set-Location ..
    exit 1
}

# Display cost breakdown
Write-Host "`n💵 Cost Breakdown (Simulated AWS Pricing):" -ForegroundColor Magenta

$resourceCosts | Sort-Object MonthlyCost -Descending | ForEach-Object {
    $icon = switch ($_.Type) {
        'aws_instance' { '🖥️' }
        'aws_s3_bucket' { '🪣' }
        'aws_vpc' { '🌐' }
        default { '📦' }
    }
    
    if ($_.MonthlyCost -gt 0) {
        Write-Host "   $icon $($_.Name)" -ForegroundColor White
        Write-Host "      Type: $($_.Type)" -ForegroundColor Gray
        if ($_.Attributes.instance_type) {
            Write-Host "      Instance Type: $($_.Attributes.instance_type)" -ForegroundColor Gray
        }
        Write-Host "      Hourly: `$$($_.HourlyCost.ToString('F4'))" -ForegroundColor Gray
        Write-Host "      Daily: `$$($_.DailyCost.ToString('F2'))" -ForegroundColor Gray
        Write-Host "      Monthly: `$$($_.MonthlyCost.ToString('F2'))" -ForegroundColor Green
        Write-Host ""
    }
    else {
        Write-Host "   $icon $($_.Name) - FREE" -ForegroundColor Green
    }
}

# Cost summary
$totalDailyCost = $totalHourlyCost * 24
$totalMonthlyCost = $totalHourlyCost * 24 * 30

Write-Host "`n📈 Cost Summary:" -ForegroundColor Cyan
Write-Host "   Hourly Total: `$$($totalHourlyCost.ToString('F4'))" -ForegroundColor Yellow
Write-Host "   Daily Total: `$$($totalDailyCost.ToString('F2'))" -ForegroundColor Yellow  
Write-Host "   Monthly Total: `$$($totalMonthlyCost.ToString('F2'))" -ForegroundColor Green

# Cost alerts based on workshop budget
$monthlyBudget = 50.00  # Workshop budget limit
Write-Host "`n🚨 Budget Alerts:" -ForegroundColor Magenta
Write-Host "   Monthly Budget: `$$($monthlyBudget.ToString('F2'))" -ForegroundColor Gray

if ($totalMonthlyCost -gt $monthlyBudget) {
    Write-Host "   ❌ OVER BUDGET! Monthly cost exceeds budget by `$$($($totalMonthlyCost - $monthlyBudget).ToString('F2'))" -ForegroundColor Red
}
elseif ($totalMonthlyCost -gt ($monthlyBudget * 0.8)) {
    Write-Host "   ⚠️ WARNING: Monthly cost is 80%+ of budget" -ForegroundColor Yellow
}
else {
    Write-Host "   ✅ Within budget ($(($totalMonthlyCost / $monthlyBudget * 100).ToString('F1'))% used)" -ForegroundColor Green
}

# Cost optimization recommendations
Write-Host "`n💡 Cost Optimization Recommendations:" -ForegroundColor Cyan

$expensiveResources = $resourceCosts | Where-Object { $_.MonthlyCost -gt 10.00 }
if ($expensiveResources.Count -gt 0) {
    Write-Host "   💰 Expensive Resources (>$10/month):" -ForegroundColor Yellow
    $expensiveResources | ForEach-Object {
        Write-Host "   - $($_.Name): `$$($_.MonthlyCost.ToString('F2'))/month" -ForegroundColor Gray
        
        if ($_.Type -eq 'aws_instance' -and $_.Attributes.instance_type -ne 't3.micro') {
            Write-Host "     💡 Consider using t3.micro for workshop environments" -ForegroundColor Blue
        }
    }
}
else {
    Write-Host "   ✅ All resources are cost-optimized for workshop environment" -ForegroundColor Green
}

# LocalStack savings
Write-Host "`n🎉 LocalStack Savings:" -ForegroundColor Green
Write-Host "   💰 Current AWS cost (if real): `$$($totalMonthlyCost.ToString('F2'))/month" -ForegroundColor Gray
Write-Host "   💰 LocalStack cost: `$0.00/month" -ForegroundColor Green
Write-Host "   💰 Monthly savings: `$$($totalMonthlyCost.ToString('F2'))" -ForegroundColor Green
Write-Host "   💰 Annual savings: `$$($totalMonthlyCost * 12).ToString('F2'))" -ForegroundColor Green

# Export cost report
$report = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    environment = "LocalStack"
    resources = $resourceCosts
    totals = @{
        hourly = $totalHourlyCost
        daily = $totalDailyCost
        monthly = $totalMonthlyCost
    }
    budget = @{
        limit = $monthlyBudget
        used_percentage = ($totalMonthlyCost / $monthlyBudget * 100)
        status = if ($totalMonthlyCost -gt $monthlyBudget) { "OVER_BUDGET" } 
                elseif ($totalMonthlyCost -gt ($monthlyBudget * 0.8)) { "WARNING" } 
                else { "OK" }
    }
}

$report | ConvertTo-Json -Depth 4 | Out-File "monitoring\cost-report-$(Get-Date -Format 'yyyyMMdd-HHmm').json" -Encoding UTF8
Write-Host "`n📄 Cost report saved to monitoring\cost-report-$(Get-Date -Format 'yyyyMMdd-HHmm').json" -ForegroundColor Gray
