# Atlantis Workflow Test Plan

## Test Scenario: Add Tags to EC2 Instance

We'll test the Atlantis workflow by adding additional tags to the EC2 instance.

### Expected Workflow:
1. Create a branch with Terraform changes
2. Open a Pull Request
3. Atlantis automatically runs `terraform plan`
4. Review the plan in PR comments
5. Approve the PR
6. Comment `atlantis apply` to deploy
7. Verify infrastructure changes

### Test Change:
- Add new tags to the EC2 instance
- Modify the `additional_tags` variable

### Expected Result:
- Atlantis should detect the change
- Generate a plan showing tag modifications
- Apply the changes after approval
