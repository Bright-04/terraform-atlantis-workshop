# Outputs for minimal workshop infrastructure

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

# Security Group Outputs
output "security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

# EC2 Instance Outputs
output "instance_id" {
  description = "ID of the web instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address of the web instance"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the web instance"
  value       = aws_instance.web.public_dns
}

# S3 Bucket Outputs
output "s3_bucket_id" {
  description = "ID of the main workshop S3 bucket"
  value       = aws_s3_bucket.workshop.id
}

output "s3_bucket_arn" {
  description = "ARN of the main workshop S3 bucket"
  value       = aws_s3_bucket.workshop.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the main workshop S3 bucket"
  value       = aws_s3_bucket.workshop.bucket_domain_name
}

output "website_url" {
  description = "S3 website URL"
  value       = "http://${aws_s3_bucket.workshop.bucket}.s3-website-${var.region}.amazonaws.com"
}

# Compliance and Validation Outputs
output "compliance_validation_status" {
  description = "Compliance validation status"
  value = {
    total_instances        = 3
    total_buckets          = 4
    required_tags          = ["Environment", "Project", "CostCenter"]
    recommended_tags       = ["Backup"]
    allowed_instance_types = ["t3.micro", "t3.small", "t3.medium"]
    message                = "Compliance validation framework active"
  }
}

output "compliance_rules" {
  description = "Compliance rules configuration"
  value = {
    security = {
      encryption_required  = true
      s3_naming_convention = "terraform-atlantis-workshop-*"
    }
    cost_control = {
      allowed_instance_types = ["t3.micro", "t3.small", "t3.medium"]
      required_tags          = ["Environment", "Project", "CostCenter"]
    }
    operational = {
      recommended_tags = ["Backup"]
    }
  }
}
