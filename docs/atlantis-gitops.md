# Atlantis GitOps

## Overview

Atlantis is a GitOps workflow automation tool that integrates Terraform with Git pull requests. It provides automated `terraform plan` and `apply` operations triggered by pull request comments, enabling teams to collaborate on infrastructure changes safely and efficiently.

## What is GitOps?

GitOps is an operational framework that takes DevOps best practices used for application development and applies them to infrastructure automation. The core principles are:

-   **Declarative**: All desired states are expressed declaratively
-   **Versioned and Immutable**: Desired states are stored in a way that enforces immutability and versioning
-   **Pulled Automatically**: Software agents automatically pull the desired state declarations
-   **Continuously Reconciled**: Software agents continuously observe actual state vs. desired state

## Atlantis Architecture

### Core Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub/GitLab │    │     Atlantis    │    │      AWS        │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Pull Request│◄┼────┼►│ Webhook     │ │    │ │ Terraform   │ │
│ │ Comments    │ │    │ │ Handler     │ │    │ │ State       │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ │ (S3)        │ │
│                 │    │                 │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │                 │
│ │ Repository  │◄┼────┼►│ Terraform   │ │    │ ┌─────────────┐ │
│ │ (Code)      │ │    │ │ Executor    │ │    │ │ Resources   │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ │ (EC2, VPC,  │ │
│                 │    │                 │    │ │  etc.)      │ │
└─────────────────┘    └─────────────────┘    │ └─────────────┘ │
                                              └─────────────────┘
```

### Key Features

-   **Pull Request Integration**: Comments trigger Terraform operations
-   **Automated Planning**: `terraform plan` runs automatically on PR creation
-   **Approval Workflow**: `terraform apply` requires explicit approval
-   **State Management**: Integrates with remote state backends
-   **Multi-Environment Support**: Supports multiple workspaces/environments
-   **Security**: Runs in isolated containers with temporary credentials

## Atlantis Workflow

### 1. Pull Request Creation

When a developer creates a pull request with Terraform changes:

```bash
# Developer workflow
git checkout -b feature/new-vpc
# Make Terraform changes
git add .
git commit -m "Add new VPC configuration"
git push origin feature/new-vpc
# Create pull request on GitHub
```

### 2. Automated Planning

Atlantis automatically detects the PR and runs `terraform plan`:

```
atlantis plan
```

**Output in PR comment:**

```
Ran Plan for dir: `terraform` workspace: `default`

