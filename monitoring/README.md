# Monitoring Configuration for Terraform Atlantis Workshop

This directory contains monitoring configurations for the AWS production infrastructure provisioned in the workshop.

## Components

### AWS Production Monitoring (Current)

-   **CloudWatch Integration**: Metrics and logs collection
-   **Cost Monitoring**: AWS Cost Explorer integration
-   **Alert Management**: CloudWatch alarms and SNS notifications
-   **Performance Monitoring**: Application and infrastructure metrics
-   **Health Checks**: AWS infrastructure health monitoring
-   **Resource Monitoring**: Track created resources in AWS
-   **Deployment Status**: Monitor Terraform deployment success/failure

## Current Implementation

### AWS Health Check

```bash
# Check AWS credentials and region
aws sts get-caller-identity

# Check AWS region
aws configure get region
```

### Infrastructure Monitoring

```powershell
# Monitor deployed resources
cd terraform
terraform show -json | jq '.values.root_module.resources[] | {type: .type, name: .values.tags.Name}'

# Check AWS resources directly
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,Tags[?Key==`Name`].Value|[0]]' --output table
```

### Deployment Monitoring

```bash
# Monitor Atlantis operations
docker-compose logs atlantis --tail=50

# Check AWS CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/terraform-atlantis-workshop"
```

## Monitoring Scripts

Run AWS health checks:

```powershell
.\monitoring\health-check-aws.ps1
```

Generate monitoring report:

```powershell
.\monitoring\monitoring-report.ps1
```

## Integration with Atlantis

The monitoring system integrates with Atlantis through:

1. **Pre-deployment checks**: Verify AWS credentials and region before applying changes
2. **Post-deployment validation**: Confirm resources are created successfully in AWS
3. **Rollback monitoring**: Track rollback operations and success rates
4. **Cost tracking**: Monitor actual AWS costs through Cost Explorer

## AWS Production Features

### CloudWatch Integration
- Application logs collection
- Infrastructure metrics
- Custom dashboards
- Automated alerting

### Cost Monitoring
- Real-time cost tracking
- Budget alerts
- Cost optimization recommendations
- Resource tagging compliance

### Security Monitoring
- IAM access monitoring
- Security group changes
- S3 bucket access logs
- CloudTrail integration

## Next Steps

1. **Implement automated health checks**
2. **Add CloudWatch dashboards for AWS monitoring**
3. **Create alerting for deployment failures**
4. **Set up SNS notifications for critical events**
5. **Implement cost optimization alerts**
