# 🧹 Complete Manual Clean Install Guide

## You're seeing the OLD error because VS Code is caching the old extension!

Follow these steps **EXACTLY** to do a complete clean install:

---

## ✅ **Step-by-Step Manual Process**

### **1. Close ALL VS Code Windows**

```powershell
# In PowerShell (Run as Administrator)
Get-Process code | Stop-Process -Force
```

**Verify:** No VS Code windows should be open!

---

### **2. Uninstall Old Extension**

```powershell
code --uninstall-extension kilocode.kilo-code
```

---

### **3. Clear ALL Extension Caches**

```powershell
# Remove installed extension files
Remove-Item -Recurse -Force "$env:USERPROFILE\.vscode\extensions\kilocode.kilo-code-*" -ErrorAction SilentlyContinue

# Remove obsolete marker
Remove-Item -Recurse -Force "$env:USERPROFILE\.vscode\extensions\.obsolete" -ErrorAction SilentlyContinue

# Clear VS Code cache
Remove-Item -Recurse -Force "$env:APPDATA\Code\Cache\*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:APPDATA\Code\CachedData\*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:APPDATA\Code\CachedExtensions\*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:APPDATA\Code\CachedExtensionVSIXs\*" -ErrorAction SilentlyContinue
```

---

### **4. Verify VSIX Contains LanceDB**

```powershell
# Extract VSIX to temp location
$vsixPath = "C:\KiloNe\kilocode-4.116.1\bin\kilo-code-4.116.1.vsix"
$tempPath = "$env:TEMP\kilocode-verify"

Remove-Item -Recurse -Force $tempPath -ErrorAction SilentlyContinue
Expand-Archive -Path $vsixPath -DestinationPath $tempPath

# Check if LanceDB exists
dir "$tempPath\extension\dist\node_modules\@lancedb\lancedb"
```

**Expected Output:**
```
Directory: ...\extension\dist\node_modules\@lancedb\lancedb

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        11/12/2025   ...                    dist
d-----        11/12/2025   ...                    native
-a----        ...                          ...    package.json
```

**Check for .node files:**
```powershell
dir "$tempPath\extension\dist\node_modules\@lancedb\lancedb\*.node" -Recurse
```

**Expected:** You should see files like:
- `lancedb.win32-x64-msvc.node`
- `lancedb.darwin-arm64.node`
- `lancedb.darwin-x64.node`
- `lancedb.linux-x64-gnu.node`

**Clean up:**
```powershell
Remove-Item -Recurse -Force $tempPath
```

---

### **5. Install New VSIX**

```powershell
code --install-extension "C:\KiloNe\kilocode-4.116.1\bin\kilo-code-4.116.1.vsix" --force
```

**Wait for:** "Extension 'kilocode.kilo-code' was successfully installed."

---

### **6. Verify Installation**

```powershell
code --list-extensions | Select-String "kilocode"
```

**Expected:** `kilocode.kilo-code`

---

### **7. Start Fresh VS Code with Developer Console**

```powershell
# Start VS Code fresh
code
```

**IMMEDIATELY after VS Code opens:**
1. Press `Ctrl+Shift+I` (Developer Tools)
2. Go to **Console** tab
3. **Keep it open!**

---

### **8. Open Your Workspace**

```powershell
# In a new terminal
code "C:\Users\ASUS\Downloads\express-hello-world"
```

---

### **9. Configure LanceDB**

1. Click **Kilocode** icon in sidebar
2. Click **Codebase Indexing** (gear icon)
3. Configure:
   - **Vector Store Type:** `LanceDB (Local Indexing)`
   - **Embedder:** `Ollama`
   - **Base URL:** `http://127.0.0.1:11434` ⚠️ **No /api/embeddings!**
   - **Model:** `nomic-embed-text`
4. Click **Save Settings**

---

### **10. Check Console Output**

**✅ SUCCESS - You should see:**
```
[LanceDB] ✅ Successfully loaded LanceDB module
[CodeIndexOrchestrator] Starting indexing...
```

**❌ FAILURE - If you see:**
```
[LanceDB] ❌ Failed to load LanceDB module
[LanceDB] Error details: ...
[LanceDB] Current __dirname: ...
[LanceDB] Platform: win32 x64
```

**Copy and share ALL lines starting with `[LanceDB]`!**

---

## 🤔 **Still Not Working?**

### **Check 1: Verify Extension Path**

```powershell
dir "$env:USERPROFILE\.vscode\extensions\kilocode.kilo-code-*\dist\node_modules\@lancedb\lancedb"
```

**This directory MUST exist!** If not, the VSIX wasn't packaged correctly.

### **Check 2: Verify Extension Version**

In VS Code:
1. Open Extensions panel
2. Find "Kilocode"
3. Check version: Should be **4.116.1**

### **Check 3: Check for Multiple Versions**

```powershell
dir "$env:USERPROFILE\.vscode\extensions\kilocode.kilo-code-*"
```

**You should only see ONE directory!** If multiple, remove all and reinstall.

---

## 🚀 **Alternative: Use Automated Script**

Run the PowerShell script I created:

```powershell
# Run as Administrator
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\CLEAN_INSTALL.ps1
```

This script does everything automatically!

---

## 📋 **What to Share If Still Failing**

1. **Console output** - All lines starting with `[LanceDB]`
2. **Extension directory check:**
   ```powershell
   dir "$env:USERPROFILE\.vscode\extensions\kilocode.kilo-code-*"
   ```
3. **LanceDB check in installed extension:**
   ```powershell
   dir "$env:USERPROFILE\.vscode\extensions\kilocode.kilo-code-*\dist\node_modules\@lancedb"
   ```
4. **Platform info:**
   ```powershell
   [Environment]::OSVersion
   [Environment]::Is64BitOperatingSystem
   ```

---

## 🎯 **Expected File Structure After Install**

```
%USERPROFILE%\.vscode\extensions\
└── kilocode.kilo-code-4.116.1\
    ├── dist\
    │   ├── extension.js
    │   └── node_modules\          ← THIS MUST EXIST!
    │       └── @lancedb\
    │           └── lancedb\
    │               ├── dist\
    │               │   └── index.js
    │               └── *.node files (native modules)
    ├── package.json
    └── ...
```

If `dist/node_modules` doesn't exist, the VSIX is corrupted!

---

**Follow these steps carefully and share the console output!** 🔍

