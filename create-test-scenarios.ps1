# Policy Violation Test Scenarios for Terraform Atlantis Workshop
# This script creates test scenarios to trigger different policy violations

param(
    [string]$TestType = "all"
)

Write-Host "🧪 Creating Policy Violation Test Scenarios..." -ForegroundColor Green

$testDir = "policy-test-scenarios"
if (-not (Test-Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir
}

function Create-TestScenario {
    param(
        [string]$ScenarioName,
        [string]$Description,
        [string]$TerraformConfig
    )
    
    $scenarioDir = "$testDir\$ScenarioName"
    if (-not (Test-Path $scenarioDir)) {
        New-Item -ItemType Directory -Path $scenarioDir -Force
    }
    
    Write-Host "📝 Creating test scenario: $Description" -ForegroundColor Cyan
    
    # Create main.tf for this scenario
    $TerraformConfig | Out-File -FilePath "$scenarioDir\main.tf" -Encoding UTF8
    
    # Copy provider and variables
    Copy-Item "terraform\main-local.tf" "$scenarioDir\" -Force
    Copy-Item "terraform\variables.tf" "$scenarioDir\" -Force
    Copy-Item "terraform\outputs.tf" "$scenarioDir\" -Force
    Copy-Item "terraform\terraform.tfvars" "$scenarioDir\" -Force
    
    return $scenarioDir
}

# Test Scenario 1: Missing Cost Center Tag
if ($TestType -eq "all" -or $TestType -eq "cost-tag") {
    $config1 = @"
# Test Case: Missing CostCenter tag (should violate cost_control.rego)
resource "aws_instance" "test_no_cost_tag" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name        = "test-no-cost-tag"
    Environment = "test"
    Project     = "terraform-atlantis-workshop"
    # Missing CostCenter tag - should trigger policy violation
  }
}
"@
    $scenario1 = Create-TestScenario -ScenarioName "missing-cost-tag" -Description "Missing CostCenter tag violation" -TerraformConfig $config1
}

# Test Scenario 2: Expensive Instance Type
if ($TestType -eq "all" -or $TestType -eq "expensive-instance") {
    $config2 = @"
# Test Case: Expensive instance type (should violate cost_control.rego)
resource "aws_instance" "test_expensive" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "m5.large"  # This should trigger cost control policy
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name       = "test-expensive-instance"
    Environment = "test"
    Project    = "terraform-atlantis-workshop"
    CostCenter = "workshop"
  }
}
"@
    $scenario2 = Create-TestScenario -ScenarioName "expensive-instance" -Description "Expensive instance type violation" -TerraformConfig $config2
}

# Test Scenario 3: Missing Required Tags
if ($TestType -eq "all" -or $TestType -eq "missing-tags") {
    $config3 = @"
# Test Case: Missing required tags (should violate terraform_security.rego)
resource "aws_instance" "test_missing_tags" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name = "test-missing-tags"
    # Missing Environment and Project tags - should trigger security policy
    CostCenter = "workshop"
  }
}
"@
    $scenario3 = Create-TestScenario -ScenarioName "missing-tags" -Description "Missing required tags violation" -TerraformConfig $config3
}

# Test Scenario 4: Unencrypted S3 Bucket
if ($TestType -eq "all" -or $TestType -eq "unencrypted-s3") {
    $config4 = @"
# Test Case: Unencrypted S3 bucket (should violate terraform_security.rego)
resource "aws_s3_bucket" "test_unencrypted" {
  bucket = "terraform-atlantis-workshop-test-unencrypted"
  
  tags = {
    Name       = "test-unencrypted-bucket"
    Environment = "test"
    Project    = "terraform-atlantis-workshop"
    CostCenter = "workshop"
  }
  
  # No server_side_encryption_configuration - should trigger security policy
}
"@
    $scenario4 = Create-TestScenario -ScenarioName "unencrypted-s3" -Description "Unencrypted S3 bucket violation" -TerraformConfig $config4
}

# Test Scenario 5: Overly Permissive Security Group
if ($TestType -eq "all" -or $TestType -eq "permissive-sg") {
    $config5 = @"
# Test Case: Overly permissive security group (should violate terraform_security.rego)
resource "aws_security_group" "test_permissive" {
  name_prefix = "test-permissive-sg"
  vpc_id      = aws_vpc.main.id
  description = "Test overly permissive security group"

  ingress {
    description = "All ports open - BAD!"
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
    Name       = "test-permissive-sg"
    Environment = "test"
    Project    = "terraform-atlantis-workshop"
  }
}
"@
    $scenario5 = Create-TestScenario -ScenarioName "permissive-sg" -Description "Overly permissive security group violation" -TerraformConfig $config5
}

Write-Host "`n✅ Test scenarios created successfully!" -ForegroundColor Green
Write-Host "📁 Test scenarios location: $testDir" -ForegroundColor Yellow

Write-Host "`n🧪 Available test scenarios:" -ForegroundColor Cyan
Get-ChildItem $testDir -Directory | ForEach-Object {
    Write-Host "  • $($_.Name)" -ForegroundColor White
}

Write-Host "`n💡 Next steps:" -ForegroundColor Magenta
Write-Host "1. Test individual scenarios:" -ForegroundColor White
Write-Host "   cd $testDir\<scenario-name>" -ForegroundColor Gray
Write-Host "   terraform init && terraform plan -out tfplan.binary" -ForegroundColor Gray
Write-Host "   terraform show -json tfplan.binary > tfplan.json" -ForegroundColor Gray
Write-Host "   conftest test --policy ..\..\policies\ tfplan.json" -ForegroundColor Gray

Write-Host "`n2. Create a branch and test with Atlantis:" -ForegroundColor White
Write-Host "   git checkout -b test-policy-violations" -ForegroundColor Gray
Write-Host "   # Copy a test scenario to terraform/ folder" -ForegroundColor Gray
Write-Host "   # Create PR to trigger Atlantis policy validation" -ForegroundColor Gray
