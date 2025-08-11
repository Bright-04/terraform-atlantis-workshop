# Monitoring and Observability Guide

## 🎯 Overview

This guide covers setting up comprehensive monitoring and observability for your Terraform infrastructure. You'll learn how to monitor resources, set up alerts, and gain insights into your infrastructure performance.

## 📋 Prerequisites

Before starting this guide, ensure you have:

-   ✅ **Infrastructure deployed** to AWS (04-AWS-DEPLOYMENT.md)
-   ✅ **Compliance policies** working (05-COMPLIANCE.md)
-   ✅ **GitOps setup** with Atlantis (06-ATLANTIS.md)
-   ✅ **Testing completed** (07-TESTING.md)

## 📊 Monitoring Architecture Overview

### **Monitoring Stack**

```
┌─────────────────────────────────────────────────────────────┐
│                    Monitoring Architecture                   │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   AWS Resources │    │   CloudWatch    │                │
│  │                 │    │                 │                │
│  │ • EC2 Instances │───▶│ • Metrics       │                │
│  │ • S3 Buckets    │    │ • Logs          │                │
│  │ • VPC/Network   │    │ • Alarms        │                │
│  │ • IAM/Roles     │    │ • Dashboards    │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                        │
│           │                       ▼                        │
│           │              ┌─────────────────┐                │
│           │              │   Notifications │                │
│           │              │                 │                │
│           │              │ • Email         │                │
│           │              │ • SNS Topics    │                │
│           │              │ • Slack/Teams   │                │
│           │              └─────────────────┘                │
│           │                       │                        │
│           ▼                       ▼                        │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Cost Monitor  │    │   Performance   │                │
│  │                 │    │   Monitor       │                │
│  │ • Billing Alerts│    │ • Response Time │                │
│  │ • Usage Tracking│    │ • Throughput    │                │
│  │ • Optimization  │    │ • Availability  │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

## 🔍 CloudWatch Setup

### **1. CloudWatch Logs Configuration**

#### **Verify Log Group Setup**

```bash
# Check existing log group
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/ec2/terraform-atlantis-workshop" \
  --query 'logGroups[].[logGroupName,retentionInDays]' \
  --output table

# Expected output:
# /aws/ec2/terraform-atlantis-workshop | 7
```

#### **Configure Log Retention**

```bash
# Update log retention if needed
aws logs put-retention-policy \
  --log-group-name "/aws/ec2/terraform-atlantis-workshop" \
  --retention-in-days 14
```

### **2. CloudWatch Metrics**

#### **View Available Metrics**

```bash
# List EC2 metrics
aws cloudwatch list-metrics \
  --namespace AWS/EC2 \
  --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
  --query 'Metrics[].[MetricName]' \
  --output table

# List S3 metrics
aws cloudwatch list-metrics \
  --namespace AWS/S3 \
  --dimensions Name=BucketName,Value=$(terraform output -raw s3_bucket_id) \
  --query 'Metrics[].[MetricName]' \
  --output table
```

#### **Get Metric Statistics**

```bash
# Get CPU utilization for the last hour
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --query 'Datapoints[].[Timestamp,Average]' \
  --output table
```

## 🚨 Alerting Setup

### **1. CloudWatch Alarms**

#### **CPU Utilization Alarm**

```bash
# Create CPU utilization alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "HighCPUUtilization-$(terraform output -raw instance_id)" \
  --alarm-description "Alarm when CPU exceeds 80% for 5 minutes" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
  --alarm-actions arn:aws:sns:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):terraform-workshop-alerts
```

#### **Disk Space Alarm**

```bash
# Create disk space alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "LowDiskSpace-$(terraform output -raw instance_id)" \
  --alarm-description "Alarm when disk space is below 20%" \
  --metric-name DiskSpaceUtilization \
  --namespace System/Linux \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
  --alarm-actions arn:aws:sns:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):terraform-workshop-alerts
```

#### **Status Check Alarm**

```bash
# Create status check alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "StatusCheckFailed-$(terraform output -raw instance_id)" \
  --alarm-description "Alarm when instance status check fails" \
  --metric-name StatusCheckFailed \
  --namespace AWS/EC2 \
  --statistic Maximum \
  --period 60 \
  --threshold 1 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
  --alarm-actions arn:aws:sns:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):terraform-workshop-alerts
```

### **2. SNS Topic Setup**

#### **Create SNS Topic**

```bash
# Create SNS topic for alerts
aws sns create-topic \
  --name terraform-workshop-alerts \
  --tags Key=Project,Value=terraform-atlantis-workshop

# Subscribe to email notifications
aws sns subscribe \
  --topic-arn arn:aws:sns:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):terraform-workshop-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com
