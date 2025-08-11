# Terraform Atlantis Workshop - Overview

## 🎯 Workshop Objectives

This comprehensive workshop teaches you how to build, deploy, and manage AWS infrastructure using modern DevOps practices. You'll learn Infrastructure as Code (IaC) with Terraform, GitOps workflows with Atlantis, and compliance automation.

### **What You'll Learn**

1. **Infrastructure as Code (IaC)**

    - Write Terraform configurations for AWS resources
    - Manage infrastructure state and versioning
    - Implement best practices for IaC

2. **GitOps with Atlantis**

    - Set up automated infrastructure deployments
    - Configure GitHub webhooks for pull request automation
    - Implement policy enforcement in GitOps workflows

3. **Compliance and Security**

    - Enforce infrastructure compliance policies
    - Test and validate policy violations
    - Implement security best practices

4. **Monitoring and Observability**

    - Set up CloudWatch monitoring
    - Configure logging and alerting
    - Monitor costs and performance

5. **Testing and Validation**
    - Test infrastructure locally with LocalStack
    - Validate compliance policies
    - Perform integration testing

## 🏗️ What You'll Build

### **Infrastructure Components**

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Infrastructure                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   VPC Network   │    │   Public Subnet │                │
│  │   (10.0.0.0/16) │    │  (10.0.1.0/24)  │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                        │
│           │                       ▼                        │
│           │              ┌─────────────────┐                │
│           │              │   Web Server    │                │
│           │              │   (EC2 t3.micro)│                │
│           │              │   + Apache      │                │
│           │              └─────────────────┘                │
│           │                       │                        │
│           ▼                       │                        │
│  ┌─────────────────┐              │                        │
│  │  Private Subnet │              │                        │
│  │  (10.0.2.0/24)  │              │                        │
│  └─────────────────┘              │                        │
│           │                       │                        │
│           ▼                       ▼                        │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   S3 Buckets    │    │  Security Groups│                │
│  │   + Encryption  │    │  + IAM Roles    │                │
│  │   + Versioning  │    │  + CloudWatch   │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

### **Key Features**

-   **Multi-tier Architecture**: Public and private subnets for security
-   **Web Application**: Apache web server with custom content
-   **Secure Storage**: S3 buckets with encryption and versioning
-   **Monitoring**: CloudWatch logs and metrics
-   **Compliance**: Automated policy validation
-   **GitOps**: Automated deployments via Atlantis

## 🎓 Learning Outcomes

By the end of this workshop, you will be able to:

### **Technical Skills**

-   ✅ Write and manage Terraform configurations
-   ✅ Deploy infrastructure to AWS
-   ✅ Set up GitOps workflows with Atlantis
-   ✅ Implement compliance policies
-   ✅ Monitor and troubleshoot infrastructure
-   ✅ Test infrastructure locally and in production

### **DevOps Practices**

-   ✅ Infrastructure as Code (IaC)
-   ✅ GitOps and automated deployments
-   ✅ Policy as Code and compliance automation
-   ✅ Testing and validation strategies
-   ✅ Monitoring and observability
-   ✅ Security best practices

### **Real-world Experience**

-   ✅ Production-like infrastructure deployment
-   ✅ Policy violation testing and fixing
-   ✅ Cost monitoring and optimization
-   ✅ Troubleshooting and debugging
-   ✅ Cleanup and resource management

## 📋 Prerequisites

### **Required Tools**

-   **AWS Account**: With appropriate permissions
-   **AWS CLI**: Version 2.x or later
-   **Terraform**: Version 1.6.0 or later
-   **Git**: For version control
-   **Docker**: For running Atlantis
-   **PowerShell** (Windows) or **Bash** (Linux/Mac)

### **Required Knowledge**

-   Basic understanding of AWS services (EC2, S3, VPC)
-   Familiarity with command line interfaces
-   Basic Git knowledge (commit, push, pull requests)
-   Understanding of networking concepts

### **AWS Permissions**

Your AWS account needs permissions for:

-   EC2 (instances, security groups, VPC)
-   S3 (buckets, encryption, versioning)
-   IAM (roles, policies)
-   CloudWatch (logs, metrics)
-   VPC (subnets, route tables, internet gateway)

## ⏱️ Workshop Timeline

| Phase                    | Duration | Description                                   |
| ------------------------ | -------- | --------------------------------------------- |
| **Setup**                | 30 min   | Environment preparation and tool installation |
| **Local Development**    | 45 min   | LocalStack setup and local testing            |
| **AWS Deployment**       | 30 min   | Production infrastructure deployment          |
| **Compliance Testing**   | 30 min   | Policy validation and violation testing       |
| **Atlantis Setup**       | 45 min   | GitOps workflow configuration                 |
| **Testing & Validation** | 30 min   | End-to-end testing and validation             |
| **Cleanup**              | 15 min   | Resource cleanup and cost optimization        |

**Total Time**: ~3.5 hours

## 🏆 Success Criteria

You'll know you've successfully completed the workshop when you can:

1. **Deploy Infrastructure**: Successfully deploy all components to AWS
2. **Test Compliance**: Create and fix policy violations
3. **GitOps Workflow**: Use Atlantis to automate deployments
4. **Monitor Resources**: Set up and use monitoring tools
5. **Clean Up**: Safely destroy all resources

## 🚀 Getting Started

1. **Read this overview** to understand what you'll build
2. **Follow the setup guide** (01-SETUP.md) to prepare your environment
3. **Review the infrastructure** (02-INFRASTRUCTURE.md) to understand the code
4. **Start with local development** (03-LOCALSTACK.md)
5. **Deploy to AWS** (04-AWS-DEPLOYMENT.md)
6. **Test compliance** (05-COMPLIANCE.md)
7. **Set up GitOps** (06-ATLANTIS.md)
8. **Validate everything** (07-TESTING.md)
9. **Monitor and optimize** (08-MONITORING.md)
10. **Clean up** (11-CLEANUP.md)

## 📚 Additional Resources

### **Documentation**

-   [Terraform Documentation](https://www.terraform.io/docs)
-   [AWS Documentation](https://docs.aws.amazon.com/)
-   [Atlantis Documentation](https://www.runatlantis.io/docs/)

### **Best Practices**

-   [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
-   [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
-   [GitOps Best Practices](https://www.gitops.tech/)

### **Community**

-   [Terraform Community](https://discuss.hashicorp.com/c/terraform-core)
-   [AWS Community](https://aws.amazon.com/developer/community/)
-   [Atlantis Community](https://github.com/runatlantis/atlantis)

## 🆘 Support

If you encounter issues during the workshop:

1. **Check the troubleshooting guide** (09-TROUBLESHOOTING.md)
2. **Review the error messages** carefully
3. **Verify your AWS credentials** and permissions
4. **Check the prerequisites** are all installed
5. **Create an issue** in the workshop repository

---

**Ready to start?** Let's begin with the setup guide in [01-SETUP.md](01-SETUP.md)!
