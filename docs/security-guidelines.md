# Security Guidelines - Terraform Atlantis Workshop

## 🔒 Security Considerations and Recommendations

This document provides comprehensive security guidelines for implementing and operating the **Environment Provisioning Automation with Terraform and Atlantis** workshop in a secure manner.

## 🛡️ Security Overview

### Security Principles

-   **Defense in Depth**: Multiple layers of security controls
-   **Least Privilege**: Minimal required permissions
-   **Zero Trust**: Verify everything, trust nothing
-   **Security by Design**: Security built into every component
-   **Continuous Monitoring**: Ongoing security oversight

### Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│                Security Architecture                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Network       │  │   Application   │  │   Data      │ │
│  │   Security      │  │   Security      │  │   Security  │ │
│  │   (VPC, SG)     │  │   (IAM, WAF)    │  │   (Encryption) │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                Compliance & Governance                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Policy        │  │   Audit         │  │   Access    │ │
│  │   Enforcement   │  │   Logging       │  │   Control   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🌐 Network Security

### 1. VPC Configuration

#### Secure VPC Design

```hcl
# VPC with secure configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Enable VPC Flow Logs for monitoring
  enable_flow_logs = true

  tags = merge(var.tags, {
    Name = "${var.environment}-vpc"
  })
}

# VPC Flow Logs for network monitoring
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
```

#### Best Practices

-   **Private Subnets**: Use private subnets for sensitive resources
-   **NAT Gateways**: Use NAT gateways for outbound internet access
-   **Flow Logs**: Enable VPC Flow Logs for network monitoring
-   **DNS Resolution**: Enable DNS hostnames and support

### 2. Security Groups

#### Restrictive Security Group Configuration

```hcl
# Web server security group
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from anywhere (for web servers)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # Allow HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Allow SSH from specific IPs only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
    description = "SSH access from allowed IPs"
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = var.tags
}
```

#### Security Group Best Practices

-   **Principle of Least Privilege**: Only allow necessary ports
-   **Source Restrictions**: Limit source IP addresses when possible
-   **Descriptive Rules**: Add descriptions to all rules
-   **Regular Review**: Periodically review and update rules
-   **Default Deny**: Deny all traffic by default, allow specific traffic

### 3. Network ACLs

#### Network ACL Configuration

```hcl
# Network ACL for additional network security
resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main.id

  # Allow HTTP inbound
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow HTTPS inbound
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow ephemeral ports for return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = var.tags
}
```

## 🔐 Identity and Access Management

### 1. IAM Roles and Policies

#### Least Privilege IAM Configuration

```hcl
# IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy with minimal required permissions
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.environment}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.data.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = [
          "arn:aws:cloudwatch:*:*:metric/*"
        ]
      }
    ]
  })
}
```

#### IAM Best Practices

-   **Least Privilege**: Grant minimum required permissions
-   **Resource-Level Permissions**: Use specific resource ARNs
-   **Role-Based Access**: Use roles instead of access keys
-   **Regular Audits**: Periodically review IAM permissions
-   **Access Reviews**: Regular access reviews and cleanup

### 2. User Access Management

#### User Access Configuration

```hcl
# IAM user for workshop access
resource "aws_iam_user" "workshop_user" {
  name = "terraform-workshop-user"

  tags = var.tags
}

# IAM policy for workshop user
resource "aws_iam_user_policy" "workshop_policy" {
  name = "terraform-workshop-policy"
  user = aws_iam_user.workshop_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "vpc:*",
          "cloudwatch:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/Environment": var.environment
          }
        }
      }
    ]
  })
}
```

#### Access Management Best Practices

-   **Multi-Factor Authentication**: Enable MFA for all users
-   **Access Key Rotation**: Regularly rotate access keys
-   **Session Management**: Implement session timeouts
-   **Access Monitoring**: Monitor access patterns and anomalies

## 🔒 Data Security

### 1. S3 Security

#### Secure S3 Configuration

```hcl
# S3 bucket with security features
resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name

  tags = var.tags
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "security_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
```

#### S3 Security Best Practices

