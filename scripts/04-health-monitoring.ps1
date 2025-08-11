# =============================================================================
# 04 - AWS Production Health Monitoring Script
# =============================================================================
# Monitors real AWS infrastructure health and status
# 
# Workflow Order:
# 1. 01-validate-environment.ps1
# 2. 02-setup-github-actions.ps1
# 3. 03-deploy-infrastructure.ps1
# 4. 04-health-monitoring.ps1 (this script)
# 5. 05-cost-monitoring.ps1
# 6. 06-rollback-procedures.ps1
# 7. 07-cleanup-infrastructure.ps1
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed = $false
)

Write-Host "🔍 Step 4: AWS Production Infrastructure - Health Check" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Gray

# Function to check AWS credentials
function Test-AWSCredentials {
    try {
        $caller = aws sts get-caller-identity 2>$null | ConvertFrom-Json
        if ($caller) {
            Write-Host "✅ AWS Credentials Valid" -ForegroundColor Green
            Write-Host "   Account ID: $($caller.Account)" -ForegroundColor Gray
            Write-Host "   User ARN: $($caller.Arn)" -ForegroundColor Gray
            return $true
        }
    }
    catch {
        Write-Host "❌ AWS Credentials Invalid" -ForegroundColor Red
        return $false
    }
}

# Function to check AWS region
function Test-AWSRegion {
    param([string]$Region)
    
    if ([string]::IsNullOrEmpty($Region)) {
        $Region = aws configure get region 2>$null
    }
    
    if ($Region) {
        Write-Host "✅ AWS Region: $Region" -ForegroundColor Green
        return $Region
    }
    else {
        Write-Host "❌ AWS Region not configured" -ForegroundColor Red
        return $null
    }
}

