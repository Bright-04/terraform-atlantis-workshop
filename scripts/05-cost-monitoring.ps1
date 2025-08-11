# =============================================================================
# 05 - Cost Monitoring Script
# =============================================================================
# This script monitors and reports AWS costs for the deployed infrastructure
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

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "ap-southeast-1",
    
    [Parameter(Mandatory=$false)]
    [decimal]$MonthlyBudget = 50.00
)

Write-Host "Step 5: Cost Monitoring - AWS Production Environment" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Gray

# Function to get AWS resource cost estimates
function Get-ResourceAWSCost {
    param(
        [string]$ResourceType,
        [int]$Count = 1,
        [hashtable]$Attributes = @{}
    )
    
    # Simulated AWS pricing (for demonstration purposes)
    $pricing = @{
        'aws_instance' = @{
            't3.micro' = 0.0104    # ~$7.50/month
            't3.small' = 0.0208    # ~$15.00/month
            't3.medium' = 0.0416   # ~$30.00/month
        }
        'aws_s3_bucket' = 0.023   # $0.023 per GB per month
        'aws_vpc' = 0.00          # Free
        'aws_subnet' = 0.00       # Free
        'aws_internet_gateway' = 0.00  # Free
        'aws_route_table' = 0.00  # Free
        'aws_security_group' = 0.00    # Free
        'aws_iam_role' = 0.00     # Free
        'aws_cloudwatch_log_group' = 0.00  # Free tier
    }
    
    switch ($ResourceType) {
        'aws_instance' {
            $instanceType = if ($Attributes['instance_type']) { $Attributes['instance_type'] } else { 't3.micro' }
            if ($pricing['aws_instance'][$instanceType]) {
                return $pricing['aws_instance'][$instanceType] * $Count
            } else {
                return $pricing['aws_instance']['t3.micro'] * $Count
            }
        }
        'aws_s3_bucket' {
            $storageGB = if ($Attributes['storage_gb']) { $Attributes['storage_gb'] } else { 1 }
            return ($pricing['aws_s3_bucket'] * $storageGB / (24 * 30)) * $Count
        }
        default {
            $cost = if ($pricing[$ResourceType]) { $pricing[$ResourceType] } else { 0.00 }
            return $cost
        }
    }
}

# Get current infrastructure
Write-Host "Analyzing Current Infrastructure:" -ForegroundColor Yellow

if (-not (Test-Path "terraform\terraform.tfstate")) {
    Write-Host "   No Terraform state found" -ForegroundColor Red
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
                if ($resource.values.instance_type) {
                    $attributes['instance_type'] = $resource.values.instance_type
                }
                $hourlyCost = Get-ResourceAWSCost $resource.type 1 $attributes
            }
            'aws_s3_bucket' {
                $attributes['storage_gb'] = 1
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
    Write-Host "   Error reading Terraform state: $($_.Exception.Message)" -ForegroundColor Red
    Set-Location ..
    exit 1
}

# Calculate totals
$totalDailyCost = $totalHourlyCost * 24
$totalMonthlyCost = $totalDailyCost * 30

# Display cost breakdown
Write-Host "Cost Breakdown (Simulated AWS Pricing):" -ForegroundColor Magenta

$resourceCosts | Sort-Object MonthlyCost -Descending | ForEach-Object {
    $icon = switch ($_.Type) {
        'aws_instance' { 'Computer' }
        'aws_s3_bucket' { 'Bucket' }
        'aws_vpc' { 'Network' }
        default { 'Resource' }
    }
    
    if ($_.MonthlyCost -gt 0) {
        Write-Host "   $icon $($_.Name)" -ForegroundColor White
        Write-Host "      Type: $($_.Type)" -ForegroundColor Gray
        if ($_.Attributes.instance_type) {
            Write-Host "      Instance Type: $($_.Attributes.instance_type)" -ForegroundColor Gray
        }
        Write-Host "      Hourly: $($_.HourlyCost.ToString('F4'))" -ForegroundColor Gray
        Write-Host "      Daily: $($_.DailyCost.ToString('F2'))" -ForegroundColor Gray
        Write-Host "      Monthly: $($_.MonthlyCost.ToString('F2'))" -ForegroundColor Green
        Write-Host ""
    }
    else {
        Write-Host "   $icon $($_.Name) - FREE" -ForegroundColor Green
    }
}

# Display totals
Write-Host "Cost Summary:" -ForegroundColor Cyan
Write-Host "   Hourly Total: $($totalHourlyCost.ToString('F4'))" -ForegroundColor White
Write-Host "   Daily Total: $($totalDailyCost.ToString('F2'))" -ForegroundColor White
Write-Host "   Monthly Total: $($totalMonthlyCost.ToString('F2'))" -ForegroundColor Green

# Budget alerts
Write-Host "Budget Alerts:" -ForegroundColor Yellow
Write-Host "   Monthly Budget: $($MonthlyBudget.ToString('F2'))" -ForegroundColor Gray

$budgetUsage = ($totalMonthlyCost / $MonthlyBudget) * 100
if ($budgetUsage -le 100) {
    Write-Host "   Within budget ($($budgetUsage.ToString('F1'))% used)" -ForegroundColor Green
} else {
    Write-Host "   OVER BUDGET ($($budgetUsage.ToString('F1'))% used)" -ForegroundColor Red
}

# Cost optimization recommendations
Write-Host "Cost Optimization Recommendations:" -ForegroundColor Yellow

$expensiveResources = $resourceCosts | Where-Object { $_.MonthlyCost -gt 10 }
if ($expensiveResources) {
    Write-Host "   Consider optimizing these resources:" -ForegroundColor Yellow
    foreach ($resource in $expensiveResources) {
        Write-Host "   - $($resource.Name): $($resource.MonthlyCost.ToString('F2'))/month" -ForegroundColor Yellow
    }
} else {
    Write-Host "   All resources are cost-optimized for workshop environment" -ForegroundColor Green
}

# Generate cost report
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$reportPath = "monitoring\cost-report-$timestamp.json"

# Ensure monitoring directory exists
if (-not (Test-Path "monitoring")) {
    New-Item -ItemType Directory -Path "monitoring" -Force | Out-Null
}

$costReport = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    region = $Region
    monthly_budget = $MonthlyBudget
    total_hourly_cost = $totalHourlyCost
    total_daily_cost = $totalDailyCost
    total_monthly_cost = $totalMonthlyCost
    budget_usage_percent = $budgetUsage
    resources = $resourceCosts
}

$costReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "Cost report saved to $reportPath" -ForegroundColor Cyan

Write-Host "Cost Monitoring Completed!" -ForegroundColor Green
