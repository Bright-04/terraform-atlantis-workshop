# Complete Analysis: "unable to unmarshal conftest output" Error

## Current Status

Despite fixing Conftest version to v0.25.0 and ensuring all policies work correctly, the error persists.

## Environment Details

-   **Atlantis Version**: v0.35.0 (very recent, potentially unstable)
-   **Conftest Version**: v0.25.0 (compatible version)
-   **Policy Files**: Both `cost_control.rego` and `terraform_security.rego` are working
-   **JSON Output**: Valid and compatible format

## Root Cause Analysis

### 1. Atlantis v0.35.0 Compatibility Issue

The main suspect is **Atlantis v0.35.0** being a very recent version that may have:

-   Different JSON parsing expectations
-   Bugs in policy check implementation
-   Incompatible changes in how it calls Conftest

### 2. Policy Check Workflow Issue

The `atlantis.yaml` configuration looks correct, but Atlantis might not be:

-   Actually running the policy check step
-   Calling Conftest with the correct parameters
-   Parsing the JSON output correctly

### 3. Conftest Command Parameters

Atlantis might be calling Conftest with different parameters than we're testing:

-   Different namespace handling
-   Different output format expectations
-   Different error handling

## Verified Working Components

### ✅ Conftest v0.25.0 Installation

```bash
$ docker exec atlantis_workshop conftest --version
Version: 0.25.0
```

### ✅ Policy Files Mounting

```bash
$ docker exec atlantis_workshop ls -la /policies/
-rwxr-xr-x    1 root     root          1599 Aug  6 08:53 cost_control.rego
-rwxrwxrwx    1 root     root          2343 Aug  6 09:00 terraform_security.rego
```

### ✅ Policy Syntax (Fixed)

-   Removed `warn[msg]` syntax (incompatible with v0.25.0)
-   All policies now use `deny[msg]` only
-   Both cost and security policies work correctly

### ✅ JSON Output Format

```json
[
	{
		"filename": "test-plan.json",
		"namespace": "terraform.cost",
		"successes": 1,
		"failures": [
			{
				"msg": "Policy violation message"
			}
		]
	}
]
```

## Potential Solutions

### Solution 1: Downgrade Atlantis (Recommended)

Change to a stable Atlantis version known to work with Conftest v0.25.0:

```dockerfile
FROM ghcr.io/runatlantis/atlantis:v0.27.0
```

### Solution 2: Upgrade Conftest (Alternative)

If Atlantis v0.35.0 requires newer Conftest:

```dockerfile
RUN wget -O conftest.tar.gz https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Linux_x86_64.tar.gz
```

### Solution 3: Custom Policy Check Workflow

Override the default policy check with a custom workflow:

```yaml
workflows:
    default:
        policy_check:
            steps:
                - run: conftest test --policy ../policies/ $PLANFILE -o json
```

### Solution 4: Disable Policy Checks Temporarily

Remove policy checks to verify other functionality works:

```yaml
workflows:
    default:
        plan:
            steps:
                - env:
                      name: TF_IN_AUTOMATION
                      value: "true"
                - init
                - plan
        apply:
            steps:
                - apply
```

## Recommended Next Steps

1. **Try Solution 1**: Downgrade Atlantis to v0.27.0
2. **If that fails**: Try Solution 2 with Conftest v0.46.0
3. **If both fail**: Use Solution 3 with custom workflow
4. **Last resort**: Use Solution 4 to disable policy checks

## Test Commands

### Verify Current Setup

```bash
# Check versions
docker exec atlantis_workshop atlantis version
docker exec atlantis_workshop conftest --version

# Test policies manually
docker exec atlantis_workshop sh -c "cd /terraform && conftest test --policy ../policies/ test-plan.json --namespace terraform.cost -o json"
```

### Test After Changes

```bash
# Rebuild and restart
docker-compose build --no-cache atlantis
docker-compose up -d --force-recreate

# Test in GitHub PR
atlantis plan -p terraform-atlantis-workshop
```

## Expected Outcome

After implementing the correct solution, you should see:

1. Plan succeeds
2. Policy check succeeds with actual violations
3. No "unable to unmarshal conftest output" error
