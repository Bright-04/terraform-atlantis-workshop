# Monitoring Configuration for Terraform Atlantis Workshop

This directory contains monitoring configurations for the infrastructure provisioned in the workshop.

## Components

### LocalStack Monitoring (Current)

-   **Health Checks**: LocalStack endpoint health monitoring
-   **Resource Monitoring**: Track created resources in LocalStack
-   **Deployment Status**: Monitor Terraform deployment success/failure
-   **Cost Simulation**: Simulate AWS cost monitoring without actual charges

### AWS Production Monitoring (Future)

-   **CloudWatch Integration**: Metrics and logs collection
-   **Cost Monitoring**: AWS Cost Explorer integration
-   **Alert Management**: CloudWatch alarms and SNS notifications
-   **Performance Monitoring**: Application and infrastructure metrics

## Current Implementation

### LocalStack Health Check

```bash
# Check LocalStack health
curl -s http://localhost:4566/_localstack/health | jq .

# Monitor specific services
curl -s http://localhost:4566/_localstack/health | jq '.services'
```

### Infrastructure Monitoring

```powershell
# Monitor deployed resources
cd terraform
terraform show -json | jq '.values.root_module.resources[] | {type: .type, name: .values.tags.Name}'
```

### Deployment Monitoring

```bash
# Monitor Atlantis operations
docker-compose logs atlantis --tail=50

# Check LocalStack operations
docker-compose logs localstack --tail=50
```

## Monitoring Scripts

Run monitoring checks:

```powershell
.\monitoring\health-check.ps1
```

Generate monitoring report:

```powershell
.\monitoring\monitoring-report.ps1
```

## Integration with Atlantis

The monitoring system integrates with Atlantis through:

1. **Pre-deployment checks**: Verify LocalStack health before applying changes
2. **Post-deployment validation**: Confirm resources are created successfully
3. **Rollback monitoring**: Track rollback operations and success rates
4. **Cost tracking**: Monitor simulated costs in LocalStack environment

## Next Steps

1. **Implement automated health checks**
2. **Add Grafana dashboard for LocalStack monitoring**
3. **Create alerting for deployment failures**
4. **Prepare CloudWatch integration for AWS transition**
