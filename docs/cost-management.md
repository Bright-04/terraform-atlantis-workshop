# Cost Management Guide

## 📊 Overview

Comprehensive cost management strategies for the Terraform Atlantis workshop infrastructure.

## 🎯 Cost Controls & Monitoring

### Budget Alerts

```hcl
resource "aws_budgets_budget" "monthly" {
  name              = "workshop-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "100"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["admin@example.com"]
  }
}
```

### Cost Monitoring Dashboard

```hcl
resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  dashboard_name = "workshop-cost-monitoring"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [["AWS/Billing", "EstimatedCharges", "Currency", "USD"]]
          period = 86400
          stat   = "Maximum"
          title  = "Daily Estimated Charges"
        }
      }
    ]
  })
}
```

## 🔧 Cost Optimization

### Auto Scaling Optimization

```hcl
resource "aws_autoscaling_schedule" "scale_down_night" {
  scheduled_action_name  = "scale-down-night"
  min_size               = 1
  max_size               = 2
  desired_capacity       = 1
  recurrence             = "0 22 * * *"
  autoscaling_group_name = aws_autoscaling_group.workshop.name
}
```

### Cost Allocation Tags

```hcl
locals {
  cost_allocation_tags = {
    Environment = var.environment
    Project     = "TerraformAtlantisWorkshop"
    Owner       = var.owner
    CostCenter  = "IT-Training"
  }
}
```

## 📈 Cost Analysis

### AWS CLI Commands

```bash
# Get current month's cost
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

## 🚨 Cost Alerting

### SNS Topic Setup

```hcl
resource "aws_sns_topic" "cost_alerts" {
  name = "workshop-cost-alerts"
}

resource "aws_sns_topic_subscription" "cost_alerts_email" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email
}
```

## 💡 Best Practices

1. **Resource Scheduling**: Use scheduled scaling for non-production
2. **Storage Optimization**: Implement S3 lifecycle policies
3. **Network Optimization**: Use CloudFront and VPC endpoints
4. **Monitoring**: Set up budget alerts at 50%, 80%, 100%

## 📋 Checklist

- [ ] Enable AWS Cost Explorer
- [ ] Set up budget alerts
- [ ] Implement cost allocation tags
- [ ] Create cost monitoring dashboard
- [ ] Configure cost optimization alarms
- [ ] Set up scheduled scaling
- [ ] Implement cost analysis Lambda
- [ ] Configure SNS notifications

## 🎯 Expected Outcomes

- Complete cost visibility
- Automated budget control
- Reduced costs through optimization
- Proper cost allocation and reporting
