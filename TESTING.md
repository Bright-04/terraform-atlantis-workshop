# Atlantis Workflow Testing Guide

## 🧪 Testing Your Atlantis Integration

### Prerequisites
- [ ] GitHub Personal Access Token created
- [ ] Webhook configured in GitHub repository
- [ ] Atlantis container running
- [ ] LocalStack container running

### Test Workflow Steps

#### 1. 🔄 Basic Workflow Test

```bash
# Create a test branch
git checkout -b test-atlantis-integration

# Make a simple change to terraform/variables.tf
# For example, change a default value or add a comment

# Commit and push
git add .
git commit -m "test: update terraform configuration for Atlantis testing"
git push origin test-atlantis-integration
```

#### 2. 🔀 Create Pull Request

1. Go to GitHub and create a Pull Request
2. Atlantis should automatically comment with a plan
3. Expected comment format:
   ```
   Ran Plan for project: terraform-atlantis-workshop

   <details><summary>Show Output</summary>

   ```
   Terraform plan output...
   ```

   </details>

   * :repeat: To **plan** this project again, comment: `atlantis plan`
   * :mag_right: To **apply** this project, comment: `atlantis apply`
   ```

#### 3. 📋 Review Process

1. **Review the plan output** in Atlantis comment
2. **Approve the PR** (required by apply_requirements)
3. **Comment `atlantis apply`** to trigger apply
4. **Monitor the apply process** in Atlantis UI

#### 4. 🎯 Expected Behavior

- [ ] Atlantis automatically plans on PR creation
- [ ] Plan shows LocalStack resources
- [ ] Apply requires PR approval
- [ ] Apply succeeds with LocalStack
- [ ] UI shows detailed logs

### Common Commands

```bash
# Manual plan
atlantis plan

# Manual apply (requires approval)
atlantis apply

# Plan specific project
atlantis plan -p terraform-atlantis-workshop

# Apply specific project
atlantis apply -p terraform-atlantis-workshop
```

### 🔍 Troubleshooting

#### Atlantis Not Commenting
- Check webhook delivery in GitHub settings
- Verify webhook secret matches
- Check Atlantis logs: `docker-compose logs atlantis`

#### Plan Fails
- Verify LocalStack is running
- Check Terraform configuration
- Review atlantis.yaml syntax

#### Apply Fails
- Ensure PR is approved
- Check apply_requirements in atlantis.yaml
- Verify LocalStack endpoints are accessible

### 📊 Monitoring

#### Atlantis UI
- Access: http://localhost:4141
- Shows active locks, plan history, apply status

#### Container Logs
```bash
# Real-time logs
docker-compose logs -f atlantis

# Specific timeframe
docker-compose logs --since 10m atlantis
```

#### LocalStack Health
```bash
# Check LocalStack status
curl http://localhost:4566/health

# Test specific service
curl http://localhost:4566/_localstack/health
```

### 🔒 Security Checklist

- [ ] GitHub token has minimal required permissions
- [ ] Webhook secret is secure and not in version control
- [ ] Repository allowlist is properly configured
- [ ] Branch protection rules are enabled
- [ ] CODEOWNERS file is configured

### 🎉 Success Criteria

A successful test should demonstrate:
1. **Automatic planning** on PR creation
2. **Approval requirement** enforcement
3. **Successful apply** to LocalStack
4. **Proper logging** and UI feedback
5. **Resource cleanup** capability

### 📚 Next Steps

After successful testing:
1. Configure production webhooks
2. Set up monitoring and alerting
3. Implement policy as code
4. Add cost estimation
5. Create runbooks for common scenarios
