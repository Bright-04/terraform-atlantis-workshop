# PowerShell Compatibility Guide

## 🎯 Overview

This document outlines all the PowerShell compatibility improvements made to the Terraform Atlantis Workshop documentation. The workshop now includes PowerShell-compatible commands for Windows users alongside the traditional bash commands.

## 🔧 Key Improvements Made

### **1. Command Compatibility**

#### **File Operations**

| **Linux/macOS (bash)** | **Windows (PowerShell)**                                   |
| ---------------------- | ---------------------------------------------------------- |
| `mkdir -p dir1 dir2`   | `New-Item -ItemType Directory -Path "dir1", "dir2" -Force` |
| `touch file.txt`       | `New-Item -ItemType File -Path "file.txt" -Force`          |
| `cp file1 file2`       | `Copy-Item "file1" "file2"`                                |
| `rm file.txt`          | `Remove-Item "file.txt" -Force`                            |
| `rm -rf directory`     | `Remove-Item "directory" -Recurse -Force`                  |

#### **Text Processing**

| **Linux/macOS (bash)**   | **Windows (PowerShell)**         |
| ------------------------ | -------------------------------- | ------------------------------ |
| `grep "pattern" file`    | `Select-String "pattern" file`   |
| `grep -q "pattern"`      | `Select-String "pattern" -Quiet` |
| `cat file.txt`           | `Get-Content file.txt`           |
| `echo "text" > file.txt` | `"text"                          | Out-File -FilePath "file.txt"` |

#### **Date and Time**

| **Linux/macOS (bash)**                       | **Windows (PowerShell)**                                  |
| -------------------------------------------- | --------------------------------------------------------- |
| `date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S` | `(Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ss")` |
| `date -u +%Y-%m-%dT%H:%M:%S`                 | `(Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")`              |
| `date +%Y%m%d-%H%M%S`                        | `Get-Date -Format "yyyyMMdd-HHmmss"`                      |

#### **Web Requests**

| **Linux/macOS (bash)**         | **Windows (PowerShell)**                                                                                               |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `curl -s URL`                  | `Invoke-WebRequest -Uri URL -UseBasicParsing`                                                                          |
| `curl -I URL`                  | `try { $response = Invoke-WebRequest -Uri URL -UseBasicParsing; $response.StatusCode } catch { $_.Exception.Message }` |
| `time curl -s URL > /dev/null` | `$stopwatch = [System.Diagnostics.Stopwatch]::StartNew(); Invoke-WebRequest -Uri URL -UseBasicParsing                  | Out-Null; $stopwatch.Stop(); $stopwatch.ElapsedMilliseconds` |

### **2. Script Improvements**

#### **Automated Cleanup Script**

**Before (bash only):**

```bash
#!/bin/bash
echo "🚀 Starting infrastructure cleanup..."
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d-%H%M%S)
aws sts get-caller-identity
terraform plan -destroy -out=destroy-plan.tfplan
read -p "Do you want to proceed with destruction? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    terraform apply destroy-plan.tfplan
    echo "✅ Cleanup completed successfully!"
else
    echo "❌ Cleanup cancelled by user"
    exit 1
fi
rm -f destroy-plan.tfplan
```

**After (PowerShell + bash):**

```powershell
# PowerShell version
Write-Host "🚀 Starting infrastructure cleanup..."
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item "terraform.tfstate" "terraform.tfstate.backup.$timestamp"
aws sts get-caller-identity
terraform plan -destroy -out=destroy-plan.tfplan
$confirm = Read-Host "Do you want to proceed with destruction? (yes/no)"
if ($confirm -eq "yes") {
    terraform apply destroy-plan.tfplan
    Write-Host "✅ Cleanup completed successfully!"
} else {
    Write-Host "❌ Cleanup cancelled by user"
    exit 1
}
Remove-Item "destroy-plan.tfplan" -ErrorAction SilentlyContinue
```

#### **Policy Testing Script**

**Before (bash only):**

```bash
#!/bin/bash
echo "Testing compliance policies..."
terraform plan -var="instance_type=t3.micro" | grep -q "VIOLATION" && echo "❌ Instance type violation found" || echo "✅ Instance type policy passed"
terraform plan | grep -q "missing required tags" && echo "❌ Tag violation found" || echo "✅ Tag policy passed"
terraform plan | grep -q "naming convention" && echo "❌ Naming violation found" || echo "✅ Naming policy passed"
echo "Policy testing completed!"
```

**After (PowerShell + bash):**

```powershell
# PowerShell version
Write-Host "Testing compliance policies..."
$planOutput = terraform plan -var="instance_type=t3.micro" 2>&1
if ($planOutput -match "VIOLATION") {
    Write-Host "❌ Instance type violation found"
} else {
    Write-Host "✅ Instance type policy passed"
}
$planOutput = terraform plan 2>&1
if ($planOutput -match "missing required tags") {
    Write-Host "❌ Tag violation found"
} else {
    Write-Host "✅ Tag policy passed"
}
if ($planOutput -match "naming convention") {
    Write-Host "❌ Naming violation found"
} else {
    Write-Host "✅ Naming policy passed"
}
Write-Host "Policy testing completed!"
```

### **3. Documentation Structure Improvements**

#### **Dual Command Examples**

All command examples now include both PowerShell and bash versions:

````markdown
#### **Windows (PowerShell)**

```powershell
# PowerShell commands here
```
````

