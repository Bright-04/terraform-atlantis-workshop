#!/bin/bash

# User data script for workshop EC2 instance
# This script sets up a basic web server for the workshop

# Update system
yum update -y

# Install Apache
yum install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a simple index page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Terraform Atlantis Workshop</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .content { margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Terraform Atlantis Workshop</h1>
            <p>Welcome to the Infrastructure as Code workshop!</p>
        </div>
        <div class="content">
            <h2>Project: ${project_name}</h2>
            <p>This EC2 instance was created using Terraform and managed by Atlantis.</p>
            <h3>Workshop Components:</h3>
            <ul>
                <li>✅ VPC with public and private subnets</li>
                <li>✅ EC2 instances with proper security groups</li>
                <li>✅ S3 buckets with encryption and versioning</li>
                <li>✅ IAM roles and policies</li>
                <li>✅ CloudWatch logging</li>
            </ul>
            <h3>Next Steps:</h3>
            <ul>
                <li>Test the CI/CD pipeline with GitHub Actions</li>
                <li>Explore compliance validation</li>
                <li>Practice infrastructure changes</li>
            </ul>
            <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
            <p><strong>Region:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/region)</p>
            <p><strong>Bucket:</strong> ${bucket_name}</p>
        </div>
    </div>
</body>
</html>
EOF

# Set proper permissions
chown apache:apache /var/www/html/index.html

# Create a simple health check endpoint
cat > /var/www/html/health.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Health Check</title>
</head>
<body>
    <h1>✅ Healthy</h1>
    <p>Server is running successfully!</p>
    <p>Timestamp: $(date)</p>
</body>
</html>
EOF

# Log the setup completion
echo "User data script completed at $(date)" >> /var/log/user-data.log
