# Terraform Atlantis Workshop - Scripts Directory

This directory contains all the PowerShell scripts for the Terraform Atlantis Workshop, organized in a numbered workflow system for easy execution and maintenance.

## 📁 Directory Structure

```
scripts/
├── 00-setup-env.ps1                  # Environment setup and .env generation
├── 01-validate-environment.ps1       # Environment validation
├── 02-setup-github-actions.ps1       # GitHub Actions setup
├── 03-deploy-infrastructure.ps1      # Infrastructure deployment
├── 04-health-monitoring.ps1          # Health monitoring
├── 05-cost-monitoring.ps1            # Cost monitoring
├── 06-rollback-procedures.ps1        # Emergency rollback
├── 07-cleanup-infrastructure.ps1     # Infrastructure cleanup
├── 08-complete-workflow.ps1          # Master workflow script (orchestrates all others)
└── README.md                         # This file
```

## 🚀 Quick Start

### Option 1: Run Complete Workflow

```powershell
# Run the complete workshop workflow
.\scripts\08-complete-workflow.ps1

# Run with custom parameters
.\scripts\08-complete-workflow.ps1 -SkipGitHubSetup -AutoConfirm
```

### Option 2: Run Individual Scripts

```powershell
# Step 1: Validate environment
.\scripts\01-validate-environment.ps1

# Step 2: Setup GitHub Actions
.\scripts\02-setup-github-actions.ps1

# Step 3: Deploy infrastructure
.\scripts\03-deploy-infrastructure.ps1

# Step 4: Monitor health
.\scripts\04-health-monitoring.ps1

# Step 5: Monitor costs
.\scripts\05-cost-monitoring.ps1
```

## 📋 Script Details

### 00-setup-env.ps1

**Purpose**: Automatically sets up the environment and generates the .env file with proper configuration.

**Features**:

-   Auto-detects existing AWS credentials and Git configuration
-   Interactive mode for entering new credentials securely
-   Validates AWS credentials before creating .env
-   Auto-generates complete .env file with all required variables
-   Environment validation for all required tools

**Parameters**:

-   `-Force`: Overwrite existing .env file
-   `-Interactive`: Enter credentials interactively

**Usage**:

```powershell
.\scripts\00-setup-env.ps1 -Interactive
```

### 08-complete-workflow.ps1

**Purpose**: Master script that orchestrates the execution of all other scripts in the correct order.

**Parameters**:

-   `-SkipValidation`: Skip environment validation
-   `-SkipGitHubSetup`: Skip GitHub Actions setup
-   `-SkipDeployment`: Skip infrastructure deployment
-   `-SkipMonitoring`: Skip health and cost monitoring
-   `-IncludeRollback`: Include rollback procedures
-   `-IncludeCleanup`: Include infrastructure cleanup
-   `-AutoConfirm`: Skip confirmation prompts

**Usage**:

```powershell
.\scripts\08-complete-workflow.ps1 -AutoConfirm
```

### 01-validate-environment.ps1

**Purpose**: Validates that all required tools and configurations are in place.

**Checks**:

-   `.env` file existence
-   GitHub Actions workflow file
-   AWS CLI installation
-   Terraform installation

**Usage**:

```powershell
.\scripts\01-validate-environment.ps1
```

### 02-setup-github-actions.ps1

**Purpose**: Configures GitHub Actions for Terraform automation.

**Features**:

-   Creates GitHub Actions workflow
-   Sets up Terraform plan/apply automation
-   Configures Atlantis integration

**Usage**:

```powershell
.\scripts\02-setup-github-actions.ps1
```

### 03-deploy-infrastructure.ps1

**Purpose**: Deploys the Terraform infrastructure to AWS.

**Features**:

-   Initializes Terraform
-   Plans infrastructure changes
-   Applies infrastructure
-   Validates deployment

**Usage**:

```powershell
.\scripts\03-deploy-infrastructure.ps1
```

### 04-health-monitoring.ps1

**Purpose**: Monitors the health and status of deployed infrastructure.

**Features**:

-   EC2 instance health checks
-   Load balancer status
-   Database connectivity
-   Application endpoint testing

**Usage**:

```powershell
.\scripts\04-health-monitoring.ps1
```

### 05-cost-monitoring.ps1

**Purpose**: Monitors and reports AWS costs for the deployed infrastructure.

**Features**:

-   Cost estimation
-   Resource cost breakdown
-   Cost alerts
-   Cost optimization suggestions

**Usage**:

```powershell
.\scripts\05-cost-monitoring.ps1
```

### 06-rollback-procedures.ps1

**Purpose**: Provides emergency rollback capabilities for infrastructure changes.

**Rollback Types**:

-   **Git-based**: Revert to previous Git commit
-   **State-based**: Restore from Terraform state backup
-   **Emergency**: Destroy and recreate from backup

**Usage**:

```powershell
# Git rollback
.\scripts\06-rollback-procedures.ps1 -RollbackType git

# State rollback
.\scripts\06-rollback-procedures.ps1 -RollbackType state

# Emergency rollback
.\scripts\06-rollback-procedures.ps1 -RollbackType emergency -Force
```

### 07-cleanup-infrastructure.ps1

**Purpose**: Cleans up all deployed infrastructure and resources.

**Features**:

-   Terraform destroy
-   Resource cleanup
-   State file cleanup
-   Backup preservation

**Usage**:

```powershell
.\scripts\07-cleanup-infrastructure.ps1
```

## 🔧 Script Organization Benefits

### 1. **Numbered Workflow**

-   Clear execution order (01 → 02 → 03 → ...)
-   Easy to understand progression
-   Prevents execution order mistakes

### 2. **Modular Design**

-   Each script has a single responsibility
-   Can be run independently
-   Easy to debug and maintain

### 3. **Master Orchestration**

-   `00-complete-workflow.ps1` manages the entire process
-   Handles dependencies between scripts
-   Provides progress tracking and error handling

### 4. **Flexible Execution**

-   Run complete workflow or individual steps
-   Skip specific steps when needed
-   Customize execution with parameters

## 📚 Additional Files

### rollback-original.ps1

This is the original rollback script that was in the `scripts/` folder. It has been preserved as a reference and contains additional rollback features that may be useful for advanced scenarios.

## 🛠️ Troubleshooting

### Common Issues

1. **Script not found**: Ensure you're running from the project root directory
2. **Permission denied**: Run PowerShell as Administrator or adjust execution policy
3. **AWS credentials**: Ensure AWS CLI is configured with valid credentials
4. **Terraform errors**: Check Terraform configuration and state files

### Debug Mode

Add `-Verbose` parameter to any script for detailed output:

```powershell
.\scripts\01-validate-environment.ps1 -Verbose
```

## 📖 Related Documentation

-   `../WORKFLOW-GUIDE.md` - Complete workflow documentation
-   `../docs/` - Additional workshop documentation
-   `../README.md` - Main project documentation

## 🤝 Contributing

When adding new scripts:

1. Follow the numbered naming convention
2. Update this README.md
3. Update the master workflow script
4. Test thoroughly before committing

---

**Note**: All scripts are designed to be run from the project root directory, not from within the `scripts/` folder.
