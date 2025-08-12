# GitHub Integration

## Overview

This guide covers the integration of GitHub with Terraform and Atlantis for implementing GitOps workflows. It includes repository setup, webhook configuration, branch protection, and automated workflows for infrastructure management.

## GitHub Repository Setup

### 1. Repository Structure

```
terraform-atlantis-workshop/
├── .github/
│   ├── workflows/
│   │   ├── terraform-plan.yml
│   │   ├── terraform-apply.yml
│   │   └── security-scan.yml
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── PULL_REQUEST_TEMPLATE.md
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── modules/
│   │   ├── networking/
│   │   ├── compute/
│   │   └── security/
│   └── shared/
├── docs/
├── scripts/
├── atlantis.yaml
├── .gitignore
├── README.md
└── LICENSE
```

### 2. Repository Configuration

#### .gitignore

```gitignore
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
*.tfvars
!example.tfvars
!*.auto.tfvars

# Atlantis
.terraform.tfstate.backup
.terraform.tfstate.backup.*
.terraform.tfstate.backup.*.backup

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Environment variables
.env
.env.local
.env.*.local

# Temporary files
*.tmp
*.temp
```

#### Branch Protection Rules

Configure branch protection for the main branch:

1. Go to **Settings** > **Branches**
2. Click **Add rule**
3. Set **Branch name pattern** to `main`
4. Enable the following options:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (set to 2)
   - ✅ Dismiss stale PR approvals when new commits are pushed
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Include administrators
   - ✅ Restrict pushes that create files
   - ✅ Restrict deletions

## GitHub Actions Workflows

### 1. Terraform Plan Workflow

```yaml
# .github/workflows/terraform-plan.yml
name: Terraform Plan

on:
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-plan.yml'

env:
  TF_VERSION: '1.0.0'
  AWS_REGION: 'us-west-2'

jobs:
  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        environment: [dev, staging, prod]
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: ${{ env.TF_VERSION }}
        
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
        
    - name: Terraform Init
      working-directory: terraform/environments/${{ matrix.environment }}
      run: |
        terraform init
        terraform workspace select ${{ matrix.environment }} || terraform workspace new ${{ matrix.environment }}
        
    - name: Terraform Format Check
      working-directory: terraform/environments/${{ matrix.environment }}
      run: terraform fmt -check
      
    - name: Terraform Validate
      working-directory: terraform/environments/${{ matrix.environment }}
      run: terraform validate
      
    - name: Terraform Plan
      working-directory: terraform/environments/${{ matrix.environment }}
      run: |
        terraform plan -out=tfplan
        terraform show -no-color tfplan > plan.txt
        
    - name: Comment PR
      uses: actions/github-script@v6
      with:
        script: |
          const fs = require('fs');
          const plan = fs.readFileSync('terraform/environments/${{ matrix.environment }}/plan.txt', 'utf8');
          
          const comment = `## Terraform Plan for ${{ matrix.environment }}
          
          <details><summary>Show Plan</summary>
          
          \`\`\`hcl
          ${plan}
          \`\`\`
          
          </details>`;
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: comment
          });
```

### 2. Terraform Apply Workflow

```yaml
# .github/workflows/terraform-apply.yml
name: Terraform Apply

on:
  push:
    branches: [ main ]
    paths:
      - 'terraform/**'

env:
  TF_VERSION: '1.0.0'
  AWS_REGION: 'us-west-2'

jobs:
  terraform-apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        environment: [dev, staging, prod]
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: ${{ env.TF_VERSION }}
        
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
        
    - name: Terraform Init
      working-directory: terraform/environments/${{ matrix.environment }}
      run: |
        terraform init
        terraform workspace select ${{ matrix.environment }}
        
    - name: Terraform Apply
      working-directory: terraform/environments/${{ matrix.environment }}
      run: terraform apply -auto-approve
      
    - name: Notify Slack
      if: matrix.environment == 'prod'
      uses: 8398a7/action-slack@v3
      with:
        status: success
        text: "Production infrastructure deployed successfully!"
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### 3. Security Scanning Workflow

