# GitHub Actions Workflow Explanation

## 🚀 **Workflow Overview**

The Terraform Atlantis Workshop uses a comprehensive GitHub Actions workflow that provides **GitOps automation** with **safety checks** and **compliance validation**.

---

## 📋 **Workflow Jobs**

### **1. terraform-plan** ✅ **Always Runs on PR**
**Purpose**: Generate and review Terraform execution plan
**When**: On every Pull Request
**What it does**:
- ✅ Initializes Terraform
- ✅ Validates configuration
- ✅ Generates execution plan
- ✅ Parses plan for resource changes (add/modify/destroy counts)
- ✅ Comments PR with detailed plan summary
- ✅ Uploads plan file for later use

**Output**: Detailed comment showing:
- 📊 Resource changes (add/modify/destroy counts)
- 🔍 Change details
- 📋 Workflow status
- 🔒 Compliance status
- 📝 Next steps

### **2. terraform-apply** ⏳ **Runs on Merge to Main**
**Purpose**: Apply infrastructure changes
**When**: Only when PR is merged to `main` or `aws-production-deployment` branches
**Why skipped on PR**: Safety - prevents accidental infrastructure changes
**What it does**:
- ✅ Downloads plan file from previous step
- ✅ Applies Terraform changes
- ✅ Captures infrastructure outputs
- ✅ Comments with deployment results

**Output**: Comment showing:
- 🎉 Deployment success status
- 📊 Infrastructure summary
- 🔧 Resources managed
- 🔒 Compliance status
- 📋 Workflow status

### **3. health-check** ⏳ **Runs After Apply**
**Purpose**: Verify infrastructure health
**When**: Only after `terraform-apply` completes successfully
**Why skipped on PR**: No infrastructure to check yet
**What it does**:
- ✅ Verifies EC2 instances are running
- ✅ Checks S3 buckets exist
- ✅ Validates VPC networking
- ✅ Tests web server accessibility
- ✅ Comments with health status

**Output**: Comment showing:
- 🔍 Health verification results
- 📊 Infrastructure status
- 📋 Complete workflow status
- 🎯 Deployment summary

### **4. cleanup** ⏸️ **Manual Trigger Only**
**Purpose**: Destroy infrastructure
**When**: Only when manually triggered with `destroy` action
**Why skipped**: Safety - prevents accidental infrastructure deletion
**What it does**:
- ✅ Destroys all Terraform-managed resources
- ✅ Cleans up AWS resources
- ✅ Used for workshop cleanup

---

## 🔍 **Why Jobs Are Skipped**

### **On Pull Requests:**
- ✅ **terraform-plan**: Runs (safety review)
- ⏸️ **terraform-apply**: Skipped (prevents accidental changes)
- ⏸️ **health-check**: Skipped (no infrastructure to check)
- ⏸️ **cleanup**: Skipped (manual trigger only)

### **On Merge to Main:**
- ✅ **terraform-plan**: Runs (safety review)
- ✅ **terraform-apply**: Runs (applies changes)
- ✅ **health-check**: Runs (verifies deployment)
- ⏸️ **cleanup**: Skipped (manual trigger only)

### **Manual Cleanup:**
- ⏸️ **terraform-plan**: Skipped (not needed for destroy)
- ⏸️ **terraform-apply**: Skipped (not needed for destroy)
- ⏸️ **health-check**: Skipped (not needed for destroy)
- ✅ **cleanup**: Runs (destroys infrastructure)

---

## 📊 **Enhanced Plan Comments**

### **What You'll See:**

#### **No Changes Detected:**
```
## Terraform Plan 📋

**✅ No Changes Detected**
- Infrastructure is up to date

**🔍 Change Details:**
No resources will be added, modified, or destroyed.

**📋 Workflow Status:**
- ✅ terraform-plan: Completed successfully
- ⏳ terraform-apply: Will run when PR is merged to main
- ⏳ health-check: Will run after apply completes
- ⏸️ cleanup: Manual trigger only (for destroy operations)
```

#### **Changes Detected:**
```
## Terraform Plan 📋

**📊 Resource Changes:**
- ➕ **2** to add
- 🔄 **1** to change
- 🗑️ **0** to destroy

**🔍 Change Details:**
- **New Resources:** 2 resource(s) will be created
- **Modified Resources:** 1 resource(s) will be updated

**📋 Workflow Status:**
- ✅ terraform-plan: Completed successfully
- ⏳ terraform-apply: Will run when PR is merged to main
- ⏳ health-check: Will run after apply completes
- ⏸️ cleanup: Manual trigger only (for destroy operations)
```

---

## 🎯 **Workflow Benefits**

### **1. Safety First**
- **Plan Review**: All changes are reviewed before application
- **Branch Protection**: Changes only apply when merged to main
- **Manual Cleanup**: Infrastructure destruction requires explicit action

### **2. Complete Visibility**
- **Detailed Comments**: Every step provides comprehensive feedback
- **Resource Counts**: Clear indication of what will change
- **Workflow Status**: Shows which jobs ran and which were skipped

### **3. Compliance & Security**
- **Policy Validation**: Enforces cost controls and security policies
- **Audit Trail**: Complete history of all infrastructure changes
- **Approval Process**: Requires PR review before changes

### **4. Health Verification**
- **Post-Deployment Checks**: Verifies infrastructure is working
- **Web Server Testing**: Ensures applications are accessible
- **Resource Validation**: Confirms all resources are properly deployed

---

## 🚨 **Troubleshooting**

### **If terraform-apply is skipped:**
- **Check**: Ensure you're merging to `main` or `aws-production-deployment`
- **Check**: Verify the PR was approved and merged
- **Check**: Look for any workflow failures in the Actions tab

### **If health-check is skipped:**
- **Check**: Ensure terraform-apply completed successfully
- **Check**: Verify infrastructure was actually deployed
- **Check**: Look for any errors in the apply step

### **If cleanup is skipped:**
- **This is normal**: Cleanup only runs when manually triggered
- **To trigger cleanup**: Use the "Run workflow" button with `destroy` action
- **Warning**: This will destroy all infrastructure!

---

## 📈 **Workflow Diagram**

```
Pull Request Created
        ↓
   terraform-plan ✅
        ↓
   PR Review & Approval
        ↓
   Merge to Main
        ↓
   terraform-apply ✅
        ↓
   health-check ✅
        ↓
   Deployment Complete!

cleanup ⏸️ (Manual Only)
```

---

## 🎉 **Success Indicators**

### **Complete Workflow Success:**
- ✅ **terraform-plan**: Shows resource changes or "no changes"
- ✅ **terraform-apply**: Shows "Deployment Successful"
- ✅ **health-check**: Shows "Infrastructure Health Verification Complete"
- ⏸️ **cleanup**: Skipped (as expected)

### **What to Look For:**
1. **Plan Comment**: Detailed resource change summary
2. **Apply Comment**: Deployment success with infrastructure details
3. **Health Comment**: Verification that everything is working
4. **No Errors**: All jobs complete successfully

---

*This workflow provides a complete GitOps experience with safety, visibility, and compliance built-in!*