-   **Encryption**: Always enable server-side encryption
-   **Versioning**: Enable versioning for data protection
-   **Public Access**: Block public access by default
-   **Lifecycle Policies**: Implement data lifecycle management
-   **Access Logging**: Enable access logging for audit trails

### 2. Data Encryption

#### Encryption Configuration

```hcl
# KMS key for encryption
resource "aws_kms_key" "data_encryption" {
  description             = "KMS key for data encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

# KMS alias for easier management
resource "aws_kms_alias" "data_encryption" {
  name          = "alias/${var.environment}-data-encryption"
  target_key_id = aws_kms_key.data_encryption.key_id
}

# EBS encryption for EC2 instances
resource "aws_instance" "web" {
  # ... other configuration ...

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = aws_kms_key.data_encryption.arn
  }
}
```

#### Encryption Best Practices

-   **Data at Rest**: Encrypt all data at rest
-   **Data in Transit**: Use TLS/SSL for data in transit
-   **Key Management**: Use AWS KMS for key management
-   **Key Rotation**: Enable automatic key rotation
-   **Access Control**: Control access to encryption keys

## 🔍 Monitoring and Logging

### 1. CloudWatch Logging

#### Comprehensive Logging Configuration

```hcl
# CloudWatch log group for application logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/ec2/${var.environment}-application"
  retention_in_days = 30

  tags = var.tags
}

# CloudWatch log group for VPC flow logs
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/${var.environment}-flow-logs"
  retention_in_days = 30

  tags = var.tags
}

# CloudWatch log group for security logs
resource "aws_cloudwatch_log_group" "security" {
  name              = "/aws/security/${var.environment}-logs"
  retention_in_days = 90

  tags = var.tags
}
```

#### Logging Best Practices

-   **Centralized Logging**: Centralize all logs in CloudWatch
-   **Log Retention**: Implement appropriate log retention policies
-   **Log Encryption**: Encrypt logs at rest
-   **Log Monitoring**: Monitor logs for security events
-   **Log Analysis**: Use CloudWatch Insights for log analysis

### 2. Security Monitoring

#### Security Alarms and Monitoring

```hcl
# CloudWatch alarm for unauthorized access
resource "aws_cloudwatch_metric_alarm" "unauthorized_access" {
  alarm_name          = "${var.environment}-unauthorized-access"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedAccess"
  namespace           = "AWS/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Unauthorized access detected"

  tags = var.tags
}

# CloudWatch alarm for failed login attempts
resource "aws_cloudwatch_metric_alarm" "failed_logins" {
  alarm_name          = "${var.environment}-failed-logins"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FailedLoginAttempts"
  namespace           = "AWS/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Multiple failed login attempts detected"

  tags = var.tags
}
```

#### Security Monitoring Best Practices

-   **Real-time Monitoring**: Monitor security events in real-time
-   **Alerting**: Set up alerts for security events
-   **Incident Response**: Have incident response procedures
-   **Forensics**: Maintain logs for forensic analysis
-   **Compliance**: Ensure monitoring meets compliance requirements

## 🛡️ Compliance and Governance

### 1. Security Policies

#### Policy Enforcement

```hcl
# AWS Config rule for security compliance
resource "aws_config_rule" "security_compliance" {
  name = "${var.environment}-security-compliance"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::Instance", "AWS::S3::Bucket"]
  }

  input_parameters = jsonencode({
    tag1Key   = "Environment"
    tag1Value = var.environment
    tag2Key   = "Security"
    tag2Value = "Compliant"
  })
}

# AWS Config rule for encryption compliance
resource "aws_config_rule" "encryption_compliance" {
  name = "${var.environment}-encryption-compliance"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}
```

#### Policy Best Practices

-   **Automated Enforcement**: Use AWS Config for policy enforcement
-   **Regular Audits**: Conduct regular compliance audits
-   **Policy Documentation**: Document all security policies
-   **Training**: Provide security training to team members
-   **Review Process**: Regular policy review and updates

### 2. Access Control

#### Access Control Configuration

