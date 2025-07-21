# Terraform Destroy Script for Workshop
# Run this script to destroy your infrastructure

Write-Host "🗑️  Starting Terraform Destroy for Workshop..." -ForegroundColor Red

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