**Plan Results**
Terraform will perform the following actions:

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + cidr_block           = "10.0.0.0/16"
      + enable_dns_hostnames = true
      + enable_dns_support   = true
      + id                   = (known after apply)
      + tags                 = {
          + "Name" = "main-vpc"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

### 3. Review and Approval

Team members review the plan and approve the changes:

```
atlantis apply
```

**Output in PR comment:**

```
Ran Apply for dir: `terraform` workspace: `default`

**Apply Results**
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:
vpc_id = "vpc-12345678"
```

### 4. Merge and Cleanup

After successful apply, the PR can be merged:

```bash
# Merge the pull request
git checkout main
git pull origin main
```

## Atlantis Configuration

### 1. Repository Configuration (atlantis.yaml)

```yaml
version: 3
projects:
    - name: terraform-workshop
      dir: terraform
      workspace: default
      terraform_version: v1.0.0
      autoplan:
          when_modified: ["*.tf", "../modules/**/*.tf"]
          enabled: true
      apply_requirements: [approved, mergeable]
      workflow: custom
      delete_source_branch_on_merge: true

workflows:
    custom:
        plan:
            steps:
                - run: terraform plan -out=$PLANFILE
        apply:
            steps:
                - run: terraform apply $PLANFILE
```

### 2. Atlantis Server Configuration

```yaml
# atlantis.yaml (server config)
repos:
    - id: /.*/
      apply_requirements: [approved, mergeable]
      allowed_overrides: [apply_requirements, workflow]
      allow_custom_workflows: true

workflows:
    custom:
        plan:
            steps:
                - run: terraform plan -out=$PLANFILE
        apply:
            steps:
                - run: terraform apply $PLANFILE
```

### 3. GitHub Webhook Configuration

```bash
# Webhook URL
https://atlantis.yourdomain.com/events

# Events to send
- Pull request
- Issue comment
- Push
```

## Multi-Environment Support

### Workspace Strategy

```yaml
# atlantis.yaml
projects:
    - name: terraform-workshop-dev
      dir: terraform
      workspace: dev
      autoplan:
          when_modified: ["*.tf"]
          enabled: true

    - name: terraform-workshop-staging
      dir: terraform
      workspace: staging
      autoplan:
          when_modified: ["*.tf"]
          enabled: false # Manual planning only

    - name: terraform-workshop-prod
      dir: terraform
      workspace: prod
      autoplan:
          when_modified: ["*.tf"]
          enabled: false # Manual planning only
      apply_requirements: [approved, mergeable, pbc]
```

### Directory Strategy

```
repository/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
└── modules/
    ├── networking/
    ├── compute/
    └── security/
```

## Security Best Practices

### 1. Access Control

```yaml
# atlantis.yaml
repos:
    - id: /.*/
      apply_requirements: [approved, mergeable]
      allowed_overrides: [apply_requirements, workflow]
      allow_custom_workflows: true
      # Restrict who can apply
      allowed_apply_requirements: [approved, mergeable, pbc]
```

### 2. Credential Management

```bash
# Use AWS IAM roles for Atlantis
aws_iam_role_arn: arn:aws:iam::123456789012:role/atlantis-role

# Or use temporary credentials
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_SESSION_TOKEN=your_session_token
```

### 3. State Security

```hcl
# terraform/backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Common Commands

### Basic Commands

```bash
# Plan changes
atlantis plan

# Apply changes
atlantis apply

# Plan specific directory
atlantis plan -d terraform

# Plan specific workspace
atlantis plan -w staging

# Apply with comment
atlantis apply -- -auto-approve
```

### Advanced Commands

```bash
# Plan with specific variables
atlantis plan -- -var="instance_type=t3.large"

# Plan with variable file
atlantis plan -- -var-file="production.tfvars"

# Destroy resources
atlantis plan -- -destroy

# Import existing resources
atlantis plan -- -import="aws_instance.web:i-12345678"
```

## Integration with CI/CD

### GitHub Actions Integration

```yaml
# .github/workflows/atlantis.yml
name: Atlantis Integration

on:
    pull_request:
        types: [opened, synchronize, closed]

jobs:
    atlantis:
        runs-on: ubuntu-latest
        steps:
            - name: Atlantis Plan
              if: github.event.action == 'opened' || github.event.action == 'synchronize'
              run: |
                  echo "atlantis plan" | gh pr comment ${{ github.event.pull_request.number }} --body -

            - name: Atlantis Apply
              if: github.event.action == 'closed' && github.event.pull_request.merged == true
              run: |
                  echo "atlantis apply" | gh pr comment ${{ github.event.pull_request.number }} --body -
```

### Slack Integration

```yaml
# atlantis.yaml
notifiers:
    - kind: slack
      channel: "#terraform"
      token: $SLACK_TOKEN
      workspace: your-workspace
```

## Troubleshooting

### Common Issues

1. **Webhook Not Received**

    ```bash
    # Check Atlantis logs
    kubectl logs -f deployment/atlantis

    # Verify webhook URL
    curl -X POST https://atlantis.yourdomain.com/events
    ```

2. **Permission Denied**

    ```bash
    # Check AWS credentials
    aws sts get-caller-identity

    # Verify IAM permissions
    aws iam get-role --role-name atlantis-role
    ```

3. **State Lock Issues**

    ```bash
    # Force unlock state
    terraform force-unlock LOCK_ID

    # Check DynamoDB locks
    aws dynamodb scan --table-name terraform-locks
    ```

### Debugging Commands

```bash
# Check Atlantis status
curl https://atlantis.yourdomain.com/health

# View Atlantis logs
docker logs atlantis

# Test Terraform locally
cd terraform
terraform init
terraform plan
```

## Best Practices

### 1. Repository Structure

```
repository/
├── .github/
│   └── workflows/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf
├── modules/
│   ├── networking/
│   ├── compute/
│   └── security/
├── atlantis.yaml
└── README.md
```

### 2. Workflow Design

-   **Automated Planning**: Enable autoplan for development
-   **Manual Approval**: Require approval for production changes
-   **Branch Protection**: Use branch protection rules
-   **Code Review**: Require code review before merge

### 3. State Management

-   **Remote State**: Use S3 or similar for state storage
-   **State Locking**: Use DynamoDB for state locking
-   **State Encryption**: Enable encryption for state files
-   **State Backup**: Regular backups of state files

## Monitoring and Observability

### 1. Atlantis Metrics

```yaml
# atlantis.yaml
metrics:
    enabled: true
    port: 9090
    path: /metrics
```

### 2. Logging

```yaml
# atlantis.yaml
logging:
    level: info
    format: json
```

### 3. Health Checks

```bash
# Health check endpoint
curl https://atlantis.yourdomain.com/health

# Metrics endpoint
curl https://atlantis.yourdomain.com/metrics
```

## Next Steps

After setting up Atlantis:

1. **Configure Webhooks**: Set up GitHub/GitLab webhooks
2. **Set Up Environments**: Configure multiple environments
3. **Implement Security**: Add access controls and encryption
4. **Monitor Operations**: Set up monitoring and alerting
5. **Document Procedures**: Create runbooks and procedures

## Resources

-   [Atlantis Documentation](https://www.runatlantis.io/docs/)
-   [Atlantis GitHub Repository](https://github.com/runatlantis/atlantis)
-   [GitOps Principles](https://www.gitops.tech/)
-   [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
