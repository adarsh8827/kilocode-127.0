# Extension Build Instructions

## Build Options

### Option 1: Single Platform Build (Default - Smaller Size ~72 MB)

Builds only for the current platform (Windows x64 if building on Windows).

```bash
cd src
pnpm bundle --production
pnpm vsix
```

**Result:** VSIX works only on the platform you built it on.

---

### Option 2: Cross-Platform Build (Larger Size ~336 MB)

Builds for all platforms (Windows, macOS, Linux).

**On Windows (PowerShell) - Recommended:**
```powershell
cd src
$env:CROSS_PLATFORM_BUILD="true"
pnpm bundle --production
$env:CROSS_PLATFORM_BUILD="true"
pnpm vsix
```

**Note:** You need to set the environment variable twice because `pnpm vsix` runs `vscode:prepublish` which rebuilds.

**Alternative - Manual method:**

**On Windows (PowerShell):**
```powershell
cd src
$env:CROSS_PLATFORM_BUILD="true"
pnpm bundle --production
# Note: Must set env var again before vsix
$env:CROSS_PLATFORM_BUILD="true"
pnpm vsix
```

**On Windows (Command Prompt):**
```cmd
cd src
set CROSS_PLATFORM_BUILD=true
pnpm bundle --production
set CROSS_PLATFORM_BUILD=true
pnpm vsix
```

**On Linux/macOS:**
```bash
cd src
export CROSS_PLATFORM_BUILD=true
pnpm bundle --production
export CROSS_PLATFORM_BUILD=true
pnpm vsix
```

**Result:** VSIX works on all platforms (Windows, macOS, Linux).

---

## Getting Linux and macOS Binaries

### Method 1: Build Cross-Platform (Recommended)

Build on Windows with cross-platform flag to include all binaries:

```powershell
cd src
$env:CROSS_PLATFORM_BUILD="true"
pnpm bundle --production
pnpm vsix
```

This creates a VSIX (~336 MB) that works on:
- ✅ Windows (x64, ARM64)
- ✅ macOS (x64, ARM64)
- ✅ Linux (x64 GNU, ARM64 GNU, x64 musl, ARM64 musl)

---

### Method 2: Build on Each Platform

Build separately on each platform to get platform-specific VSIX files:

**On Linux:**
```bash
cd src
pnpm bundle --production
pnpm vsix
# Creates VSIX with Linux binaries only (~72 MB)
```

**On macOS:**
```bash
cd src
pnpm bundle --production
pnpm vsix
# Creates VSIX with macOS binaries only (~72 MB)
```

**On Windows:**
```bash
cd src
pnpm bundle --production
pnpm vsix
# Creates VSIX with Windows binaries only (~72 MB)
```

---

### Method 3: Manual Binary Installation (Advanced)

If you need to add binaries after building:

1. Install the platform-specific LanceDB packages:
   ```bash
   # On Linux
   pnpm add @lancedb/lancedb-linux-x64-gnu --save-optional
   
   # On macOS
   pnpm add @lancedb/lancedb-darwin-arm64 --save-optional
   ```

2. Copy the binaries to `dist/node_modules/@lancedb/`

3. Rebuild the VSIX

---

## Recommended Approach

**For distribution to all platforms:**
- Use **Method 1** (Cross-Platform Build)
- One VSIX file works everywhere
- Size: ~336 MB (acceptable for cross-platform support)

**For platform-specific distribution:**
- Use **Method 2** (Build on Each Platform)
- Smaller VSIX files (~72 MB each)
- Requires building on each platform

---

## Quick Reference

| Build Type | Command | Size | Platforms |
|------------|---------|------|-----------|
| Single Platform | `pnpm bundle --production` | ~72 MB | Current platform only |
| Cross-Platform | `CROSS_PLATFORM_BUILD=true pnpm bundle --production` | ~336 MB | All platforms |

---

## Notes

- The cross-platform build includes all 8 platform binaries:
  - `lancedb-win32-x64-msvc` (~120 MB)
  - `lancedb-win32-arm64-msvc` (~100 MB)
  - `lancedb-darwin-x64` (~91 MB)
  - `lancedb-darwin-arm64` (~80 MB)
  - `lancedb-linux-x64-gnu` (~111 MB)
  - `lancedb-linux-arm64-gnu` (~101 MB)
  - `lancedb-linux-x64-musl` (~111 MB)
  - `lancedb-linux-arm64-musl` (~101 MB)

- Total: ~816 MB of binaries, but optimized copying reduces unnecessary files
