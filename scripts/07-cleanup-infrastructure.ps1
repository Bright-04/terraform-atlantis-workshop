# =============================================================================
# 07 - Infrastructure Cleanup Script
# =============================================================================
# Run this script to destroy your infrastructure and clean up resources
# 
# Workflow Order:
# 1. 01-validate-environment.ps1
# 2. 02-setup-github-actions.ps1
# 3. 03-deploy-infrastructure.ps1
# 4. 04-health-monitoring.ps1
# 5. 05-cost-monitoring.ps1
# 6. 06-rollback-procedures.ps1
# 7. 07-cleanup-infrastructure.ps1 (this script)
# =============================================================================

Write-Host "🗑️  Step 7: Starting Infrastructure Cleanup..." -ForegroundColor Red

# Confirm destruction
Write-Host "⚠️  This will DESTROY all infrastructure created by Terraform!" -ForegroundColor Yellow
$confirmation = Read-Host "Are you sure you want to destroy all resources? Type 'destroy' to confirm"

if ($confirmation -eq 'destroy') {
    Write-Host "🔨 Destroying Terraform infrastructure..." -ForegroundColor Red
    terraform destroy -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Infrastructure destroyed successfully!" -ForegroundColor Green
        Write-Host "💰 Remember to check AWS console for any remaining resources" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Terraform destroy failed!" -ForegroundColor Red
        Write-Host "🔧 You may need to manually clean up some resources" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "❌ Destroy cancelled - infrastructure preserved" -ForegroundColor Yellow
}
