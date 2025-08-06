# Policy Test Script
# This script simulates what Atlantis policy checks would do

Write-Host "=== TERRAFORM-ATLANTIS POLICY CHECK TEST ===" -ForegroundColor Cyan
Write-Host ""

# Read the terraform plan (simplified)
Write-Host "📋 Analyzing Terraform Plan..." -ForegroundColor Yellow
Write-Host ""

# Simulate policy violations based on our test configuration
$violations = @()

Write-Host "🔍 Checking Cost Control Policies..." -ForegroundColor Blue
Write-Host ""

# Cost Control Violations
$violations += "❌ COST VIOLATION: aws_instance.test_violation uses expensive instance type 'm5.large'"
$violations += "❌ COST VIOLATION: aws_instance.test_violation missing required tag 'CostCenter'"
$violations += "❌ COST VIOLATION: aws_s3_bucket.test_violation missing required tag 'CostCenter'"
$violations += "❌ COST VIOLATION: aws_ebs_volume.test_violation missing required tag 'CostCenter'"
$violations += "❌ COST VIOLATION: aws_s3_bucket.test_violation naming convention violation"

Write-Host "🔒 Checking Security Policies..." -ForegroundColor Blue
Write-Host ""

# Security Violations
$violations += "❌ SECURITY VIOLATION: aws_instance.test_violation missing required tag 'Environment'"
$violations += "❌ SECURITY VIOLATION: aws_instance.test_violation missing required tag 'Project'"  
$violations += "❌ SECURITY VIOLATION: aws_security_group.test_violation overly permissive ingress"

Write-Host "📊 POLICY CHECK RESULTS:" -ForegroundColor Red
Write-Host "=========================" -ForegroundColor Red
Write-Host ""

foreach ($violation in $violations) {
    Write-Host $violation -ForegroundColor Red
}

Write-Host ""
Write-Host "📈 SUMMARY:" -ForegroundColor Yellow
Write-Host "- Total violations found: $($violations.Count)" -ForegroundColor Red
Write-Host "- Cost control violations: 5" -ForegroundColor Red  
Write-Host "- Security violations: 3" -ForegroundColor Red
Write-Host ""
Write-Host "🚫 RESULT: POLICY CHECK FAILED" -ForegroundColor Red
Write-Host "💡 Apply operations will be blocked until violations are resolved" -ForegroundColor Yellow
Write-Host ""

# Simulate what Atlantis would show
Write-Host "=== ATLANTIS SIMULATION ===" -ForegroundColor Cyan
Write-Host "If this were running in Atlantis on a GitHub PR:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. ✅ 'atlantis plan' would execute successfully"
Write-Host "2. ❌ 'atlantis policy_check' would FAIL with above violations"
Write-Host "3. 🚫 'atlantis apply' would be BLOCKED until violations are fixed"
Write-Host "4. 📋 PR would show policy violation comments"
Write-Host ""

Write-Host "To test with real Atlantis:" -ForegroundColor Green
Write-Host "1. Create a PR from this branch to main"
Write-Host "2. Comment 'atlantis plan' on the PR"
Write-Host "3. Observe policy check failures"  
Write-Host "4. Fix violations and test again"
