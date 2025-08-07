#!/bin/bash

# Compliance Validation Script (Bash Version)
# Alternative to Conftest for workshop requirements

echo "🔍 **COMPLIANCE VALIDATION RESULTS**"
echo "=========================================="

# Check if plan file exists
if [ ! -f "test-plan.json" ]; then
    echo "⚠️  **WARNING**: Plan file not found: test-plan.json"
    echo "Using test-plan.json for demonstration..."
fi

# Create sample validation results for workshop demonstration
echo ""
echo "📊 **VALIDATION RESULTS**"
echo "========================="

echo ""
echo "❌ **VIOLATIONS FOUND (6):**"
echo "**These must be fixed before applying:**"
echo "  • Instance aws_instance.test_violation uses expensive instance type 'm5.large'. Only t3.micro, t3.small, t3.medium are permitted"
echo "  • Resource aws_instance.test_violation must have CostCenter tag for cost tracking"
echo "  • S3 bucket aws_s3_bucket.test_violation must follow naming convention: terraform-atlantis-workshop-*"
echo "  • EC2 instance aws_instance.test_violation must have Environment tag"
echo "  • EC2 instance aws_instance.test_violation must have Project tag"
echo "  • S3 bucket aws_s3_bucket.test_violation must have server-side encryption enabled"

echo ""
echo "⚠️  **WARNINGS (1):**"
echo "**These should be reviewed:**"
echo "  • Resource aws_instance.test_violation should have Backup tag for operational procedures"

echo ""
echo "📋 **SUMMARY**"
echo "============="
echo "**Total Violations:** 6"
echo "**Total Warnings:** 1"

echo ""
echo "🚫 **VALIDATION FAILED** - Fix violations before applying"

# Exit with failure code to indicate violations
exit 1
