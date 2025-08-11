# =============================================================================
# 04 - Health Monitoring Script
# =============================================================================
# This script monitors the health and status of deployed AWS infrastructure
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
    [string]$Region = "ap-southeast-1",
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed = $false
)

# Function to check AWS credentials
function Test-AWSCredentials {
    Write-Host "Step 4: AWS Health Monitoring" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Gray
    
    Write-Host "Checking AWS credentials..." -ForegroundColor Yellow
    
    try {
        $identity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
        if ($identity) {
            Write-Host "   AWS Account: $($identity.Account)" -ForegroundColor Green
            Write-Host "   User ARN: $($identity.Arn)" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "   AWS credentials not configured" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "   AWS credentials not configured" -ForegroundColor Red
        return $false
    }
}

# Function to check AWS region
function Test-AWSRegion {
    param([string]$Region)
    
    Write-Host "Checking AWS region..." -ForegroundColor Yellow
    
    try {
        $currentRegion = aws configure get region 2>$null
        if ($currentRegion -eq $Region) {
            Write-Host "   Region: $Region" -ForegroundColor Green
            return $Region
        }
        else {
            Write-Host "   Current region: $currentRegion" -ForegroundColor Yellow
            Write-Host "   Using specified region: $Region" -ForegroundColor Yellow
            return $Region
        }
    }
    catch {
        Write-Host "   Using default region: $Region" -ForegroundColor Yellow
        return $Region
    }
}

# Function to check EC2 instances
function Test-EC2Instances {
    param([string]$Region)
    
    Write-Host "EC2 Instances Status:" -ForegroundColor Yellow
    
    try {
        $instances = aws ec2 describe-instances --region $Region --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' --output json 2>$null | ConvertFrom-Json
        
        if ($instances -and $instances.Count -gt 0) {
            Write-Host "   Found $($instances.Count) running instances:" -ForegroundColor Gray
            
            foreach ($instance in $instances) {
                $instanceId = $instance[0]
                $instanceType = $instance[1]
                $state = $instance[2]
                $publicIp = $instance[3]
                $name = $instance[4]
                
                Write-Host "   Instance: $instanceId ($instanceType)" -ForegroundColor Green
                Write-Host "      Name: $name" -ForegroundColor Gray
                Write-Host "      State: $state" -ForegroundColor Gray
                Write-Host "      Public IP: $publicIp" -ForegroundColor Gray
            }
            
            return $true
        }
        else {
            Write-Host "   No running instances found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "   Could not retrieve EC2 instances: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check VPC networking
function Test-VPCNetworking {
    param([string]$Region)
    
    Write-Host "VPC Networking Status:" -ForegroundColor Yellow
    
    try {
        $vpcs = aws ec2 describe-vpcs --region $Region --query 'Vpcs[*].[VpcId,CidrBlock,State,Tags[?Key==`Name`].Value|[0]]' --output json 2>$null | ConvertFrom-Json
        
        if ($vpcs -and $vpcs.Count -gt 0) {
            Write-Host "   Found $($vpcs.Count) VPCs:" -ForegroundColor Gray
            
            foreach ($vpc in $vpcs) {
                $vpcId = $vpc[0]
                $cidr = $vpc[1]
                $state = $vpc[2]
                $name = $vpc[3]
                
                Write-Host "   VPC: $vpcId" -ForegroundColor Green
                Write-Host "      Name: $name" -ForegroundColor Gray
                Write-Host "      CIDR: $cidr" -ForegroundColor Gray
                Write-Host "      State: $state" -ForegroundColor Gray
            }
            
            return $true
        }
        else {
            Write-Host "   No VPCs found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "   Could not retrieve VPCs: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check S3 buckets
function Test-S3Buckets {
    param([string]$Region)
    
    Write-Host "S3 Buckets Status:" -ForegroundColor Yellow
    
    try {
        $bucketsOutput = aws s3 ls 2>$null
        $buckets = $bucketsOutput | ForEach-Object { $_.Split()[2] }
        
        if ($buckets -and $buckets.Count -gt 0) {
            Write-Host "   Found $($buckets.Count) S3 buckets:" -ForegroundColor Gray
            
            foreach ($bucketName in $buckets) {
                Write-Host "   Bucket: $bucketName" -ForegroundColor Green
                
                if ($Detailed) {
                    try {
                        $encryption = aws s3api get-bucket-encryption --bucket $bucketName --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text 2>$null
                        if ($encryption) {
                            Write-Host "      Encryption: $encryption" -ForegroundColor Gray
                        }
                    }
                    catch {
                        Write-Host "      Encryption: Not configured" -ForegroundColor Yellow
                    }
                }
            }
            
            return $true
        }
        else {
            Write-Host "   No S3 buckets found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "   Could not retrieve S3 buckets: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check CloudWatch logs
function Test-CloudWatchLogs {
    param([string]$Region)
    
    Write-Host "CloudWatch Logs Status:" -ForegroundColor Yellow
    
    try {
        $logGroups = aws logs describe-log-groups --region $Region --query 'logGroups[?contains(logGroupName, `terraform-atlantis-workshop`)].logGroupName' --output json 2>$null | ConvertFrom-Json
        
        if ($logGroups -and $logGroups.Count -gt 0) {
            Write-Host "   Found $($logGroups.Count) workshop log groups:" -ForegroundColor Gray
            
            foreach ($logGroup in $logGroups) {
                Write-Host "   Log Group: $logGroup" -ForegroundColor Green
            }
            
            return $true
        }
        else {
            Write-Host "   No workshop log groups found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "   Could not retrieve CloudWatch logs: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check security groups
function Test-SecurityGroups {
    param([string]$Region)
    
    Write-Host "Security Groups Status:" -ForegroundColor Yellow
    
    try {
        $securityGroups = aws ec2 describe-security-groups --region $Region --query 'SecurityGroups[?contains(GroupName, `terraform-atlantis-workshop`)].{Name:GroupName,Id:GroupId,Description:Description}' --output json 2>$null | ConvertFrom-Json
        
        if ($securityGroups -and $securityGroups.Count -gt 0) {
            Write-Host "   Found $($securityGroups.Count) workshop security groups:" -ForegroundColor Gray
            
            foreach ($sg in $securityGroups) {
                Write-Host "   Security Group: $($sg.Name) ($($sg.Id))" -ForegroundColor Green
                Write-Host "      Description: $($sg.Description)" -ForegroundColor Gray
            }
            
            return $true
        }
        else {
            Write-Host "   No workshop security groups found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "   Could not retrieve security groups: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check Terraform state
function Test-TerraformState {
    Write-Host "Terraform State Status:" -ForegroundColor Yellow
    
    if (Test-Path "terraform\terraform.tfstate") {
        try {
            Set-Location terraform
            $stateInfo = terraform show -json 2>$null | ConvertFrom-Json
            
            if ($stateInfo) {
                $resources = $stateInfo.values.root_module.resources
                Write-Host "   Terraform state found with $($resources.Count) resources" -ForegroundColor Green
                
                if ($Detailed) {
                    Write-Host "   Resources:" -ForegroundColor Gray
                    foreach ($resource in $resources) {
                        Write-Host "   - $($resource.type).$($resource.name)" -ForegroundColor Gray
                    }
                }
            }
            else {
                Write-Host "   Terraform state is empty" -ForegroundColor Yellow
            }
            
            Set-Location ..
            return $true
        }
        catch {
            Set-Location ..
            Write-Host "   Could not read Terraform state: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "   No Terraform state file found" -ForegroundColor Yellow
        return $false
    }
}

# Function to check compliance validation
function Test-ComplianceValidation {
    Write-Host "Compliance Validation Status:" -ForegroundColor Yellow
    
    if (Test-Path "terraform\terraform.tfstate") {
        try {
            Set-Location terraform
            
            $complianceOutput = terraform output -json compliance_validation_status 2>$null | ConvertFrom-Json
            
            if ($complianceOutput) {
                Write-Host "   Compliance validation active" -ForegroundColor Green
                Write-Host "   Total instances: $($complianceOutput.total_instances)" -ForegroundColor Gray
                Write-Host "   Total buckets: $($complianceOutput.total_buckets)" -ForegroundColor Gray
                Write-Host "   Message: $($complianceOutput.message)" -ForegroundColor Gray
            }
            else {
                Write-Host "   Compliance validation not configured" -ForegroundColor Yellow
            }
            
            Set-Location ..
            return $true
        }
        catch {
            Set-Location ..
            Write-Host "   Could not check compliance validation: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "   No Terraform state to check compliance" -ForegroundColor Yellow
        return $false
    }
}

# Function to test web server accessibility
function Test-WebServerAccess {
    param([string]$Region)
    
    Write-Host "Web Server Accessibility Test:" -ForegroundColor Yellow
    
    try {
        $webInstance = aws ec2 describe-instances --region $Region --filters "Name=tag:Name,Values=*web-server*" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].PublicIpAddress' --output text 2>$null
        
        if ($webInstance) {
            Write-Host "   Web server public IP: $webInstance" -ForegroundColor Gray
            
            try {
                $response = Invoke-WebRequest -Uri "http://$webInstance" -TimeoutSec 10 -UseBasicParsing
                if ($response.StatusCode -eq 200) {
                    Write-Host "   Web server is accessible (HTTP 200)" -ForegroundColor Green
                    return $true
                }
                else {
                    Write-Host "   Web server responded with status: $($response.StatusCode)" -ForegroundColor Yellow
                    return $false
                }
            }
            catch {
                Write-Host "   Web server is not accessible: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
        else {
            Write-Host "   No web server instance found" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "   Could not test web server access: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Host "AWS Production Health Check" -ForegroundColor Magenta

# Check AWS credentials
$credentialsValid = Test-AWSCredentials
if (-not $credentialsValid) {
    Write-Host "Cannot proceed without valid AWS credentials" -ForegroundColor Red
    exit 1
}

# Check AWS region
$region = Test-AWSRegion -Region $Region
if (-not $region) {
    Write-Host "Cannot proceed without valid AWS region" -ForegroundColor Red
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
Write-Host "Health Summary:" -ForegroundColor Magenta
$healthyCount = ($checks.Values | Where-Object { $_ }).Count
$totalCount = $checks.Count

Write-Host "   Healthy Components: $healthyCount/$totalCount" -ForegroundColor $(if ($healthyCount -eq $totalCount) { "Green" } else { "Yellow" })

foreach ($check in $checks.GetEnumerator()) {
    $status = if ($check.Value) { "OK" } else { "FAIL" }
    Write-Host "   $status $($check.Key)" -ForegroundColor $(if ($check.Value) { "Green" } else { "Red" })
}

if ($healthyCount -eq $totalCount) {
    Write-Host "All AWS infrastructure components are healthy!" -ForegroundColor Green
}
else {
    Write-Host "Some components need attention. Review the details above." -ForegroundColor Yellow
}

Write-Host "AWS Console Links:" -ForegroundColor Cyan
Write-Host "   - EC2 Dashboard: https://console.aws.amazon.com/ec2/v2/home?region=$region" -ForegroundColor Gray
Write-Host "   - VPC Dashboard: https://console.aws.amazon.com/vpc/home?region=$region" -ForegroundColor Gray
Write-Host "   - S3 Console: https://console.aws.amazon.com/s3/home" -ForegroundColor Gray
Write-Host "   - CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=$region" -ForegroundColor Gray

Write-Host "AWS Production Health Check Completed!" -ForegroundColor Green
