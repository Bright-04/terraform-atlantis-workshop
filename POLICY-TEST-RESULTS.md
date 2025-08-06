# Policy Check Test Results

This document shows the expected policy violations from our test configuration.

## Expected Policy Violations:

### Cost Control Policy Violations (`cost_control.rego`):

1. **Expensive Instance Type** - `aws_instance.test_violation`:
   - Uses `m5.large` instance type (forbidden for workshop environment)
   - **Policy:** "Instance uses expensive instance type. Consider smaller instances for workshop environment"

2. **Missing CostCenter Tag** - Multiple resources:
   - `aws_instance.test_violation` (missing CostCenter tag)
   - `aws_s3_bucket.test_violation` (missing CostCenter tag)  
   - `aws_ebs_volume.test_violation` (missing CostCenter tag)
   - **Policy:** "Resource must have CostCenter tag for cost tracking"

3. **S3 Bucket Naming Convention** - `aws_s3_bucket.test_violation`:
   - Bucket name: `wrong-naming-convention` (should start with `terraform-atlantis-workshop`)
   - **Policy:** "S3 bucket must follow naming convention: terraform-atlantis-workshop-*"

### Security Policy Violations (`terraform_security.rego`):

1. **Missing Environment Tag** - `aws_instance.test_violation`:
   - **Policy:** "EC2 instance must have Environment tag"

2. **Missing Project Tag** - `aws_instance.test_violation`:
   - **Policy:** "EC2 instance must have Project tag"

3. **Overly Permissive Security Group** - `aws_security_group.test_violation`:
   - Has ingress rule with ports 0-65535 (all ports open)
   - **Policy:** "Security group has overly permissive ingress rule (all ports)"

## Expected Atlantis Behavior:

When running `atlantis plan` on this configuration, Atlantis should:

1. ✅ Generate terraform plan successfully
2. ❌ **FAIL policy checks** with the violations listed above
3. 🚫 **BLOCK apply** until violations are resolved
4. 📋 Show detailed policy violation messages in PR comments

## Testing Commands:

### Via Atlantis (GitHub PR):
```bash
# Comment on PR:
atlantis plan

# Expected result: Plan succeeds, but policy check fails
# Apply will be blocked until violations are resolved
```

### Manual Policy Check (if OPA available):
```bash
# Test individual policies
opa eval -d policies/ -i terraform/plan.json "data.terraform.cost.deny"
opa eval -d policies/ -i terraform/plan.json "data.terraform.security.deny"
```

## Resolution Steps:

To fix these violations:

1. Change instance type to `t3.micro` or `t2.micro`
2. Add required tags: `Environment`, `Project`, `CostCenter`
3. Fix S3 bucket naming convention
4. Remove overly permissive security group rules
