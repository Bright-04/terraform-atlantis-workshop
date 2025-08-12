# Comprehensive cleanup script for terraform-atlantis-workshop
# This script will destroy all AWS resources created during the workshop

Write-Host "🧹 Starting comprehensive cleanup of terraform-atlantis-workshop resources..." -ForegroundColor Yellow

# Function to handle errors gracefully
function Handle-Error {
    param($Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

# 1. Terminate all EC2 instances
Write-Host "🖥️  Terminating EC2 instances..." -ForegroundColor Cyan
$instances = aws ec2 describe-instances --filters "Name=tag:Project,Values=terraform-atlantis-workshop*" --query 'Reservations[].Instances[].InstanceId' --output text 2>$null
if ($instances) {
    $instanceArray = $instances.Split("`t")
    foreach ($instance in $instanceArray) {
        if ($instance.Trim()) {
            Write-Host "  Terminating instance: $instance" -ForegroundColor Gray
            aws ec2 terminate-instances --instance-ids $instance 2>$null
        }
    }
}

# 2. Delete all S3 buckets
Write-Host "🪣  Deleting S3 buckets..." -ForegroundColor Cyan
$buckets = aws s3api list-buckets --query 'Buckets[?contains(Name, `terraform-atlantis-workshop`)].Name' --output text 2>$null
if ($buckets) {
    $bucketArray = $buckets.Split("`t")
    foreach ($bucket in $bucketArray) {
        if ($bucket.Trim()) {
            Write-Host "  Deleting bucket: $bucket" -ForegroundColor Gray
            # Empty bucket first
            aws s3 rm "s3://$bucket" --recursive 2>$null
            # Delete bucket
            aws s3api delete-bucket --bucket $bucket 2>$null
        }
    }
}

# 3. Delete RDS instances
Write-Host "🗄️  Deleting RDS instances..." -ForegroundColor Cyan
$rdsInstances = aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `terraform-atlantis-workshop`)].DBInstanceIdentifier' --output text 2>$null
if ($rdsInstances) {
    $rdsArray = $rdsInstances.Split("`t")
    foreach ($rds in $rdsArray) {
        if ($rds.Trim()) {
            Write-Host "  Deleting RDS instance: $rds" -ForegroundColor Gray
            aws rds delete-db-instance --db-instance-identifier $rds --skip-final-snapshot --delete-automated-backups 2>$null
        }
    }
}

# 4. Delete security groups
Write-Host "🔒 Deleting security groups..." -ForegroundColor Cyan
$securityGroups = aws ec2 describe-security-groups --filters "Name=group-name,Values=*terraform-atlantis-workshop*" --query 'SecurityGroups[].GroupId' --output text 2>$null
if ($securityGroups) {
    $sgArray = $securityGroups.Split("`t")
    foreach ($sg in $sgArray) {
        if ($sg.Trim()) {
            Write-Host "  Deleting security group: $sg" -ForegroundColor Gray
            aws ec2 delete-security-group --group-id $sg 2>$null
        }
    }
}

# 5. Delete VPCs
Write-Host "🌐 Deleting VPCs..." -ForegroundColor Cyan
$vpcs = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*terraform-atlantis-workshop*" --query 'Vpcs[].VpcId' --output text 2>$null
if ($vpcs) {
    $vpcArray = $vpcs.Split("`t")
    foreach ($vpc in $vpcArray) {
        if ($vpc.Trim()) {
            Write-Host "  Deleting VPC: $vpc" -ForegroundColor Gray
            # Delete route tables
            $routeTables = aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text 2>$null
            if ($routeTables) {
                $rtArray = $routeTables.Split("`t")
                foreach ($rt in $rtArray) {
                    if ($rt.Trim()) {
                        aws ec2 delete-route-table --route-table-id $rt 2>$null
                    }
                }
            }
            
            # Delete subnets
            $subnets = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --query 'Subnets[].SubnetId' --output text 2>$null
            if ($subnets) {
                $subnetArray = $subnets.Split("`t")
                foreach ($subnet in $subnetArray) {
                    if ($subnet.Trim()) {
                        aws ec2 delete-subnet --subnet-id $subnet 2>$null
                    }
                }
            }
            
            # Delete internet gateways
            $igws = aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId' --output text 2>$null
            if ($igws) {
                $igwArray = $igws.Split("`t")
                foreach ($igw in $igwArray) {
                    if ($igw.Trim()) {
                        aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc 2>$null
                        aws ec2 delete-internet-gateway --internet-gateway-id $igw 2>$null
                    }
                }
            }
            
            # Delete VPC
            aws ec2 delete-vpc --vpc-id $vpc 2>$null
        }
    }
}

