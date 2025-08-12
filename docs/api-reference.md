# API Reference - Terraform Atlantis Workshop

## 🔌 Technical Reference Documentation

This document provides comprehensive API reference information for the **Environment Provisioning Automation with Terraform and Atlantis** workshop, including Atlantis API, AWS APIs used, and custom webhook endpoints.

## 🏗️ Atlantis API Reference

### Core Endpoints

#### Health Check

```http
GET /healthz
Host: localhost:4141
```

**Response:**

```json
{
	"status": "ok"
}
```

**Description:** Returns the health status of the Atlantis server.

#### Webhook Events

```http
POST /events
Host: localhost:4141
Content-Type: application/json
X-GitHub-Event: pull_request
X-Hub-Signature-256: sha256=...
```

**Request Body (Pull Request):**

```json
{
	"action": "opened",
	"number": 123,
	"pull_request": {
		"id": 456789,
		"number": 123,
		"state": "open",
		"title": "Update infrastructure configuration",
		"head": {
			"ref": "feature/update-config",
			"sha": "abc123def456"
		},
		"base": {
			"ref": "main",
			"sha": "def456abc123"
		}
	},
	"repository": {
		"name": "terraform-atlantis-workshop",
		"full_name": "Bright-04/terraform-atlantis-workshop",
		"clone_url": "https://github.com/Bright-04/terraform-atlantis-workshop.git"
	}
}
```

#### Plan Status

```http
GET /api/plans/{project}/{workspace}
Host: localhost:4141
Authorization: Bearer <api-token>
```

**Response:**

```json
{
	"project": "terraform-atlantis-workshop",
	"workspace": "default",
	"status": "success",
	"plan_summary": {
		"add": 3,
		"change": 1,
		"destroy": 0
	},
	"apply_lock": false,
	"created_at": "2025-08-12T10:30:00Z"
}
```

#### Apply Status

```http
GET /api/applies/{project}/{workspace}
Host: localhost:4141
Authorization: Bearer <api-token>
```

**Response:**

```json
{
	"project": "terraform-atlantis-workshop",
	"workspace": "default",
	"status": "success",
	"apply_summary": {
		"add": 3,
		"change": 1,
		"destroy": 0
	},
	"completed_at": "2025-08-12T10:35:00Z"
}
```

### Atlantis Commands API

#### Plan Command

```http
POST /api/plan
Host: localhost:4141
Content-Type: application/json
Authorization: Bearer <api-token>
```

**Request Body:**

```json
{
	"repository": "Bright-04/terraform-atlantis-workshop",
	"project": "terraform-atlantis-workshop",
	"workspace": "default",
	"directory": "terraform",
	"flags": ["-var-file=production.tfvars"]
}
```

#### Apply Command

```http
POST /api/apply
Host: localhost:4141
Content-Type: application/json
Authorization: Bearer <api-token>
```

**Request Body:**

```json
{
	"repository": "Bright-04/terraform-atlantis-workshop",
	"project": "terraform-atlantis-workshop",
	"workspace": "default",
	"auto_merge": false
}
```

### Atlantis Configuration API

#### Get Configuration

```http
GET /api/config
Host: localhost:4141
Authorization: Bearer <api-token>
```

**Response:**

```json
{
	"atlantis_version": "v0.27.0",
	"projects": [
		{
			"name": "terraform-atlantis-workshop",
			"dir": "terraform",
			"workspace": "default",
			"terraform_version": "v1.6.0",
			"autoplan": {
				"when_modified": ["*.tf", "../.github/workflows/*.yml"],
				"enabled": true
			},
			"apply_requirements": ["approved", "mergeable"]
		}
	]
}
```

## 🔄 GitHub Webhook API

### Webhook Configuration

#### Repository Webhook

```http
POST /repos/{owner}/{repo}/hooks
Host: api.github.com
Authorization: token <github-token>
Content-Type: application/json
```

**Request Body:**