```yaml
# .github/workflows/security-scan.yml
name: Security Scan

on:
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'terraform/**'

jobs:
  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Run Checkov
      uses: bridgecrewio/checkov-action@master
      with:
        directory: terraform/
        framework: terraform
        output_format: sarif
        output_file_path: checkov.sarif
        
    - name: Upload SARIF file
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: checkov.sarif
        
    - name: Run TFLint
      uses: terraform-linters/setup-tflint@v3
      with:
        tflint_version: v0.44.1
        
    - name: TFLint
      run: |
        cd terraform/
        tflint --init
        tflint
```

## Atlantis Integration

### 1. Atlantis Configuration

```yaml
# atlantis.yaml
version: 3

projects:
- name: terraform-workshop-dev
  dir: terraform/environments/dev
  workspace: default
  terraform_version: v1.0.0
  autoplan:
    when_modified: ["*.tf", "../modules/**/*.tf"]
    enabled: true
  apply_requirements: [approved, mergeable]
  workflow: custom

- name: terraform-workshop-staging
  dir: terraform/environments/staging
  workspace: default
  terraform_version: v1.0.0
  autoplan:
    when_modified: ["*.tf", "../modules/**/*.tf"]
    enabled: false  # Manual planning only
  apply_requirements: [approved, mergeable]
  workflow: custom

- name: terraform-workshop-prod
  dir: terraform/environments/prod
  workspace: default
  terraform_version: v1.0.0
  autoplan:
    when_modified: ["*.tf", "../modules/**/*.tf"]
    enabled: false  # Manual planning only
  apply_requirements: [approved, mergeable, pbc]
  workflow: custom

workflows:
  custom:
    plan:
      steps:
      - run: terraform plan -out=$PLANFILE
    apply:
      steps:
      - run: terraform apply $PLANFILE
```

### 2. Webhook Configuration

Configure GitHub webhook for Atlantis:

1. Go to **Settings** > **Webhooks**
2. Click **Add webhook**
3. Set **Payload URL** to your Atlantis webhook endpoint
4. Set **Content type** to `application/json`
5. Select events:
   - ✅ Pull requests
   - ✅ Issue comments
   - ✅ Pushes
6. Click **Add webhook**

### 3. GitHub App Integration

For better integration, consider using GitHub App:

```yaml
# atlantis.yaml
repos:
  - id: /.*/
    apply_requirements: [approved, mergeable]
    allowed_overrides: [apply_requirements, workflow]
    allow_custom_workflows: true

# GitHub App configuration
github:
  app_id: "123456"
  app_key_file: "/path/to/private-key.pem"
  webhook_secret: "your-webhook-secret"
```

## Pull Request Templates

### 1. Pull Request Template

```markdown
# .github/PULL_REQUEST_TEMPLATE.md
## Description

Brief description of the changes made.

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Infrastructure change
- [ ] Documentation update

## Environment

- [ ] Development
- [ ] Staging
- [ ] Production

## Checklist

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published in downstream modules

## Terraform Changes

- [ ] I have run `terraform fmt` on all changed files
- [ ] I have run `terraform validate` on all changed directories
- [ ] I have run `terraform plan` and reviewed the output
- [ ] I have updated the documentation if needed

## Security Considerations

- [ ] I have reviewed the security implications of my changes
- [ ] I have ensured proper access controls are in place
- [ ] I have validated that sensitive data is properly handled

## Testing

- [ ] I have tested my changes in a development environment
- [ ] I have validated that the infrastructure deploys correctly
- [ ] I have verified that the application functions as expected

## Screenshots (if applicable)

Add screenshots to help explain your changes.

## Additional Notes

Any additional information or context that reviewers should know.
```

### 2. Issue Templates

#### Bug Report Template

```markdown
# .github/ISSUE_TEMPLATE/bug_report.md
---
name: Bug report
about: Create a report to help us improve
title: ''
labels: 'bug'
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
 - OS: [e.g. Ubuntu 20.04]
 - Terraform Version: [e.g. 1.0.0]
 - AWS CLI Version: [e.g. 2.0.0]
 - Atlantis Version: [e.g. 0.19.0]

**Additional context**
Add any other context about the problem here.
```

#### Feature Request Template

```markdown
# .github/ISSUE_TEMPLATE/feature_request.md
---
name: Feature request
about: Suggest an idea for this project
title: ''
labels: 'enhancement'
assignees: ''

---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
```