# 6. Delete IAM roles and policies
Write-Host "👤 Deleting IAM roles and policies..." -ForegroundColor Cyan
$roles = aws iam list-roles --query 'Roles[?contains(RoleName, `terraform-atlantis-workshop`)].RoleName' --output text 2>$null
if ($roles) {
    $roleArray = $roles.Split("`t")
    foreach ($role in $roleArray) {
        if ($role.Trim()) {
            Write-Host "  Deleting IAM role: $role" -ForegroundColor Gray
            # Detach policies
            $policies = aws iam list-attached-role-policies --role-name $role --query 'AttachedPolicies[].PolicyArn' --output text 2>$null
            if ($policies) {
                $policyArray = $policies.Split("`t")
                foreach ($policy in $policyArray) {
                    if ($policy.Trim()) {
                        aws iam detach-role-policy --role-name $role --policy-arn $policy 2>$null
                    }
                }
            }
            
            # Delete inline policies
            $inlinePolicies = aws iam list-role-policies --role-name $role --query 'PolicyNames' --output text 2>$null
            if ($inlinePolicies) {
                $inlineArray = $inlinePolicies.Split("`t")
                foreach ($inline in $inlineArray) {
                    if ($inline.Trim()) {
                        aws iam delete-role-policy --role-name $role --policy-name $inline 2>$null
                    }
                }
            }
            
            # Delete role
            aws iam delete-role --role-name $role 2>$null
        }
    }
}

# 7. Delete IAM instance profiles
Write-Host "👤 Deleting IAM instance profiles..." -ForegroundColor Cyan
$profiles = aws iam list-instance-profiles --query 'InstanceProfiles[?contains(InstanceProfileName, `terraform-atlantis-workshop`)].InstanceProfileName' --output text 2>$null
if ($profiles) {
    $profileArray = $profiles.Split("`t")
    foreach ($profile in $profileArray) {
        if ($profile.Trim()) {
            Write-Host "  Deleting instance profile: $profile" -ForegroundColor Gray
            aws iam delete-instance-profile --instance-profile-name $profile 2>$null
        }
    }
}

# 8. Delete CloudWatch log groups
Write-Host "📊 Deleting CloudWatch log groups..." -ForegroundColor Cyan
$logGroups = aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/terraform-atlantis-workshop" --query 'logGroups[].logGroupName' --output text 2>$null
if ($logGroups) {
    $lgArray = $logGroups.Split("`t")
    foreach ($lg in $lgArray) {
        if ($lg.Trim()) {
            Write-Host "  Deleting log group: $lg" -ForegroundColor Gray
            aws logs delete-log-group --log-group-name $lg 2>$null
        }
    }
}

# 9. Delete RDS subnet groups
Write-Host "🗄️  Deleting RDS subnet groups..." -ForegroundColor Cyan
$subnetGroups = aws rds describe-db-subnet-groups --query 'DBSubnetGroups[?contains(DBSubnetGroupName, `terraform-atlantis-workshop`)].DBSubnetGroupName' --output text 2>$null
if ($subnetGroups) {
    $sgArray = $subnetGroups.Split("`t")
    foreach ($sg in $sgArray) {
        if ($sg.Trim()) {
            Write-Host "  Deleting subnet group: $sg" -ForegroundColor Gray
            aws rds delete-db-subnet-group --db-subnet-group-name $sg 2>$null
        }
    }
}

# 10. Delete RDS parameter groups
Write-Host "🗄️  Deleting RDS parameter groups..." -ForegroundColor Cyan
$paramGroups = aws rds describe-db-parameter-groups --query 'DBParameterGroups[?contains(DBParameterGroupName, `terraform-atlantis-workshop`)].DBParameterGroupName' --output text 2>$null
if ($paramGroups) {
    $pgArray = $paramGroups.Split("`t")
    foreach ($pg in $pgArray) {
        if ($pg.Trim()) {
            Write-Host "  Deleting parameter group: $pg" -ForegroundColor Gray
            aws rds delete-db-parameter-group --db-parameter-group-name $pg 2>$null
        }
    }
}

Write-Host "✅ Cleanup completed!" -ForegroundColor Green
Write-Host "📋 Summary of actions taken:" -ForegroundColor Cyan
Write-Host "  - EC2 instances terminated" -ForegroundColor Gray
Write-Host "  - S3 buckets deleted" -ForegroundColor Gray
Write-Host "  - RDS instances deleted" -ForegroundColor Gray
Write-Host "  - Security groups deleted" -ForegroundColor Gray
Write-Host "  - VPCs and networking deleted" -ForegroundColor Gray
Write-Host "  - IAM roles and policies deleted" -ForegroundColor Gray
Write-Host "  - CloudWatch log groups deleted" -ForegroundColor Gray
Write-Host "  - RDS subnet and parameter groups deleted" -ForegroundColor Gray

Write-Host "🎯 Workshop is now in a clean state!" -ForegroundColor Green
