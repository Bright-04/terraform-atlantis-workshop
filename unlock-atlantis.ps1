# Unlock Atlantis - Delete existing locks
Write-Host "🔓 Unlocking Atlantis..." -ForegroundColor Green

# Check if Atlantis container is running
Write-Host "`n📦 Checking Atlantis container..." -ForegroundColor Yellow
$atlantisRunning = docker ps --format "table {{.Names}}" | Select-String "atlantis_workshop"

if ($atlantisRunning) {
    Write-Host "✅ Atlantis container is running" -ForegroundColor Green
    
    # Delete the lock by removing the lock file
    Write-Host "`n🔓 Deleting Atlantis lock..." -ForegroundColor Yellow
    docker exec atlantis_workshop find /atlantis -name "*.lock" -delete 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Lock deleted successfully" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  No lock files found or already deleted" -ForegroundColor Yellow
    }
    
    # Alternative: Clear the entire data directory (more aggressive)
    Write-Host "`n🧹 Clearing Atlantis data directory..." -ForegroundColor Yellow
    docker exec atlantis_workshop rm -rf /atlantis/repos/* 2>$null
    
    Write-Host "✅ Atlantis unlocked and ready for testing!" -ForegroundColor Green
    Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Go to your GitHub PR" -ForegroundColor White
    Write-Host "2. Comment: atlantis plan" -ForegroundColor White
    Write-Host "3. Should work without custom workflow errors!" -ForegroundColor White
} else {
    Write-Host "❌ Atlantis container is not running" -ForegroundColor Red
    Write-Host "Please start Atlantis first: docker-compose up -d" -ForegroundColor Yellow
} 