```json
{
	"name": "web",
	"active": true,
	"events": ["pull_request", "issue_comment", "pull_request_review", "push"],
	"config": {
		"url": "https://your-atlantis-server.com/events",
		"content_type": "json",
		"secret": "your-webhook-secret",
		"insecure_ssl": "0"
	}
}
```

#### Webhook Events

**Pull Request Event:**

```json
{
	"action": "opened|closed|synchronize",
	"number": 123,
	"pull_request": {
		"state": "open",
		"mergeable": true,
		"mergeable_state": "clean"
	}
}
```

**Issue Comment Event:**

```json
{
	"action": "created",
	"issue": {
		"number": 123,
		"pull_request": {}
	},
	"comment": {
		"body": "atlantis plan"
	}
}
```

## ☁️ AWS API Integration

### EC2 API Calls

#### Describe Instances

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Workshop,Values=terraform-atlantis" \
  --query "Reservations[].Instances[].[InstanceId,State.Name,InstanceType]" \
  --output table
```

**Response Format:**

```
---------------------------------
|        DescribeInstances      |
+---------------+-------+-------+
|  i-0123456789abcdef0 | running | t3.micro |
|  i-0987654321fedcba0 | running | t3.micro |
+---------------+-------+-------+
```

#### Create Instance

```bash
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t3.micro \
  --key-name workshop-key \
  --security-group-ids sg-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Workshop,Value=terraform-atlantis},{Key=Environment,Value=production}]'
```

### CloudWatch API Calls

#### Get Metric Statistics

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef0 \
  --start-time 2025-08-12T09:00:00Z \
  --end-time 2025-08-12T10:00:00Z \
  --period 300 \
  --statistics Average,Maximum
```

**Response:**

```json
{
	"Label": "CPUUtilization",
	"Datapoints": [
		{
			"Timestamp": "2025-08-12T09:00:00Z",
			"Average": 15.2,
			"Maximum": 23.1,
			"Unit": "Percent"
		}
	]
}
```

#### Create Alarm

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "workshop-high-cpu" \
  --alarm-description "High CPU utilization alarm" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef0 \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-west-2:123456789012:workshop-alerts
```

### Cost Explorer API

#### Get Cost and Usage

```bash
aws ce get-cost-and-usage \
  --time-period Start=2025-08-01,End=2025-08-12 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

**Response:**

```json
{
	"GroupDefinitions": [
		{
			"Type": "DIMENSION",
			"Key": "SERVICE"
		}
	],
	"ResultsByTime": [
		{
			"TimePeriod": {
				"Start": "2025-08-01",
				"End": "2025-08-02"
			},
			"Total": {},
			"Groups": [
				{
					"Keys": ["Amazon Elastic Compute Cloud - Compute"],
					"Metrics": {
						"BlendedCost": {
							"Amount": "1.23",
							"Unit": "USD"
						}
					}
				}
			]
		}
	]
}
```

## 🐳 Docker API Integration

### Docker Compose API

#### Service Status

```bash
docker-compose ps
```

**Response:**

```
       Name                     Command               State           Ports
-----------------------------------------------------------------------------------
atlantis_atlantis_1   atlantis server --atlantis...   Up      0.0.0.0:4141->4141/tcp
```

#### Service Logs

```bash
docker-compose logs atlantis
```

### Container API

#### Container Information

```bash
docker inspect atlantis_atlantis_1
```

**Response (excerpt):**

```json
{
	"Id": "abc123def456...",
	"State": {
		"Status": "running",
		"Running": true,
		"Paused": false,
		"Restarting": false,
		"StartedAt": "2025-08-12T08:00:00.000000000Z"
	},
	"Config": {
		"Image": "runatlantis/atlantis:latest",
		"Env": ["ATLANTIS_GITHUB_TOKEN=***", "ATLANTIS_GITHUB_WEBHOOK_SECRET=***"]
	}
}
```

## 🔧 Custom Workshop APIs

### Health Check Endpoint

#### Workshop Health API

