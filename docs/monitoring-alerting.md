# Monitoring & Alerting

## Overview

This guide covers the setup and configuration of comprehensive monitoring and alerting systems for the Terraform Atlantis workshop infrastructure. It includes CloudWatch monitoring, custom metrics, alerting, logging, and dashboard configuration.

## Monitoring Architecture

### High-Level Monitoring Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                    Monitoring & Alerting Stack                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐ │
│  │   Application   │    │   Infrastructure│    │   Security  │ │
│  │   Monitoring    │    │   Monitoring    │    │   Monitoring│ │
│  │                 │    │                 │    │             │ │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────┐ │ │
│  │ │ Application │ │    │ │ EC2 Metrics │ │    │ │ VPC Flow│ │ │
│  │ │ Logs        │ │    │ │ RDS Metrics │ │    │ │ Logs    │ │ │
│  │ │ Performance │ │    │ │ ALB Metrics │ │    │ │ IAM     │ │ │
│  │ │ Metrics     │ │    │ │ Auto Scaling│ │    │ │ Events  │ │ │
│  │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────┘ │ │
│  └─────────────────┘    └─────────────────┘    └─────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    Alerting & Notification                  │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │ │
│  │  │ CloudWatch  │  │ SNS Topics  │  │ Slack/Email │         │ │
│  │  │ Alarms      │  │             │  │ Notifications│         │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘         │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## CloudWatch Configuration

### 1. Basic CloudWatch Setup

```hcl
# terraform/monitoring/cloudwatch.tf
# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/application/${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.environment}-application-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "system" {
  name              = "/aws/system/${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.environment}-system-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "security" {
  name              = "/aws/security/${var.environment}"
  retention_in_days = 90

  tags = {
    Name        = "${var.environment}-security-logs"
    Environment = var.environment
  }
}
```

### 2. Custom Metrics

```hcl
# terraform/monitoring/custom-metrics.tf
# Custom Metric for Application Health
resource "aws_cloudwatch_metric_alarm" "application_health" {
  alarm_name          = "${var.environment}-application-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.main.arn_suffix
  }

  alarm_description = "Application health check failed"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.environment}-application-health-alarm"
    Environment = var.environment
  }
}

# Custom Metric for Response Time
resource "aws_cloudwatch_metric_alarm" "response_time" {
  alarm_name          = "${var.environment}-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.main.arn_suffix
  }

  alarm_description = "Application response time is too high"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.environment}-response-time-alarm"
    Environment = var.environment
  }
}
```

## Infrastructure Monitoring

### 1. EC2 Monitoring

```hcl
# terraform/monitoring/ec2-monitoring.tf
# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  alarm_description = "CPU utilization is high"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.environment}-cpu-high-alarm"
    Environment = var.environment
  }
}

# Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.environment}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  alarm_description = "Memory utilization is high"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.environment}-memory-high-alarm"
    Environment = var.environment
  }
}

# Disk Space Alarm
resource "aws_cloudwatch_metric_alarm" "disk_high" {
  alarm_name          = "${var.environment}-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  alarm_description = "Disk space utilization is high"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.environment}-disk-high-alarm"
    Environment = var.environment
  }
}
```

### 2. RDS Monitoring

```hcl
# terraform/monitoring/rds-monitoring.tf
# RDS CPU Utilization
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.environment}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  alarm_description = "RDS CPU utilization is high"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.environment}-rds-cpu-alarm"
    Environment = var.environment
  }
}

# RDS Freeable Memory
resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  alarm_name          = "${var.environment}-rds-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000000000"  # 1GB in bytes

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  alarm_description = "RDS freeable memory is low"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.environment}-rds-memory-alarm"
    Environment = var.environment
  }
}

# RDS Database Connections
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.environment}-rds-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  alarm_description = "RDS database connections are high"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.environment}-rds-connections-alarm"
    Environment = var.environment
  }
}
```

### 3. Load Balancer Monitoring

```hcl
# terraform/monitoring/alb-monitoring.tf
# ALB Request Count
resource "aws_cloudwatch_metric_alarm" "alb_requests" {
  alarm_name          = "${var.environment}-alb-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_description = "ALB request count is high"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.environment}-alb-requests-alarm"
    Environment = var.environment
  }
}

# ALB 5XX Errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_description = "ALB 5XX errors detected"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.environment}-alb-5xx-errors-alarm"
    Environment = var.environment
  }
}
```