#### **Linux/macOS**

```bash
# bash commands here
```

````

#### **PowerShell-Specific Sections**

Added dedicated PowerShell sections for:
- Environment setup
- File operations
- Testing procedures
- Cleanup processes
- Monitoring commands

### **4. Removed Misleading Information**

#### **LocalStack References**
- Removed LocalStack installation instructions
- Updated 03-LOCALSTACK.md to focus on general local development
- Removed LocalStack from prerequisites checklist

#### **Non-Working Commands**
- Removed `-verbose` flags that don't work in PowerShell
- Replaced `grep` commands with `Select-String`
- Fixed date/time commands for PowerShell compatibility
- Updated web request commands for PowerShell

## 📋 Files Updated

### **Core Documentation**
- ✅ **01-SETUP.md** - Added PowerShell installation and setup commands
- ✅ **04-AWS-DEPLOYMENT.md** - Added PowerShell testing and monitoring commands
- ✅ **07-TESTING.md** - Added PowerShell testing scripts and commands
- ✅ **11-CLEANUP.md** - Added PowerShell cleanup scripts
- ✅ **README.md** - Updated with PowerShell compatibility notes

### **Infrastructure Files**
- ✅ **03-LOCALSTACK.md** - Removed LocalStack focus, added general local development
- ✅ **WORKSHOP_OUTLINE.md** - Updated to reflect PowerShell compatibility

## 🎯 PowerShell Best Practices Implemented

### **1. Error Handling**
```powershell
try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    Write-Host "Success: $($response.StatusCode)"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
````

### **2. Variable Usage**

```powershell
$websiteUrl = terraform output -raw website_url
$instanceId = terraform output -raw instance_id
```

### **3. Pipeline Operations**

```powershell
# Instead of grep
aws s3 ls | Select-String "pattern"

# Instead of time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
# ... operation ...
$stopwatch.Stop()
Write-Host "Time: $($stopwatch.ElapsedMilliseconds)ms"
```

### **4. File Operations**

```powershell
# Safe file operations
Remove-Item "file.txt" -ErrorAction SilentlyContinue
Copy-Item "source" "destination" -Force
```

## 🚨 Common PowerShell Issues Addressed

### **1. Command Not Found**

-   **Issue**: `grep`, `curl`, `date` commands not available
-   **Solution**: Provided PowerShell equivalents (`Select-String`, `Invoke-WebRequest`, `Get-Date`)

### **2. Parameter Differences**

-   **Issue**: `-verbose` flag doesn't work for external commands
-   **Solution**: Removed or replaced with PowerShell-compatible alternatives

### **3. Path Separators**

-   **Issue**: Forward slashes vs backslashes
-   **Solution**: Used PowerShell path handling with `-Path` parameter

### **4. Variable Expansion**

-   **Issue**: Different variable syntax between shells
-   **Solution**: Used PowerShell variable syntax (`$variable`)

## 📊 Compatibility Matrix

| **Feature**     | **Linux/macOS** | **Windows PowerShell** | **Status**  |
| --------------- | --------------- | ---------------------- | ----------- |
| File Operations | ✅ bash         | ✅ PowerShell          | ✅ Complete |
| Web Requests    | ✅ curl         | ✅ Invoke-WebRequest   | ✅ Complete |
| Text Processing | ✅ grep         | ✅ Select-String       | ✅ Complete |
| Date/Time       | ✅ date         | ✅ Get-Date            | ✅ Complete |
| Scripts         | ✅ bash         | ✅ PowerShell          | ✅ Complete |
| Testing         | ✅ bash         | ✅ PowerShell          | ✅ Complete |
| Cleanup         | ✅ bash         | ✅ PowerShell          | ✅ Complete |

## 🎯 Benefits of PowerShell Compatibility

### **1. Windows User Experience**

-   Native PowerShell commands for Windows users
-   No need to install additional tools (like Git Bash)
-   Familiar syntax and conventions

### **2. Enterprise Compatibility**

-   Works in corporate Windows environments
-   Compatible with Windows Server
-   Supports Active Directory integration

### **3. Learning Accessibility**

-   Reduces barriers for Windows users
-   Provides clear command alternatives
-   Maintains educational value

## 📞 Support for PowerShell Users

### **Getting Help**

1. **Check this guide** for PowerShell equivalents
2. **Use PowerShell help**: `Get-Help Command-Name`
3. **Test commands** in PowerShell ISE or VS Code
4. **Check troubleshooting guide** for PowerShell-specific issues

### **Common PowerShell Commands**

```powershell
# Get help
Get-Help Invoke-WebRequest
Get-Help Select-String

# Check if command exists
Get-Command Invoke-WebRequest

# Get PowerShell version
$PSVersionTable.PSVersion
```

## 🏆 Summary

The Terraform Atlantis Workshop now provides:

-   ✅ **Complete PowerShell compatibility** for Windows users
-   ✅ **Dual command examples** (PowerShell + bash)
-   ✅ **PowerShell-specific scripts** and automation
-   ✅ **Removed misleading information** about non-working commands
-   ✅ **Updated documentation** with Windows-friendly instructions
-   ✅ **Enterprise-ready** for Windows environments

**Result**: Windows users can now complete the entire workshop using native PowerShell commands without needing to install additional tools or learn bash syntax.

---

**Ready to use PowerShell?** Start with the [Environment Setup Guide](01-SETUP.md) for Windows-specific instructions!
