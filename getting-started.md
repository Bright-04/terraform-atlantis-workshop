# Environment Provisioning Automation Workshop

## Quick Start Guide

### Immediate Next Steps (Start Here!)

1. **Set up your AWS environment** (Priority 1)
   - Create AWS account if you don't have one
   - Configure billing alerts
   - Create IAM user for Terraform with appropriate permissions

2. **Install required tools** (Priority 1)
   ```powershell
   # Install Terraform
   choco install terraform

   # Install AWS CLI
   choco install awscli

   # Verify installations
   terraform version
   aws --version
   ```

3. **Configure AWS credentials** (Priority 1)
   ```powershell
   aws configure
   ```

4. **Create your first Terraform configuration** (Priority 2)
   - Start with the `/terraform` directory
   - Create a basic VPC and EC2 instance
   - Test the Terraform workflow

5. **Set up version control** (Priority 2)
   - Initialize git repository
   - Create proper .gitignore for Terraform
   - Push to GitHub/GitLab

### Project Structure
```
IT WORKSHOP/
├── terraform/          # Terraform configurations
├── atlantis/           # Atlantis configuration files
├── monitoring/         # Monitoring and alerting setup
├── docs/              # Hugo documentation
├── workshop-plan.md   # Detailed workshop plan
└── readme.md          # This file
```

### Key Resources to Study
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Atlantis Documentation](https://www.runatlantis.io/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### Workshop Timeline
- **Phase 1** (Weeks 1-2): Foundation Setup
- **Phase 2** (Weeks 3-4): Atlantis Integration
- **Phase 3** (Weeks 5-6): Cost Controls & Monitoring
- **Phase 4** (Weeks 7-8): Compliance & Operations
- **Phase 5** (Weeks 9-10): Documentation & Finalization

See `workshop-plan.md` for detailed breakdown of each phase.

### Success Criteria
- Automated environment provisioning with approval workflows
- Cost monitoring and controls implemented
- Compliance validation automated
- Complete documentation with Hugo
- Operational procedures documented

### Getting Help
- Review the detailed plan in `workshop-plan.md`
- Check AWS documentation for service-specific guidance
- Use Terraform and Atlantis community forums
- Consider AWS support if needed for complex scenarios
