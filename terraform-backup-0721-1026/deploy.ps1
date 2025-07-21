# Terraform Deployment Script for Workshop
# Run this script to deploy your infrastructure

Write-Host "🚀 Starting Terraform Deployment for Workshop..." -ForegroundColor Green

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "❌ terraform.tfvars not found. Copying from example..." -ForegroundColor Yellow
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
    Write-Host "✅ Please edit terraform.tfvars with your specific values" -ForegroundColor Yellow
    exit 1
}

# Initialize Terraform
Write-Host "📦 Initializing Terraform..." -ForegroundColor Blue
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform init failed!" -ForegroundColor Red
    exit 1
}

# Validate configuration
Write-Host "🔍 Validating Terraform configuration..." -ForegroundColor Blue
terraform validate

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform validation failed!" -ForegroundColor Red
    exit 1
}

# Plan the deployment
Write-Host "📋 Planning Terraform deployment..." -ForegroundColor Blue
terraform plan -out=tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform plan failed!" -ForegroundColor Red
    exit 1
}

# Ask for confirmation
$confirmation = Read-Host "Do you want to apply this plan? (y/N)"
if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
    Write-Host "🔨 Applying Terraform configuration..." -ForegroundColor Blue
    terraform apply tfplan
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Terraform deployment completed successfully!" -ForegroundColor Green
        Write-Host "🌐 Your infrastructure is now running!" -ForegroundColor Green
        
        # Show outputs
        Write-Host "📊 Infrastructure Outputs:" -ForegroundColor Yellow
        terraform output
    } else {
        Write-Host "❌ Terraform apply failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ Deployment cancelled by user" -ForegroundColor Yellow
    Remove-Item tfplan -ErrorAction SilentlyContinue
}
