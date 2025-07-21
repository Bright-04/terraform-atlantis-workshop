# Policy Validation Test - Branch: policy-validation-test-0721-1026

## Test Objective
This PR demonstrates Atlantis policy validation by introducing multiple policy violations:

## Policy Violations Introduced

### 1. Cost Control Violations (cost_control.rego)
- ❌ **Missing CostCenter tag**: \ws_instance.policy_test_no_cost_tag\
- ❌ **Expensive instance type**: \ws_instance.policy_test_expensive\ (m5.large)
- ❌ **Missing CostCenter tag**: \ws_s3_bucket.policy_test_unencrypted\

### 2. Security Violations (terraform_security.rego)
- ❌ **Unencrypted S3 bucket**: \ws_s3_bucket.policy_test_unencrypted\
- ❌ **Overly permissive security group**: \ws_security_group.policy_test_permissive\ (all ports open)
- ⚠️ **Missing backup tags**: Multiple resources

## Expected Atlantis Behavior
1. ✅ Atlantis should automatically run \	erraform plan\
2. ✅ Atlantis should run policy validation with Conftest
3. ❌ Atlantis should **BLOCK** the apply due to policy violations
4. 📝 Atlantis should comment with detailed policy violation report

## Test Instructions
1. Open a Pull Request with this branch
2. Wait for Atlantis to automatically run plan and policy check
3. Review policy violation comments from Atlantis
4. Verify that \tlantis apply\ is blocked until violations are fixed

## To Fix Violations
\\\	erraform
# Add missing CostCenter tags
tags = {
  # ... existing tags ...
  CostCenter = "workshop"
}

# Change expensive instance type
instance_type = "t3.micro"

# Add S3 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "policy_test_encryption" {
  bucket = aws_s3_bucket.policy_test_unencrypted.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Fix security group rules (remove overly permissive rules)
\\\

## Cleanup
After testing, remove the test resources and merge/close the PR.