## Security Monitoring

### 1. VPC Flow Logs

```hcl
# terraform/monitoring/security-monitoring.tf
# VPC Flow Logs
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-flow-logs"
    Environment = var.environment
  }
}

# Flow Logs CloudWatch Log Group
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.environment}-flow-logs"
    Environment = var.environment
  }
}

# Flow Logs IAM Role
resource "aws_iam_role" "flow_log_role" {
  name = "${var.environment}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# Flow Logs Policy
resource "aws_iam_role_policy" "flow_log_policy" {
  name = "${var.environment}-flow-log-policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}
```

### 2. IAM Monitoring

```hcl
# terraform/monitoring/iam-monitoring.tf
# IAM Access Denied Alarm
resource "aws_cloudwatch_metric_alarm" "iam_access_denied" {
  alarm_name          = "${var.environment}-iam-access-denied"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AccessDenied"
  namespace           = "AWS/IAM"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  alarm_description = "IAM access denied events detected"
  alarm_actions     = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name        = "${var.environment}-iam-access-denied-alarm"
    Environment = var.environment
  }
}

# IAM Root User Alarm
resource "aws_cloudwatch_metric_alarm" "iam_root_user" {
  alarm_name          = "${var.environment}-iam-root-user"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootUserEventCount"
  namespace           = "AWS/IAM"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  alarm_description = "Root user activity detected"
  alarm_actions     = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name        = "${var.environment}-iam-root-user-alarm"
    Environment = var.environment
  }
}
```

## Alerting Configuration

### 1. SNS Topics

```hcl
# terraform/monitoring/sns.tf
# Main Alerts SNS Topic
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-alerts"

  tags = {
    Name        = "${var.environment}-alerts-topic"
    Environment = var.environment
  }
}

# Security Alerts SNS Topic
resource "aws_sns_topic" "security_alerts" {
  name = "${var.environment}-security-alerts"

  tags = {
    Name        = "${var.environment}-security-alerts-topic"
    Environment = var.environment
  }
}

# Critical Alerts SNS Topic
resource "aws_sns_topic" "critical_alerts" {
  name = "${var.environment}-critical-alerts"

  tags = {
    Name        = "${var.environment}-critical-alerts-topic"
    Environment = var.environment
  }
}

# SNS Topic Subscriptions
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alerts_email
}

resource "aws_sns_topic_subscription" "security_alerts_email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_alerts_email
}

resource "aws_sns_topic_subscription" "critical_alerts_email" {
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.critical_alerts_email
}
```

### 2. Slack Integration

```hcl
# terraform/monitoring/slack-integration.tf
# Lambda Function for Slack Notifications
resource "aws_lambda_function" "slack_notification" {
  filename         = "slack_notification.zip"
  function_name    = "${var.environment}-slack-notification"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs16.x"
  timeout         = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  tags = {
    Name        = "${var.environment}-slack-notification"
    Environment = var.environment
  }
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda Policy
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.environment}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# SNS Topic Subscription for Slack
resource "aws_sns_topic_subscription" "alerts_slack" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notification.arn
}

# Lambda Permission for SNS
resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}
```

## Dashboard Configuration

### 1. CloudWatch Dashboard

```hcl
# terraform/monitoring/dashboard.tf
# Main Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Metrics"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main.id],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeableMemory", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Load Balancer Metrics"
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          query   = "SOURCE '/aws/application/${var.environment}'\n| fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 20"
          region  = var.aws_region
          title   = "Application Errors"
          view    = "table"
        }
      }
    ]
  })
}
```

### 2. Security Dashboard

