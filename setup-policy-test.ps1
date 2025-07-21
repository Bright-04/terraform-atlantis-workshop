# Atlantis Policy Integration Test
# This script creates a test branch and PR to demonstrate policy enforcement with Atlantis

Write-Host "🎯 Setting up Atlantis Policy Validation Test..." -ForegroundColor Green

# Create a test branch for policy violations
$testBranch = "policy-validation-test-$(Get-Date -Format 'MMdd-HHmm')"
Write-Host "📝 Creating test branch: $testBranch" -ForegroundColor Cyan

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "❌ Not in a git repository. Initializing..." -ForegroundColor Yellow
    git init
    git remote add origin https://github.com/Bright-04/terraform-atlantis-workshop.git
}

# Stash any current changes
git stash push -m "Temporary stash before policy test"

# Create and checkout new branch
git checkout -b $testBranch

# Backup current terraform configuration
$backupDir = "terraform-backup-$(Get-Date -Format 'MMdd-HHmm')"
Copy-Item "terraform" $backupDir -Recurse -Force
Write-Host "📦 Backed up current config to: $backupDir" -ForegroundColor Yellow

# Create test scenario that violates multiple policies
$testConfig = @"
# Test configuration that violates multiple policies
# This will be added to main-local.tf to trigger policy violations

# Policy Violation 1: Missing CostCenter tag (Cost Control Policy)
resource "aws_instance" "policy_test_no_cost_tag" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name        = "policy-test-no-cost-tag"
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    # Missing: CostCenter tag - violates cost_control.rego
  }
}

# Policy Violation 2: Expensive instance type (Cost Control Policy)
resource "aws_instance" "policy_test_expensive" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "m5.large"  # Violates cost_control.rego
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name       = "policy-test-expensive"
    Environment = "test"
    Project    = "terraform-atlantis-workshop"
    CostCenter = "workshop"
  }
}

# Policy Violation 3: Unencrypted S3 bucket (Security Policy)
resource "aws_s3_bucket" "policy_test_unencrypted" {
  bucket = "terraform-atlantis-workshop-policy-test-unencrypted"
  
  tags = {
    Name       = "policy-test-unencrypted"
    Environment = "test"
    Project    = "terraform-atlantis-workshop"
    CostCenter = "workshop"
  }
  
  # Missing: server_side_encryption_configuration - violates terraform_security.rego
}

# Policy Violation 4: Overly permissive security group (Security Policy)
resource "aws_security_group" "policy_test_permissive" {
  name_prefix = "policy-test-permissive-"
  vpc_id      = aws_vpc.main.id
  description = "Test security group with policy violations"

  # Violates terraform_security.rego - all ports open
  ingress {
    description = "All ports - BAD POLICY VIOLATION!"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "policy-test-permissive-sg"
    Environment = "test"
    Project    = "terraform-atlantis-workshop"
    CostCenter = "workshop"
  }
}
"@

# Add test configuration to main-local.tf
Add-Content -Path "terraform\main-local.tf" -Value "`n`n# === POLICY VIOLATION TEST RESOURCES ===`n$testConfig"

Write-Host "✅ Added policy violation test resources to terraform\main-local.tf" -ForegroundColor Green

# Update Atlantis configuration to enforce policies
$atlantisConfig = @"
version: 3
projects:
  - name: terraform-atlantis-workshop
    dir: terraform
    terraform_version: v1.6.0
    workflow: policy-validation

workflows:
  policy-validation:
    plan:
      steps:
      - init
      - plan
      - policy_check:
          extra_args: ["--policy", "../policies/"]

policies:
  conftest_version: 0.46.0
  policy_sets:
    - name: workshop-policies
      path: policies/
      source: local
"@

$atlantisConfig | Out-File -FilePath "atlantis.yaml" -Encoding UTF8

Write-Host "✅ Updated atlantis.yaml with policy enforcement workflow" -ForegroundColor Green

# Create comprehensive test documentation
$testDocs = @"
# Policy Validation Test - Branch: $testBranch

