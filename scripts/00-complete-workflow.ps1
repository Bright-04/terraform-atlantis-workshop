# =============================================================================
# 00 - Complete Workshop Workflow Script
# =============================================================================
# This script runs the complete Terraform Atlantis Workshop workflow
# 
# Workflow Steps:
# 1. 01-validate-environment.ps1
# 2. 02-setup-github-actions.ps1
# 3. 03-deploy-infrastructure.ps1
# 4. 04-health-monitoring.ps1
# 5. 05-cost-monitoring.ps1
# 6. 06-rollback-procedures.ps1 (optional)
# 7. 07-cleanup-infrastructure.ps1 (optional)
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipValidation = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipGitHubSetup = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDeployment = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipMonitoring = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeRollback = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeCleanup = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoConfirm = $false
)

Write-Host "Terraform Atlantis Workshop - Complete Workflow" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Gray
Write-Host "This script will run the complete workshop workflow" -ForegroundColor White
Write-Host ""

# Display workflow steps
Write-Host "Workflow Steps:" -ForegroundColor Cyan
$steps = @(
    @{Name="Environment Validation"; Script="01-validate-environment.ps1"; Skip=$SkipValidation},
    @{Name="GitHub Actions Setup"; Script="02-setup-github-actions.ps1"; Skip=$SkipGitHubSetup},
    @{Name="Infrastructure Deployment"; Script="03-deploy-infrastructure.ps1"; Skip=$SkipDeployment},
    @{Name="Health Monitoring"; Script="04-health-monitoring.ps1"; Skip=$SkipMonitoring},
    @{Name="Cost Monitoring"; Script="05-cost-monitoring.ps1"; Skip=$SkipMonitoring},
    @{Name="Rollback Procedures"; Script="06-rollback-procedures.ps1"; Skip=(-not $IncludeRollback)},
    @{Name="Infrastructure Cleanup"; Script="07-cleanup-infrastructure.ps1"; Skip=(-not $IncludeCleanup)}
)

for ($i = 0; $i -lt $steps.Count; $i++) {
    $step = $steps[$i]
    $status = if ($step.Skip) { "SKIPPED" } else { "ENABLED" }
    Write-Host "   $($i+1). $($step.Name) - $status" -ForegroundColor $(if ($step.Skip) { "Gray" } else { "White" })
}

Write-Host ""

# Confirm execution
if (-not $AutoConfirm) {
    $confirmation = Read-Host "Do you want to proceed with the workflow? (y/N)"
    if ($confirmation -ne "y" -and $confirmation -ne "Y") {
        Write-Host "Workflow cancelled" -ForegroundColor Yellow
        exit 0
    }
}

            # Function to run a script
            function Invoke-WorkflowStep {
                param(
                    [string]$StepName,
                    [string]$ScriptPath,
                    [bool]$Skip = $false
                )
                
                Write-Host "`nRunning: $StepName" -ForegroundColor Yellow
                Write-Host "=============================================" -ForegroundColor Gray
                
                if ($Skip) {
                    Write-Host "Skipping $StepName" -ForegroundColor Gray
                    return $true
                }
                
                if (-not (Test-Path ".\scripts\$ScriptPath")) {
                    Write-Host "Script not found: .\scripts\$ScriptPath" -ForegroundColor Red
                    return $false
                }
                
                try {
                    $result = & ".\scripts\$ScriptPath"
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "$StepName completed successfully" -ForegroundColor Green
                        return $true
                    } else {
                        Write-Host "$StepName failed with exit code: $LASTEXITCODE" -ForegroundColor Red
                        return $false
                    }
                }
                catch {
                    Write-Host "$StepName failed with error: $($_.Exception.Message)" -ForegroundColor Red
                    return $false
                }
            }

# Execute workflow steps
$successCount = 0
$totalSteps = $steps.Count

foreach ($step in $steps) {
    $success = Invoke-WorkflowStep -StepName $step.Name -ScriptPath $step.Script -Skip $step.Skip
    if ($success) {
        $successCount++
    } else {
        Write-Host "`nWorkflow stopped due to failure in: $($step.Name)" -ForegroundColor Red
        Write-Host "Please fix the issue and run the workflow again" -ForegroundColor Yellow
        exit 1
    }
}

# Summary
Write-Host "`nWorkflow Summary" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Gray
Write-Host "Completed: $successCount/$totalSteps steps" -ForegroundColor Green

if ($successCount -eq $totalSteps) {
    Write-Host "`nWorkshop completed successfully!" -ForegroundColor Green
    Write-Host "Check the documentation for next steps and advanced topics" -ForegroundColor Cyan
} else {
    Write-Host "`nSome steps were skipped or failed" -ForegroundColor Yellow
    Write-Host "Review the output above for any issues" -ForegroundColor Yellow
}

            Write-Host "`nAvailable scripts for manual execution:" -ForegroundColor Cyan
            Write-Host "   • scripts/01-validate-environment.ps1 - Validate setup" -ForegroundColor White
            Write-Host "   • scripts/02-setup-github-actions.ps1 - Configure GitHub Actions" -ForegroundColor White
            Write-Host "   • scripts/03-deploy-infrastructure.ps1 - Deploy to AWS" -ForegroundColor White
            Write-Host "   • scripts/04-health-monitoring.ps1 - Monitor infrastructure health" -ForegroundColor White
            Write-Host "   • scripts/05-cost-monitoring.ps1 - Monitor costs" -ForegroundColor White
            Write-Host "   • scripts/06-rollback-procedures.ps1 - Emergency rollback" -ForegroundColor White
            Write-Host "   • scripts/07-cleanup-infrastructure.ps1 - Clean up resources" -ForegroundColor White