```

### **3. View Alarms**

#### **List Active Alarms**

```bash
# List all alarms
aws cloudwatch describe-alarms \
  --query 'MetricAlarms[].[AlarmName,StateValue,Threshold]' \
  --output table

# List alarms by state
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[].[AlarmName,StateValue]' \
  --output table
```

## 📈 Dashboard Creation

### **1. CloudWatch Dashboard**

#### **Create Dashboard**

```bash
# Create dashboard JSON
cat > dashboard.json << EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/EC2", "CPUUtilization", "InstanceId", "$(terraform output -raw instance_id)"]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "$(aws configure get region)",
        "title": "EC2 CPU Utilization",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/EC2", "NetworkIn", "InstanceId", "$(terraform output -raw instance_id)"],
          [".", "NetworkOut", ".", "."]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "$(aws configure get region)",
        "title": "Network Traffic",
        "period": 300
      }
    }
  ]
}
EOF

# Create dashboard
aws cloudwatch put-dashboard \
  --dashboard-name TerraformWorkshopDashboard \
  --dashboard-body file://dashboard.json
```

### **2. View Dashboard**

#### **Access Dashboard**

```bash
# Get dashboard URL
echo "Dashboard URL: https://$(aws configure get region).console.aws.amazon.com/cloudwatch/home?region=$(aws configure get region)#dashboards:name=TerraformWorkshopDashboard"
```

## 💰 Cost Monitoring

### **1. Billing Alerts**

#### **Create Billing Alarm**

```bash
# Create billing alarm (requires billing alerts enabled)
aws cloudwatch put-metric-alarm \
  --alarm-name "MonthlyBillingAlarm" \
  --alarm-description "Alarm when monthly billing exceeds $50" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=Currency,Value=USD \
  --alarm-actions arn:aws:sns:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):terraform-workshop-alerts
```

### **2. Cost Analysis**

#### **Get Cost Data**

```bash
# Get current month's costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[0].Groups[].[Keys[0],Metrics.BlendedCost.Amount]' \
  --output table

# Get EC2 costs specifically
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{"Dimensions": {"Key": "SERVICE", "Values": ["Amazon Elastic Compute Cloud - Compute"]}}' \
  --query 'ResultsByTime[0].Groups[0].Metrics.BlendedCost.Amount' \
  --output text
```

## 🔍 Log Monitoring

### **1. CloudWatch Logs**

#### **View Log Streams**

```bash
# List log streams
aws logs describe-log-streams \
  --log-group-name "/aws/ec2/terraform-atlantis-workshop" \
  --order-by LastEventTime \
  --descending \
  --max-items 5 \
  --query 'logStreams[].[logStreamName,lastEventTimestamp]' \
  --output table
```

#### **Filter Log Events**

```bash
# Filter recent log events
aws logs filter-log-events \
  --log-group-name "/aws/ec2/terraform-atlantis-workshop" \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --query 'events[].[timestamp,message]' \
  --output table

# Filter for errors
aws logs filter-log-events \
  --log-group-name "/aws/ec2/terraform-atlantis-workshop" \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --filter-pattern "ERROR" \
  --query 'events[].[timestamp,message]' \
  --output table
```

### **2. Application Logs**

#### **Monitor Web Server Logs**

```bash
# Check Apache logs on the instance
# (This would require SSH access to the instance)
# sudo tail -f /var/log/httpd/access_log
# sudo tail -f /var/log/httpd/error_log
```

## 📊 Performance Monitoring

### **1. Web Application Monitoring**

#### **Test Response Time**

```bash
# Test web server response time
time curl -s $(terraform output -raw website_url) > /dev/null

# Test with multiple requests
for i in {1..10}; do
  echo "Request $i: $(curl -s -w "%{time_total}s" $(terraform output -raw website_url) -o /dev/null)"
done
```

#### **Load Testing**

```bash
# Simple load test with Apache Bench (if available)
# ab -n 100 -c 10 $(terraform output -raw website_url)

# Or with curl
for i in {1..50}; do
  curl -s $(terraform output -raw website_url) > /dev/null &
done
wait
echo "Load test completed"
```

### **2. S3 Performance**

#### **Test S3 Operations**

```bash
# Test S3 upload performance
time dd if=/dev/zero bs=1M count=100 | aws s3 cp - \
  s3://$(terraform output -raw s3_bucket_id)/performance-test-file

# Test S3 download performance
time aws s3 cp s3://$(terraform output -raw s3_bucket_id)/performance-test-file /tmp/
```

## 🔧 Monitoring Automation

### **1. Monitoring Scripts**

#### **Health Check Script**

```bash
#!/bin/bash
# health-check.sh

