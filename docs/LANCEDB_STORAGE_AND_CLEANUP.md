# LanceDB Storage and Cleanup Guide

## 📍 Storage Location

LanceDB data is stored **locally on disk** (not in memory) in VS Code's global storage directory:

**Windows:**

```
C:\Users\{YourUsername}\AppData\Roaming\Code\User\globalStorage\kilocode.kilo-code\code-index\lancedb\
```

**macOS:**

```
~/Library/Application Support/Code/User/globalStorage/kilocode.kilo-code/code-index/lancedb/
```

**Linux:**

```
~/.config/Code/User/globalStorage/kilocode.kilo-code/code-index/lancedb/
```

### Storage Structure

Each project/branch combination gets its own directory:

```
code-index/lancedb/
├── {ProjectName}-{BranchName}-{hash}/
│   └── *.lance files (vector data)
└── {ProjectName}-{hash}/ (for non-git projects)
```

## 🔒 Git Status

✅ **LanceDB data is already ignored by git** - it's in `.gitignore`:

- `*.lance`
- `*.lancedb`
- `.lancedb/`
- `lancedb-data/`
- `code-index/`

**It will NEVER be pushed to git** - it's purely local storage.

## 💾 Memory vs Disk

- **Disk Storage**: LanceDB stores data on disk (not in RAM)
- **Memory Impact**: Minimal - only active indexes are loaded into memory
- **Disk Impact**: Can grow over time as you index more files/branches

### Typical Sizes:

- Small project (100 files): ~5-10 MB
- Medium project (1000 files): ~50-100 MB
- Large project (10000 files): ~500 MB - 1 GB

## 🧹 Cleanup Options

### Option 1: Manual Cleanup (Current)

You can manually delete old indexes:

1. **Via File Explorer**: Navigate to the storage path above and delete old project/branch folders
2. **Via VS Code**: Close workspace → Delete the folder for that project

### Option 2: Automatic Cleanup (Recommended)

We should add automatic cleanup for:

- **Old unused indexes** (not accessed in X days)
- **Deleted branches** (git branches that no longer exist)
- **Orphaned indexes** (projects that no longer exist)

## 🚀 Proposed Auto-Cleanup Implementation

### Cleanup Strategy

1. **On Extension Startup**: Check for indexes older than 30 days
2. **On Branch Switch**: Clean up indexes for branches that no longer exist
3. **On Workspace Close**: Optionally clean up indexes for closed workspaces
4. **Configurable**: Allow users to set cleanup interval (default: 30 days)

### Cleanup Rules

- ✅ Keep indexes for current branch
- ✅ Keep indexes for branches that exist in git
- ❌ Delete indexes older than 30 days (configurable)
- ❌ Delete indexes for branches that no longer exist
- ❌ Delete indexes for projects that no longer exist

## 📊 Impact Analysis

### Current Behavior:

- ✅ No git impact (already ignored)
- ✅ No memory impact (disk storage)
- ⚠️ Disk space can grow over time
- ⚠️ No automatic cleanup

### With Auto-Cleanup:

- ✅ No git impact (still ignored)
- ✅ No memory impact (still disk storage)
- ✅ Disk space managed automatically
- ✅ Old/unused indexes removed automatically

## 🛠️ Implementation Plan

1. Add cleanup service to `CodeIndexManager`
2. Run cleanup on extension startup
3. Run cleanup when switching branches
4. Add configuration option for cleanup interval
5. Log cleanup actions for transparency

## ✅ Summary

- **Git**: ✅ Already ignored, won't be pushed
- **Memory**: ✅ Stored on disk, minimal RAM usage
- **Disk**: ⚠️ Can grow, but manageable
- **Cleanup**: ⚠️ Currently manual, should be automatic
- **Safety**: ✅ Safe to delete manually, will be recreated if needed
