#!/usr/bin/env pwsh
# Rollback Script for Terraform Atlantis Workshop
# Provides emergency rollback capabilities

param(
    [Parameter(Mandatory=$false)]
    [string]$RollbackType = "git",  # git, state, emergency
    
    [Parameter(Mandatory=$false)]
    [string]$CommitHash = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

Write-Host "🔄 Terraform Atlantis Workshop - Rollback Procedure" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Gray

# Backup current state before rollback
function Backup-CurrentState {
    Write-Host "`n📦 Creating backup of current state..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = "backups\rollback-$timestamp"
    
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    # Backup terraform state
    if (Test-Path "terraform\terraform.tfstate") {
        Copy-Item "terraform\terraform.tfstate" "$backupDir\terraform.tfstate.before-rollback"
        Write-Host "   ✅ Terraform state backed up" -ForegroundColor Green
    }
    
    # Backup current git state
    $currentCommit = git rev-parse HEAD
    $currentCommit | Out-File "$backupDir\git-commit-before-rollback.txt"
    Write-Host "   ✅ Git commit hash saved: $currentCommit" -ForegroundColor Green
    
    return $backupDir
}

# Health check before rollback
function Test-PreRollbackHealth {
    Write-Host "`n🔍 Pre-rollback health check..." -ForegroundColor Yellow
    
    # Check AWS credentials and region
    try {
        $awsRegion = aws configure get region
        $awsAccount = aws sts get-caller-identity --query 'Account' --output text
        
        Write-Host "   ✅ AWS Region: $awsRegion" -ForegroundColor Green
        Write-Host "   ✅ AWS Account: $awsAccount" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Host "   ❌ AWS credentials not configured" -ForegroundColor Red
        return $false
    }
}

# Git-based rollback
function Invoke-GitRollback {
    param([string]$CommitHash)
    
    Write-Host "`n📝 Performing Git-based rollback..." -ForegroundColor Yellow
    
    if (-not $CommitHash) {
        # Get the previous commit
        $CommitHash = git rev-parse HEAD~1
        Write-Host "   Using previous commit: $CommitHash" -ForegroundColor Gray
    }
    
    try {
        # Create rollback branch
        $branchName = "rollback-$(Get-Date -Format 'yyyyMMdd-HHmm')"
        git checkout -b $branchName
        
        # Revert to specified commit
        git reset --hard $CommitHash
        
        Write-Host "   ✅ Git rollback completed" -ForegroundColor Green
        Write-Host "   Branch: $branchName" -ForegroundColor Gray
        Write-Host "   Commit: $CommitHash" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Host "   ❌ Git rollback failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# State-based rollback
function Invoke-StateRollback {
    Write-Host "`n💾 Performing State-based rollback..." -ForegroundColor Yellow
    
    if (-not (Test-Path "terraform\terraform.tfstate.backup")) {
        Write-Host "   ❌ No state backup found" -ForegroundColor Red
        return $false
    }
    
    try {
        Set-Location terraform
        
        # Use backup state
        Copy-Item "terraform.tfstate.backup" "terraform.tfstate" -Force
        
        # Refresh state
        terraform refresh -auto-approve
        
        Set-Location ..
        Write-Host "   ✅ State rollback completed" -ForegroundColor Green
        return $true
    }
    catch {
        Set-Location ..
        Write-Host "   ❌ State rollback failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Emergency rollback (destroy and recreate from backup)
function Invoke-EmergencyRollback {
    Write-Host "`n🚨 Performing Emergency rollback..." -ForegroundColor Red
    Write-Host "   This will destroy current infrastructure and recreate from backup" -ForegroundColor Yellow
    
    if (-not $Force) {
        $confirmation = Read-Host "   Are you sure? (type 'yes' to continue)"
        if ($confirmation -ne "yes") {
            Write-Host "   Rollback cancelled" -ForegroundColor Yellow
            return $false
        }
    }
    
    try {
        Set-Location terraform
        
        # Destroy current infrastructure
        Write-Host "   🔥 Destroying current infrastructure..." -ForegroundColor Yellow
        terraform destroy -auto-approve
        
        # Find latest backup
        $latestBackup = Get-ChildItem "..\backups" | Where-Object { $_.Name -like "*terraform.tfstate*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        if ($latestBackup) {
            Copy-Item $latestBackup.FullName "terraform.tfstate" -Force
            Write-Host "   📦 Restored from backup: $($latestBackup.Name)" -ForegroundColor Green
            
            # Recreate infrastructure
            terraform apply -auto-approve
            Write-Host "   ✅ Emergency rollback completed" -ForegroundColor Green
        }
        else {
            Write-Host "   ❌ No backup found for emergency rollback" -ForegroundColor Red
            Set-Location ..
            return $false
        }
        
        Set-Location ..
        return $true
    }
    catch {
        Set-Location ..
        Write-Host "   ❌ Emergency rollback failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Post-rollback validation
function Test-PostRollbackHealth {
    Write-Host "`n🔍 Post-rollback validation..." -ForegroundColor Yellow
    
    # Wait for services to stabilize
    Start-Sleep 10
    
    # Run health check
    if (Test-Path "monitoring\health-check.ps1") {
        & ".\monitoring\health-check.ps1"
    }
    else {
        Write-Host "   ⚠️ Health check script not found" -ForegroundColor Yellow
        
        # Basic validation
        try {
            Set-Location terraform
            $planOutput = terraform plan -detailed-exitcode
            $exitCode = $LASTEXITCODE
            Set-Location ..
            
            if ($exitCode -eq 0) {
                Write-Host "   ✅ Infrastructure is in sync" -ForegroundColor Green
                return $true
            }
            elseif ($exitCode -eq 2) {
                Write-Host "   ⚠️ Infrastructure has pending changes" -ForegroundColor Yellow
                return $true
            }
            else {
                Write-Host "   ❌ Infrastructure validation failed" -ForegroundColor Red
                return $false
            }
        }
        catch {
            Set-Location ..
            Write-Host "   ❌ Validation failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

# Main execution
Write-Host "`n🎯 Rollback Type: $RollbackType" -ForegroundColor Magenta

# Create backup before starting
$backupPath = Backup-CurrentState
Write-Host "   Backup location: $backupPath" -ForegroundColor Gray

# Pre-rollback health check
$preHealth = Test-PreRollbackHealth

# Execute rollback based on type
$rollbackSuccess = $false

switch ($RollbackType.ToLower()) {
    "git" {
        $rollbackSuccess = Invoke-GitRollback -CommitHash $CommitHash
    }
    "state" {
        $rollbackSuccess = Invoke-StateRollback
    }
    "emergency" {
        $rollbackSuccess = Invoke-EmergencyRollback
    }
    default {
        Write-Host "   ❌ Unknown rollback type: $RollbackType" -ForegroundColor Red
        Write-Host "   Valid types: git, state, emergency" -ForegroundColor Gray
        exit 1
    }
}

# Post-rollback validation
if ($rollbackSuccess) {
    Write-Host "`n✅ Rollback completed successfully!" -ForegroundColor Green
    Test-PostRollbackHealth
    
    Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Verify infrastructure is working correctly" -ForegroundColor White
    Write-Host "   2. Test critical functionality" -ForegroundColor White
    Write-Host "   3. Document the incident and rollback" -ForegroundColor White
    Write-Host "   4. If using git rollback, consider creating a PR to merge changes" -ForegroundColor White
}
else {
    Write-Host "`n❌ Rollback failed!" -ForegroundColor Red
    Write-Host "   Backup location: $backupPath" -ForegroundColor Yellow
    Write-Host "   Manual intervention may be required" -ForegroundColor Yellow
    exit 1
}