## Branch Strategy

### 1. Git Flow

```
main (production)
├── develop (integration)
├── feature/new-vpc
├── feature/security-updates
└── hotfix/critical-fix
```

### 2. Branch Naming Conventions

- **Feature branches**: `feature/description`
- **Bug fixes**: `fix/description`
- **Hotfixes**: `hotfix/description`
- **Infrastructure changes**: `infra/description`
- **Documentation**: `docs/description`

### 3. Commit Message Format

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks
- `infra`: Infrastructure changes

## Security Best Practices

### 1. Secrets Management

Store sensitive information in GitHub Secrets:

1. Go to **Settings** > **Secrets and variables** > **Actions**
2. Add the following secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `ATLANTIS_WEBHOOK_SECRET`
   - `SLACK_WEBHOOK_URL`

### 2. Code Scanning

Enable GitHub Code Scanning:

1. Go to **Security** > **Code security and analysis**
2. Enable:
   - ✅ Code scanning
   - ✅ Secret scanning
   - ✅ Dependency review

### 3. Dependabot Configuration

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "terraform"
    directory: "/terraform"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
```

## Monitoring and Notifications

### 1. Status Checks

Configure required status checks:

1. Go to **Settings** > **Branches**
2. Edit branch protection rule for `main`
3. Under **Status checks that are required**:
   - ✅ `terraform-plan`
   - ✅ `security-scan`
   - ✅ `terraform-validate`

### 2. Slack Integration

```yaml
# .github/workflows/notify.yml
name: Notify Slack

on:
  pull_request:
    types: [opened, synchronize, closed]

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
    - name: Notify Slack
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        text: |
          Pull Request: ${{ github.event.pull_request.title }}
          Author: ${{ github.event.pull_request.user.login }}
          URL: ${{ github.event.pull_request.html_url }}
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### 3. Email Notifications

Configure email notifications for:
- Pull request reviews
- Security alerts
- Dependabot updates
- Repository activity

## Troubleshooting

### 1. Common Issues

#### Webhook Not Received
```bash
# Check webhook delivery
# Go to Settings > Webhooks > View recent deliveries

# Test webhook manually
curl -X POST https://your-atlantis-domain.com/events \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -d '{"action": "opened"}'
```

#### Permission Denied
```bash
# Check GitHub App permissions
# Ensure the app has access to:
# - Repository contents
# - Pull requests
# - Issues
# - Commit statuses
```

#### Atlantis Not Responding
```bash
# Check Atlantis logs
kubectl logs -f deployment/atlantis

# Verify webhook configuration
# Check if webhook URL is correct and accessible
```

### 2. Debugging Commands

```bash
# Test GitHub API access
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo

# Check webhook configuration
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo/hooks

# Test Atlantis webhook endpoint
curl -X POST https://atlantis.yourdomain.com/health
```

## Best Practices

### 1. Repository Management

- **Branch Protection**: Always protect main branch
- **Code Review**: Require at least 2 approvals
- **Status Checks**: Require all checks to pass
- **Linear History**: Enable "Squash and merge" or "Rebase and merge"

### 2. Security

- **Secrets**: Never commit secrets to repository
- **Access Control**: Use least privilege principle
- **Audit Logs**: Regularly review audit logs
- **Dependencies**: Keep dependencies updated

### 3. Workflow

- **Small PRs**: Keep pull requests small and focused
- **Clear Descriptions**: Write clear PR descriptions
- **Testing**: Always test changes before merging
- **Documentation**: Update documentation with changes

## Next Steps

After setting up GitHub integration:

1. **Configure Webhooks**: Set up webhooks for Atlantis
2. **Set Up Branch Protection**: Configure branch protection rules
3. **Enable Security Features**: Enable code scanning and secret scanning
4. **Test Workflows**: Test all GitHub Actions workflows
5. **Monitor Operations**: Set up monitoring and notifications

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Webhooks](https://docs.github.com/en/developers/webhooks-and-events)
- [Atlantis GitHub Integration](https://www.runatlantis.io/docs/github-compatibility.html)
- [Terraform GitHub Actions](https://www.terraform.io/docs/cloud/run/automation.html)
- [GitHub Security Best Practices](https://docs.github.com/en/github/security)
