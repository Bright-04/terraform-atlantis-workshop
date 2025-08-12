# Feature: RDS Database and CloudFront CDN

## Overview
This feature branch adds significant infrastructure components to test the Terraform Atlantis workflow:

1. **PostgreSQL RDS Database** - A managed database for application data
2. **CloudFront Distribution** - CDN for serving static content from S3

## Changes Made

### 1. RDS Database Infrastructure
- Added PostgreSQL RDS instance with encryption
- Created database subnet group for private subnet placement
- Added parameter group with logging enabled
- Created security group with restricted access (only from web servers)
- Added comprehensive tagging for cost tracking

### 2. CloudFront CDN
- Created CloudFront distribution for S3 bucket
- Added Origin Access Identity for secure S3 access
- Configured cache behaviors for different content types
- Added S3 bucket policy for CloudFront access

### 3. Variables and Outputs
- Added new variables for database configuration
- Added outputs for database connection information
- Added CloudFront distribution outputs

## Files Modified
- `terraform/variables.tf` - Added RDS variables
- `terraform/main-aws.tf` - Added RDS resources
- `terraform/outputs.tf` - Added RDS and CloudFront outputs
- `terraform/cloudfront.tf` - New file for CloudFront resources

## Testing Workflow
This branch will test:
1. Terraform plan validation
2. Atlantis workflow processing
3. GitHub Actions integration
4. Compliance policy validation
5. Cost estimation and monitoring

## Security Features
- Database encryption at rest
- Security groups with minimal required access
- CloudFront with HTTPS enforcement
- S3 bucket with public access blocked

## Cost Considerations
- RDS instance: db.t3.micro (~$15/month)
- CloudFront: Pay-per-use CDN
- Additional storage and data transfer costs

## Next Steps
1. Create pull request
2. Run Atlantis plan
3. Review compliance validation
4. Test deployment
5. Monitor costs and performance