```hcl
# terraform/monitoring/security-dashboard.tf
# Security Dashboard
resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "${var.environment}-security-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        x      = 0
        y      = 0
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/vpc/flowlogs/${var.environment}'\n| fields @timestamp, srcaddr, dstaddr, action\n| filter action == 'REJECT'\n| sort @timestamp desc\n| limit 50"
          region  = var.aws_region
          title   = "VPC Flow Log Rejections"
          view    = "table"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/IAM", "AccessDenied", "Region", var.aws_region],
            [".", "RootUserEventCount", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "IAM Security Events"
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          query   = "SOURCE '/aws/security/${var.environment}'\n| fields @timestamp, @message\n| filter @message like /FAILED/ or @message like /DENIED/\n| sort @timestamp desc\n| limit 20"
          region  = var.aws_region
          title   = "Security Events"
          view    = "table"
        }
      }
    ]
  })
}
```

## Log Aggregation

### 1. Centralized Logging

```hcl
# terraform/monitoring/logging.tf
# CloudWatch Log Insights Queries
resource "aws_cloudwatch_query_definition" "error_logs" {
  name = "${var.environment}-error-logs"

  log_group_names = [
    aws_cloudwatch_log_group.application.name,
    aws_cloudwatch_log_group.system.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}

resource "aws_cloudwatch_query_definition" "security_events" {
  name = "${var.environment}-security-events"

  log_group_names = [
    aws_cloudwatch_log_group.security.name,
    aws_cloudwatch_log_group.flow_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /FAILED/ or @message like /DENIED/ or @message like /REJECT/
| sort @timestamp desc
| limit 100
EOF
}
```

### 2. Log Retention Policies

```hcl
# terraform/monitoring/log-retention.tf
# Log Retention Policies
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/application/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.environment}-application-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "system" {
  name              = "/aws/system/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.environment}-system-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "security" {
  name              = "/aws/security/${var.environment}"
  retention_in_days = 90  # Longer retention for security logs

  tags = {
    Name        = "${var.environment}-security-logs"
    Environment = var.environment
  }
}
```

## Variables and Outputs

### 1. Variables

```hcl
# terraform/monitoring/variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "alerts_email" {
  description = "Email for general alerts"
  type        = string
}

variable "security_alerts_email" {
  description = "Email for security alerts"
  type        = string
}

variable "critical_alerts_email" {
  description = "Email for critical alerts"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}
```

### 2. Outputs

```hcl
# terraform/monitoring/outputs.tf
output "dashboard_url" {
  description = "URL of the main CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.environment}-dashboard"
}

output "security_dashboard_url" {
  description = "URL of the security CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.environment}-security-dashboard"
}

output "alerts_topic_arn" {
  description = "ARN of the main alerts SNS topic"
  value       = aws_sns_topic.alerts.arn
}

output "security_alerts_topic_arn" {
  description = "ARN of the security alerts SNS topic"
  value       = aws_sns_topic.security_alerts.arn
}
```

## Best Practices

### 1. Monitoring Best Practices

-   **Set Appropriate Thresholds**: Use realistic thresholds based on historical data
-   **Use Multiple Evaluation Periods**: Avoid false positives with multiple evaluation periods
-   **Implement Escalation**: Use different SNS topics for different severity levels
-   **Monitor Business Metrics**: Include application-specific metrics
-   **Regular Review**: Review and adjust alarms based on actual usage

### 2. Alerting Best Practices

-   **Avoid Alert Fatigue**: Don't create too many alarms
-   **Use Descriptive Names**: Make alarm names clear and descriptive
-   **Include Context**: Add descriptions to alarms
-   **Test Alerts**: Regularly test alert delivery
-   **Document Procedures**: Document response procedures for each alert

### 3. Logging Best Practices

-   **Structured Logging**: Use structured log formats (JSON)
-   **Include Context**: Log relevant context with each event
-   **Avoid Sensitive Data**: Never log passwords or sensitive information
-   **Use Appropriate Levels**: Use appropriate log levels (DEBUG, INFO, WARN, ERROR)
-   **Centralized Collection**: Collect logs centrally for analysis

## Next Steps

After setting up monitoring and alerting:

1. **Test Alerts**: Test all alert configurations
2. **Set Up Dashboards**: Create custom dashboards for different teams
3. **Implement Log Analysis**: Set up log analysis and reporting
4. **Create Runbooks**: Document response procedures
5. **Regular Reviews**: Schedule regular monitoring reviews

## Resources

-   [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
-   [CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
-   [CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/)
-   [SNS Documentation](https://docs.aws.amazon.com/sns/)
-   [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
