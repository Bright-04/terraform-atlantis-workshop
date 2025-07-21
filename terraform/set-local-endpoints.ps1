# PowerShell script to set LocalStack endpoints for local terraform development
# Run this before executing terraform commands locally

Write-Host "Setting LocalStack endpoint environment variables..."

$env:AWS_ENDPOINT_URL_EC2="http://localhost:4566"
$env:AWS_ENDPOINT_URL_S3="http://localhost:4566"
$env:AWS_ENDPOINT_URL_RDS="http://localhost:4566"
$env:AWS_ENDPOINT_URL_IAM="http://localhost:4566"
$env:AWS_ENDPOINT_URL_CLOUDWATCH="http://localhost:4566"
$env:AWS_ENDPOINT_URL_LOGS="http://localhost:4566"
$env:AWS_ENDPOINT_URL_STS="http://localhost:4566"
$env:AWS_ENDPOINT_URL_LAMBDA="http://localhost:4566"
$env:AWS_ENDPOINT_URL_APIGATEWAY="http://localhost:4566"

Write-Host "LocalStack endpoints configured for localhost:4566"
Write-Host "You can now run terraform commands that will connect to LocalStack"