echo "🔍 Running infrastructure health check..."

# Check instance status
INSTANCE_ID=$(terraform output -raw instance_id)
INSTANCE_STATE=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text)

echo "Instance State: $INSTANCE_STATE"

# Check web server
WEBSITE_URL=$(terraform output -raw website_url)
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $WEBSITE_URL)

echo "Website Status: $HTTP_STATUS"

# Check CloudWatch alarms
ALARM_COUNT=$(aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'length(MetricAlarms)' \
  --output text)

echo "Active Alarms: $ALARM_COUNT"

# Check S3 bucket
S3_BUCKET=$(terraform output -raw s3_bucket_id)
S3_EXISTS=$(aws s3 ls s3://$S3_BUCKET >/dev/null 2>&1 && echo "OK" || echo "ERROR")

echo "S3 Bucket Status: $S3_EXISTS"

echo "✅ Health check completed!"
```

#### **Cost Monitoring Script**

```bash
#!/bin/bash
# cost-monitor.sh

echo "💰 Checking infrastructure costs..."

# Get current month's cost
CURRENT_COST=$(aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
  --output text)

echo "Current Month Cost: $${CURRENT_COST}"

# Get EC2 cost
EC2_COST=$(aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{"Dimensions": {"Key": "SERVICE", "Values": ["Amazon Elastic Compute Cloud - Compute"]}}' \
  --query 'ResultsByTime[0].Groups[0].Metrics.BlendedCost.Amount' \
  --output text)

echo "EC2 Cost: $${EC2_COST}"

# Check if cost exceeds threshold
THRESHOLD=50
if (( $(echo "$CURRENT_COST > $THRESHOLD" | bc -l) )); then
  echo "⚠️  WARNING: Cost exceeds $${THRESHOLD} threshold!"
else
  echo "✅ Cost is within acceptable range"
fi
```

### **2. Automated Monitoring**

#### **Cron Jobs for Monitoring**

```bash
# Add to crontab for automated monitoring
# Check every 5 minutes
*/5 * * * * /path/to/health-check.sh >> /var/log/health-check.log 2>&1

# Check costs daily at 9 AM
0 9 * * * /path/to/cost-monitor.sh >> /var/log/cost-monitor.log 2>&1
```

## 📋 Monitoring Checklist

Before considering monitoring complete, verify:

-   [ ] **CloudWatch alarms** configured and active
-   [ ] **SNS notifications** set up and tested
-   [ ] **Dashboard** created and accessible
-   [ ] **Log monitoring** configured
-   [ ] **Cost monitoring** active
-   [ ] **Performance monitoring** implemented
-   [ ] **Automated scripts** running
-   [ ] **Alerting** working correctly

## 🎯 Best Practices

### **1. Monitoring Strategy**

-   **Monitor key metrics** that indicate health
-   **Set appropriate thresholds** for alerts
-   **Use multiple notification channels** for critical alerts
-   **Regularly review and adjust** monitoring configuration

### **2. Alert Management**

-   **Avoid alert fatigue** by setting meaningful thresholds
-   **Use different severity levels** for different types of issues
-   **Document alert procedures** and response plans
-   **Test alerting** regularly

### **3. Cost Optimization**

-   **Monitor costs daily** to catch unexpected charges
-   **Set up billing alerts** to prevent overspending
-   **Review resource usage** regularly
-   **Optimize based on monitoring data**

## 🚨 Troubleshooting

### **1. Common Monitoring Issues**

#### **Alarms Not Triggering**

```bash
# Check alarm configuration
aws cloudwatch describe-alarms \
  --alarm-names "HighCPUUtilization-$(terraform output -raw instance_id)"

# Check metric data
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

#### **Logs Not Appearing**

```bash
# Check log group configuration
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/ec2/terraform-atlantis-workshop"

# Check instance logging configuration
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'
```

### **2. Debugging Commands**

```bash
# Check CloudWatch service status
aws health describe-events \
  --filter eventTypeCategory=issue \
  --query 'events[?service==`CLOUDWATCH`]'

# Check SNS topic subscriptions
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):terraform-workshop-alerts
```

## 📞 Support

If you encounter monitoring issues:

1. **Check the troubleshooting guide** (09-TROUBLESHOOTING.md)
2. **Verify CloudWatch permissions** and configuration
3. **Test alerting manually** to ensure it works
4. **Check AWS service status** for any outages
5. **Review CloudWatch documentation** for specific issues

---

**Monitoring set up?** Continue to [09-TROUBLESHOOTING.md](09-TROUBLESHOOTING.md) for troubleshooting guidance!