```powershell
# Custom PowerShell API endpoint
function Get-WorkshopHealth {
    [CmdletBinding()]
    param()

    $health = @{
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        status = 'healthy'
        components = @{
            terraform = @{
                status = 'ok'
                version = (terraform version -json | ConvertFrom-Json).terraform_version
            }
            atlantis = @{
                status = 'ok'
                endpoint = 'http://localhost:4141'
            }
            aws = @{
                status = 'ok'
                region = (aws configure get region)
                account = (aws sts get-caller-identity --query Account --output text)
            }
        }
    }

    return $health | ConvertTo-Json -Depth 3
}
```

### Cost Monitoring API

#### Current Cost Endpoint

```powershell
function Get-CurrentCost {
    [CmdletBinding()]
    param(
        [string]$StartDate = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd'),
        [string]$EndDate = (Get-Date).ToString('yyyy-MM-dd')
    )

    $costData = aws ce get-cost-and-usage `
        --time-period Start=$StartDate,End=$EndDate `
        --granularity DAILY `
        --metrics BlendedCost `
        --group-by Type=DIMENSION,Key=SERVICE | ConvertFrom-Json

    $result = @{
        period = @{
            start = $StartDate
            end = $EndDate
        }
        total_cost = $costData.ResultsByTime[0].Total.BlendedCost.Amount
        currency = $costData.ResultsByTime[0].Total.BlendedCost.Unit
        services = @()
    }

    foreach ($group in $costData.ResultsByTime[0].Groups) {
        $result.services += @{
            name = $group.Keys[0]
            cost = $group.Metrics.BlendedCost.Amount
        }
    }

    return $result | ConvertTo-Json -Depth 3
}
```

### Resource Status API

#### Infrastructure Status

```powershell
function Get-InfrastructureStatus {
    [CmdletBinding()]
    param()

    # Get EC2 instances
    $instances = aws ec2 describe-instances `
        --filters "Name=tag:Workshop,Values=terraform-atlantis" `
        --query "Reservations[].Instances[].[InstanceId,State.Name,InstanceType,PublicIpAddress]" `
        --output json | ConvertFrom-Json

    # Get security groups
    $securityGroups = aws ec2 describe-security-groups `
        --filters "Name=tag:Workshop,Values=terraform-atlantis" `
        --query "SecurityGroups[].[GroupId,GroupName]" `
        --output json | ConvertFrom-Json

    # Get load balancers
    $loadBalancers = aws elbv2 describe-load-balancers `
        --query "LoadBalancers[].[LoadBalancerName,State.Code,DNSName]" `
        --output json | ConvertFrom-Json

    $status = @{
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        infrastructure = @{
            ec2_instances = @{
                count = $instances.Count
                running = ($instances | Where-Object { $_[1] -eq 'running' }).Count
                stopped = ($instances | Where-Object { $_[1] -eq 'stopped' }).Count
                instances = $instances | ForEach-Object {
                    @{
                        id = $_[0]
                        state = $_[1]
                        type = $_[2]
                        public_ip = $_[3]
                    }
                }
            }
            security_groups = @{
                count = $securityGroups.Count
                groups = $securityGroups | ForEach-Object {
                    @{
                        id = $_[0]
                        name = $_[1]
                    }
                }
            }
            load_balancers = @{
                count = $loadBalancers.Count
                balancers = $loadBalancers | ForEach-Object {
                    @{
                        name = $_[0]
                        state = $_[1]
                        dns_name = $_[2]
                    }
                }
            }
        }
    }

    return $status | ConvertTo-Json -Depth 4
}
```

## 📊 Monitoring API Integration

### CloudWatch Logs API

#### Query Logs

```bash
aws logs filter-log-events \
  --log-group-name /aws/ec2/workshop \
  --start-time 1691827200000 \
  --filter-pattern "ERROR"
```

#### Create Log Stream

```bash
aws logs create-log-stream \
  --log-group-name /aws/ec2/workshop \
  --log-stream-name "workshop-$(date +%Y%m%d)"
```

### SNS API Integration

#### Publish Alert

```bash
aws sns publish \
  --topic-arn arn:aws:sns:us-west-2:123456789012:workshop-alerts \
  --message "Workshop infrastructure alert: High CPU utilization detected" \
  --subject "Workshop Alert"
```