# Function to check EC2 instances
function Test-EC2Instances {
    param([string]$Region)
    
    Write-Host "`n🖥️ EC2 Instances Status:" -ForegroundColor Yellow
    
    try {
        $instances = aws ec2 describe-instances --region $Region --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType,Tags[?Key==`Name`].Value|[0],PublicIpAddress]' --output json 2>$null | ConvertFrom-Json
        
        if ($instances -and $instances.Count -gt 0) {
            Write-Host "   Found $($instances.Count) instances:" -ForegroundColor Gray
            
            foreach ($instance in $instances) {
                $instanceId = $instance[0]
                $state = $instance[1]
                $type = $instance[2]
                $name = $instance[3]
                $publicIp = $instance[4]
                
                $statusIcon = if ($state -eq "running") { "✅" } else { "❌" }
                Write-Host "   $statusIcon $instanceId ($type) - $state" -ForegroundColor $(if ($state -eq "running") { "Green" } else { "Red" })
                Write-Host "      Name: $name" -ForegroundColor Gray
                if ($publicIp) {
                    Write-Host "      Public IP: $publicIp" -ForegroundColor Gray
                }
            }
            
            return $true
        }
        else {
            Write-Host "   ⚠️ No EC2 instances found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "   ❌ Could not retrieve EC2 instances: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check VPC and networking
function Test-VPCNetworking {
    param([string]$Region)
    
    Write-Host "`n🌐 VPC and Networking Status:" -ForegroundColor Yellow
    
    try {
        # Check VPCs
        $vpcs = aws ec2 describe-vpcs --region $Region --query 'Vpcs[].[VpcId,CidrBlock,State,Tags[?Key==`Name`].Value|[0]]' --output json 2>$null | ConvertFrom-Json
        
        if ($vpcs -and $vpcs.Count -gt 0) {
            Write-Host "   VPCs:" -ForegroundColor Gray
            foreach ($vpc in $vpcs) {
                $vpcId = $vpc[0]
                $cidr = $vpc[1]
                $state = $vpc[2]
                $name = $vpc[3]
                
                $statusIcon = if ($state -eq "available") { "✅" } else { "❌" }
                Write-Host "   $statusIcon $vpcId ($cidr) - $state" -ForegroundColor $(if ($state -eq "available") { "Green" } else { "Red" })
                Write-Host "      Name: $name" -ForegroundColor Gray
            }
        }
        
        # Check subnets
        $subnets = aws ec2 describe-subnets --region $Region --query 'Subnets[].[SubnetId,CidrBlock,State,Tags[?Key==`Name`].Value|[0]]' --output json 2>$null | ConvertFrom-Json
        
        if ($subnets -and $subnets.Count -gt 0) {
            Write-Host "   Subnets:" -ForegroundColor Gray
            foreach ($subnet in $subnets) {
                $subnetId = $subnet[0]
                $cidr = $subnet[1]
                $state = $subnet[2]
                $name = $subnet[3]
                
                $statusIcon = if ($state -eq "available") { "✅" } else { "❌" }
                Write-Host "   $statusIcon $subnetId ($cidr) - $state" -ForegroundColor $(if ($state -eq "available") { "Green" } else { "Red" })
                Write-Host "      Name: $name" -ForegroundColor Gray
            }
        }
        
        return $true
    }
    catch {
        Write-Host "   ❌ Could not retrieve VPC/Networking info: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check S3 buckets
function Test-S3Buckets {
    param([string]$Region)
    
    Write-Host "`n🪣 S3 Buckets Status:" -ForegroundColor Yellow
    
    try {
        $buckets = aws s3api list-buckets --query 'Buckets[].Name' --output json 2>$null | ConvertFrom-Json
        
        if ($buckets -and $buckets.Count -gt 0) {
            Write-Host "   Found $($buckets.Count) buckets:" -ForegroundColor Gray
            
            foreach ($bucket in $buckets) {
                if ($bucket -like "*terraform-atlantis-workshop*") {
                    Write-Host "   ✅ $bucket (Workshop bucket)" -ForegroundColor Green
                    
                    # Check bucket versioning
                    try {
                        $versioning = aws s3api get-bucket-versioning --bucket $bucket --query 'Status' --output text 2>$null
                        if ($versioning -eq "Enabled") {
                            Write-Host "      Versioning: ✅ Enabled" -ForegroundColor Green
                        } else {
                            Write-Host "      Versioning: ❌ Disabled" -ForegroundColor Red
                        }
                    }
                    catch {
                        Write-Host "      Versioning: ⚠️ Could not check" -ForegroundColor Yellow
                    }
                }
                else {
                    Write-Host "   ℹ️ $bucket" -ForegroundColor Gray
                }
            }
            
            return $true
        }
        else {
            Write-Host "   ⚠️ No S3 buckets found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "   ❌ Could not retrieve S3 buckets: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check CloudWatch logs
function Test-CloudWatchLogs {
    param([string]$Region)
    
    Write-Host "`n📊 CloudWatch Logs Status:" -ForegroundColor Yellow
    
    try {
        $logGroups = aws logs describe-log-groups --region $Region --query 'logGroups[?contains(logGroupName, `terraform-atlantis-workshop`)].{Name:logGroupName,Retention:retentionInDays}' --output json 2>$null | ConvertFrom-Json
        
        if ($logGroups -and $logGroups.Count -gt 0) {
            Write-Host "   Found $($logGroups.Count) workshop log groups:" -ForegroundColor Gray
            
            foreach ($logGroup in $logGroups) {
                Write-Host "   ✅ $($logGroup.Name)" -ForegroundColor Green
                Write-Host "      Retention: $($logGroup.Retention) days" -ForegroundColor Gray
            }
            
            return $true
        }
        else {
            Write-Host "   ⚠️ No workshop log groups found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "   ❌ Could not retrieve CloudWatch logs: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check security groups
function Test-SecurityGroups {
    param([string]$Region)
    
    Write-Host "`n🔒 Security Groups Status:" -ForegroundColor Yellow
    
    try {
        $securityGroups = aws ec2 describe-security-groups --region $Region --query 'SecurityGroups[?contains(GroupName, `terraform-atlantis-workshop`)].{Name:GroupName,Id:GroupId,Description:Description}' --output json 2>$null | ConvertFrom-Json
        
        if ($securityGroups -and $securityGroups.Count -gt 0) {
            Write-Host "   Found $($securityGroups.Count) workshop security groups:" -ForegroundColor Gray
            
            foreach ($sg in $securityGroups) {
                Write-Host "   ✅ $($sg.Name) ($($sg.Id))" -ForegroundColor Green
                Write-Host "      Description: $($sg.Description)" -ForegroundColor Gray
            }
            
            return $true
        }
        else {
            Write-Host "   ⚠️ No workshop security groups found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "   ❌ Could not retrieve security groups: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check Terraform state
function Test-TerraformState {
    Write-Host "`n🏗️ Terraform State Status:" -ForegroundColor Yellow
    
    if (Test-Path "terraform\terraform.tfstate") {
        try {
            Set-Location terraform
            $stateInfo = terraform show -json 2>$null | ConvertFrom-Json
            
            if ($stateInfo) {
                $resources = $stateInfo.values.root_module.resources
                Write-Host "   ✅ Terraform state found with $($resources.Count) resources" -ForegroundColor Green
                
                if ($Detailed) {
                    Write-Host "   Resources:" -ForegroundColor Gray
                    foreach ($resource in $resources) {
                        Write-Host "   - $($resource.type).$($resource.name)" -ForegroundColor Gray
                    }
                }
            }
            else {
                Write-Host "   ⚠️ Terraform state is empty" -ForegroundColor Yellow
            }
            
            Set-Location ..
            return $true
        }
        catch {
            Set-Location ..
            Write-Host "   ❌ Could not read Terraform state: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "   ⚠️ No Terraform state file found" -ForegroundColor Yellow
        return $false
    }
}

# Function to check compliance validation
function Test-ComplianceValidation {
    Write-Host "`n🛡️ Compliance Validation Status:" -ForegroundColor Yellow
    
    if (Test-Path "terraform\terraform.tfstate") {
        try {
            Set-Location terraform
            
            # Get compliance output in JSON format
            $complianceOutput = terraform output -json compliance_validation_status 2>$null | ConvertFrom-Json
            
            if ($complianceOutput) {
                Write-Host "   ✅ Compliance validation active" -ForegroundColor Green
                Write-Host "   Total instances: $($complianceOutput.total_instances)" -ForegroundColor Gray
                Write-Host "   Total buckets: $($complianceOutput.total_buckets)" -ForegroundColor Gray
                Write-Host "   Message: $($complianceOutput.message)" -ForegroundColor Gray
                
                if ($Detailed) {
                    Write-Host "   Allowed instance types: $($complianceOutput.allowed_instance_types -join ', ')" -ForegroundColor Gray
                    Write-Host "   Required tags: $($complianceOutput.required_tags -join ', ')" -ForegroundColor Gray
                    Write-Host "   Recommended tags: $($complianceOutput.recommended_tags -join ', ')" -ForegroundColor Gray
                }
            }
            else {
                Write-Host "   ⚠️ Compliance validation not configured" -ForegroundColor Yellow
            }
            
            Set-Location ..
            return $true
        }
        catch {
            Set-Location ..
            Write-Host "   ❌ Could not check compliance validation: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "   ⚠️ No Terraform state to check compliance" -ForegroundColor Yellow
        return $false
    }
}

# Function to test web server accessibility
function Test-WebServerAccess {
    param([string]$Region)
    
    Write-Host "`n🌐 Web Server Accessibility Test:" -ForegroundColor Yellow
    
    try {
        # Get public IP of web server
        $webInstance = aws ec2 describe-instances --region $Region --filters "Name=tag:Name,Values=*web-server*" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].PublicIpAddress' --output text 2>$null
        
        if ($webInstance) {
            Write-Host "   Web server public IP: $webInstance" -ForegroundColor Gray
            
            # Test HTTP connectivity
            try {
                $response = Invoke-WebRequest -Uri "http://$webInstance" -TimeoutSec 10 -UseBasicParsing
                if ($response.StatusCode -eq 200) {
                    Write-Host "   ✅ Web server is accessible (HTTP 200)" -ForegroundColor Green
                    return $true
                }
                else {
                    Write-Host "   ⚠️ Web server responded with status: $($response.StatusCode)" -ForegroundColor Yellow
                    return $false
                }
            }
            catch {
                Write-Host "   ❌ Web server is not accessible: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
        else {
            Write-Host "   ⚠️ No web server instance found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "   ❌ Could not test web server access: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Host "`n🎯 AWS Production Health Check" -ForegroundColor Magenta

# Check AWS credentials
$credentialsValid = Test-AWSCredentials
if (-not $credentialsValid) {
    Write-Host "`n❌ Cannot proceed without valid AWS credentials" -ForegroundColor Red
    exit 1
}

# Check AWS region
$region = Test-AWSRegion -Region $Region
if (-not $region) {
    Write-Host "`n❌ Cannot proceed without valid AWS region" -ForegroundColor Red
    exit 1
}

# Run health checks
$checks = @{
    "EC2 Instances" = Test-EC2Instances -Region $region
    "VPC Networking" = Test-VPCNetworking -Region $region
    "S3 Buckets" = Test-S3Buckets -Region $region
    "CloudWatch Logs" = Test-CloudWatchLogs -Region $region
    "Security Groups" = Test-SecurityGroups -Region $region
    "Terraform State" = Test-TerraformState
    "Compliance Validation" = Test-ComplianceValidation
    "Web Server Access" = Test-WebServerAccess -Region $region
}

# Summary
Write-Host "`n📊 Health Summary:" -ForegroundColor Magenta
$healthyCount = ($checks.Values | Where-Object { $_ }).Count
$totalCount = $checks.Count

Write-Host "   Healthy Components: $healthyCount/$totalCount" -ForegroundColor $(if ($healthyCount -eq $totalCount) { "Green" } else { "Yellow" })

foreach ($check in $checks.GetEnumerator()) {
    $status = if ($check.Value) { "✅" } else { "❌" }
    Write-Host "   $status $($check.Key)" -ForegroundColor $(if ($check.Value) { "Green" } else { "Red" })
}

if ($healthyCount -eq $totalCount) {
    Write-Host "`n🎉 All AWS infrastructure components are healthy!" -ForegroundColor Green
}
else {
    Write-Host "`n⚠️ Some components need attention. Review the details above." -ForegroundColor Yellow
}

Write-Host "`n🔗 AWS Console Links:" -ForegroundColor Cyan
Write-Host "   - EC2 Dashboard: https://console.aws.amazon.com/ec2/v2/home?region=$region" -ForegroundColor Gray
Write-Host "   - VPC Dashboard: https://console.aws.amazon.com/vpc/home?region=$region" -ForegroundColor Gray
Write-Host "   - S3 Console: https://console.aws.amazon.com/s3/home" -ForegroundColor Gray
Write-Host "   - CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=$region" -ForegroundColor Gray

Write-Host "`n✅ AWS Production Health Check Completed!" -ForegroundColor Green