```hcl
# AWS Organizations SCP for security controls
resource "aws_organizations_policy" "security_scp" {
  name = "${var.environment}-security-scp"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = [
          "ec2:DeleteVpc",
          "s3:DeleteBucket",
          "iam:DeleteRole"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestTag/Environment": var.environment
          }
        }
      }
    ]
  })
}
```

#### Access Control Best Practices

-   **Role-Based Access**: Implement role-based access control
-   **Principle of Least Privilege**: Grant minimum required access
-   **Regular Reviews**: Regular access reviews and cleanup
-   **Separation of Duties**: Implement separation of duties
-   **Access Monitoring**: Monitor access patterns and anomalies

## 🚨 Incident Response

### 1. Security Incident Procedures

#### Incident Response Plan

```markdown
# Security Incident Response Plan

## 1. Detection

-   Monitor CloudWatch alarms and logs
-   Review security events and alerts
-   Investigate suspicious activities

## 2. Assessment

-   Assess the scope and impact of the incident
-   Determine the type and severity of the incident
-   Identify affected resources and data

## 3. Containment

-   Isolate affected resources
-   Block malicious IP addresses
-   Revoke compromised credentials

## 4. Eradication

-   Remove malware and backdoors
-   Patch vulnerabilities
-   Restore from clean backups

## 5. Recovery

-   Restore affected services
-   Verify system integrity
-   Monitor for recurrence

## 6. Lessons Learned

-   Document the incident
-   Update procedures and policies
-   Conduct post-incident review
```

### 2. Emergency Procedures

#### Emergency Access

```hcl
# Emergency access role for incident response
resource "aws_iam_role" "emergency_access" {
  name = "${var.environment}-emergency-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.emergency_account_id}:root"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId": var.emergency_external_id
          }
        }
      }
    ]
  })

  tags = var.tags
}
```

#### Emergency Procedures Best Practices

-   **Emergency Contacts**: Maintain up-to-date emergency contacts
-   **Escalation Procedures**: Define clear escalation procedures
-   **Communication Plan**: Have a communication plan for incidents
-   **Documentation**: Document all incident response procedures
-   **Testing**: Regular testing of incident response procedures

## 📋 Security Checklist

### Pre-Deployment Security Checklist

-   ✅ **Network Security**: VPC, security groups, and NACLs configured
-   ✅ **Identity Management**: IAM roles and policies configured
-   ✅ **Data Protection**: Encryption enabled for all data
-   ✅ **Monitoring**: CloudWatch logging and monitoring configured
-   ✅ **Compliance**: Security policies and controls implemented
-   ✅ **Access Control**: Access controls and authentication configured
-   ✅ **Incident Response**: Incident response procedures documented
-   ✅ **Training**: Security training provided to team members

### Ongoing Security Maintenance

-   ✅ **Regular Audits**: Conduct regular security audits
-   ✅ **Patch Management**: Keep systems patched and updated
-   ✅ **Access Reviews**: Regular access reviews and cleanup
-   ✅ **Monitoring**: Continuous security monitoring
-   ✅ **Testing**: Regular security testing and assessments
-   ✅ **Documentation**: Keep security documentation updated
-   ✅ **Training**: Regular security training and awareness

## 📞 Security Support

### Getting Security Help

-   **Security Issues**: Report security issues immediately
-   **Incident Response**: Follow incident response procedures
-   **Security Training**: Attend security training sessions
-   **Security Reviews**: Participate in security reviews
-   **Security Updates**: Stay updated on security best practices

### Security Resources

-   **AWS Security**: https://aws.amazon.com/security/
-   **AWS Security Blog**: https://aws.amazon.com/blogs/security/
-   **AWS Security Best Practices**: https://aws.amazon.com/architecture/security-identity-compliance/
-   **Security Compliance**: https://aws.amazon.com/compliance/

---

**📚 Related Documentation**

-   [Best Practices](best-practices.md)
-   [Compliance Validation](compliance-validation.md)
-   [Troubleshooting Guide](troubleshooting-guide.md)
-   [FAQ](faq.md)