#### Create Topic

```bash
aws sns create-topic --name workshop-alerts
```

## 🔐 Authentication & Authorization

### Atlantis API Authentication

#### API Token Configuration

```yaml
# atlantis.yaml
version: 3
api:
    token: "your-api-token-here"
    cors_origins: ["https://your-domain.com"]
```

#### Using API Token

```bash
curl -H "Authorization: Bearer your-api-token" \
     http://localhost:4141/api/config
```

### AWS API Authentication

#### IAM Policy for Workshop

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ec2:*",
				"iam:*",
				"s3:*",
				"cloudwatch:*",
				"logs:*",
				"ce:GetCostAndUsage",
				"ce:GetDimensionValues",
				"ce:GetReservationCoverage",
				"ce:GetReservationPurchaseRecommendation",
				"ce:GetReservationUtilization",
				"ce:GetRightsizingRecommendation",
				"ce:GetUsageReport"
			],
			"Resource": "*"
		}
	]
}
```

#### AWS CLI Configuration

```bash
aws configure set aws_access_key_id YOUR_ACCESS_KEY
aws configure set aws_secret_access_key YOUR_SECRET_KEY
aws configure set default.region us-west-2
```

## 📈 API Response Codes

### Standard HTTP Codes

| Code | Status                | Description                     |
| ---- | --------------------- | ------------------------------- |
| 200  | OK                    | Request successful              |
| 201  | Created               | Resource created successfully   |
| 400  | Bad Request           | Invalid request parameters      |
| 401  | Unauthorized          | Authentication required         |
| 403  | Forbidden             | Insufficient permissions        |
| 404  | Not Found             | Resource not found              |
| 500  | Internal Server Error | Server error                    |
| 503  | Service Unavailable   | Service temporarily unavailable |

### Atlantis-Specific Codes

| Code | Status               | Description                          |
| ---- | -------------------- | ------------------------------------ |
| 409  | Conflict             | Plan/Apply already in progress       |
| 422  | Unprocessable Entity | Invalid Terraform configuration      |
| 423  | Locked               | Resource locked by another operation |

### AWS API Error Codes

| Code                       | Error | Description                  |
| -------------------------- | ----- | ---------------------------- |
| InvalidInstanceId.NotFound | 400   | EC2 instance not found       |
| UnauthorizedOperation      | 403   | Insufficient IAM permissions |
| ResourceLimitExceeded      | 400   | AWS service limit exceeded   |
| ThrottlingException        | 400   | API rate limit exceeded      |

## 🔧 Error Handling

### Atlantis Error Responses

```json
{
	"error": "plan failed",
	"details": "terraform plan execution failed",
	"code": "PLAN_FAILED",
	"timestamp": "2025-08-12T10:30:00Z"
}
```

### AWS Error Responses

```json
{
	"Error": {
		"Code": "InvalidInstanceId.NotFound",
		"Message": "The instance ID 'i-1234567890abcdef0' does not exist"
	},
	"RequestId": "12345678-1234-1234-1234-123456789012"
}
```

## 📝 API Testing

### Testing Atlantis API

```bash
# Health check
curl -f http://localhost:4141/healthz

# Test webhook
curl -X POST http://localhost:4141/events \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: ping" \
  -d '{"zen":"Non-blocking is better than blocking."}'
```

### Testing AWS API

```bash
# Test connectivity
aws sts get-caller-identity

# Test permissions
aws ec2 describe-instances --dry-run

# Test specific service
aws s3 ls
```

---

**📚 Additional Resources:**

-   [Atlantis API Documentation](https://www.runatlantis.io/docs/server-configuration.html#api)
-   [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/reference/)
-   [GitHub API Documentation](https://docs.github.com/en/rest)
-   [Docker API Documentation](https://docs.docker.com/engine/api/)

**Last Updated**: August 2025  
**Version**: 1.0  
**Author**: Nguyen Nhat Quang (Bright-04)