## Test Objective
This PR demonstrates Atlantis policy validation by introducing multiple policy violations:

## Policy Violations Introduced

### 1. Cost Control Violations (cost_control.rego)
- ❌ **Missing CostCenter tag**: \`aws_instance.policy_test_no_cost_tag\`
- ❌ **Expensive instance type**: \`aws_instance.policy_test_expensive\` (m5.large)
- ❌ **Missing CostCenter tag**: \`aws_s3_bucket.policy_test_unencrypted\`

### 2. Security Violations (terraform_security.rego)
- ❌ **Unencrypted S3 bucket**: \`aws_s3_bucket.policy_test_unencrypted\`
- ❌ **Overly permissive security group**: \`aws_security_group.policy_test_permissive\` (all ports open)
- ⚠️ **Missing backup tags**: Multiple resources

## Expected Atlantis Behavior
1. ✅ Atlantis should automatically run \`terraform plan\`
2. ✅ Atlantis should run policy validation with Conftest
3. ❌ Atlantis should **BLOCK** the apply due to policy violations
4. 📝 Atlantis should comment with detailed policy violation report

## Test Instructions
1. Open a Pull Request with this branch
2. Wait for Atlantis to automatically run plan and policy check
3. Review policy violation comments from Atlantis
4. Verify that \`atlantis apply\` is blocked until violations are fixed

## To Fix Violations
\`\`\`terraform
# Add missing CostCenter tags
tags = {
  # ... existing tags ...
  CostCenter = "workshop"
}

# Change expensive instance type
instance_type = "t3.micro"

# Add S3 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "policy_test_encryption" {
  bucket = aws_s3_bucket.policy_test_unencrypted.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Fix security group rules (remove overly permissive rules)
\`\`\`

## Cleanup
After testing, remove the test resources and merge/close the PR.
"@

$testDocs | Out-File -FilePath "POLICY_TEST_README.md" -Encoding UTF8

# Commit changes
git add .
git commit -m "feat: Add policy validation test scenarios

- Add test resources that violate cost and security policies
- Update Atlantis configuration for policy enforcement  
- Test scenarios include:
  * Missing CostCenter tags
  * Expensive instance types
  * Unencrypted S3 buckets
  * Overly permissive security groups

This PR will test Atlantis policy validation and should be BLOCKED
until policy violations are resolved."

Write-Host "`n🎉 Test branch created successfully!" -ForegroundColor Green
Write-Host "📊 Summary of policy violations added:" -ForegroundColor Yellow
Write-Host "  • Missing CostCenter tags (Cost Control)" -ForegroundColor Red
Write-Host "  • Expensive instance type m5.large (Cost Control)" -ForegroundColor Red  
Write-Host "  • Unencrypted S3 bucket (Security)" -ForegroundColor Red
Write-Host "  • Overly permissive security group (Security)" -ForegroundColor Red

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Push branch to GitHub:" -ForegroundColor White
Write-Host "   git push origin $testBranch" -ForegroundColor Gray
Write-Host "`n2. Create Pull Request on GitHub" -ForegroundColor White
Write-Host "`n3. Watch Atlantis automatically:" -ForegroundColor White
Write-Host "   • Run terraform plan" -ForegroundColor Gray
Write-Host "   • Run policy validation" -ForegroundColor Gray
Write-Host "   • Comment with policy violations" -ForegroundColor Gray
Write-Host "   • Block atlantis apply until violations fixed" -ForegroundColor Gray

Write-Host "`n4. Test policy validation by commenting 'atlantis apply'" -ForegroundColor White
Write-Host "   (Should be blocked due to policy violations)" -ForegroundColor Gray

Write-Host "`n📝 Test documentation created: POLICY_TEST_README.md" -ForegroundColor Yellow
Write-Host "🔙 Your original config is backed up in: $backupDir" -ForegroundColor Yellow

Write-Host "`n✨ Policy validation test setup complete!" -ForegroundColor Green
