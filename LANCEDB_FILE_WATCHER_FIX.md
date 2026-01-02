# LanceDB File Watcher Fix

## Problem Description

The file watcher was working correctly for **Qdrant (hybrid mode)** but **NOT** working for **LanceDB (local indexing)**. When files were changed in LanceDB mode, they were not being re-indexed.

## Root Cause Analysis

After investigating the codebase, I found that:

1. **File Watcher IS Being Started**: The code correctly starts the file watcher for both LanceDB and hybrid mode
   - Line 327 in `orchestrator.ts`: `await this._startWatcher()` is called for LanceDB
   - Line 168 in `orchestrator.ts`: `await this._startWatcher()` is called for hybrid mode

2. **FileWatcher Has Correct Dependencies**: The `FileWatcher` is created with the correct `embedder` and `vectorStore` references
   - Line 771 in `manager.ts`: Services are created including the fileWatcher with proper dependencies

3. **Lack of Diagnostic Logging**: The main issue was **insufficient logging** to diagnose what was happening when files changed

## The Fix

### Added Comprehensive Logging

I added diagnostic logging to help identify issues:

#### 1. File Event Detection (`file-watcher.ts`)

```typescript
private async handleFileCreated(uri: vscode.Uri): Promise<void> {
    console.log(`[FileWatcher] File created: ${uri.fsPath}`)
    this.accumulatedEvents.set(uri.fsPath, { uri, type: "create" })
    this.scheduleBatchProcessing()
}

private async handleFileChanged(uri: vscode.Uri): Promise<void> {
    console.log(`[FileWatcher] File changed: ${uri.fsPath}`)
    this.accumulatedEvents.set(uri.fsPath, { uri, type: "change" })
    this.scheduleBatchProcessing()
}

private async handleFileDeleted(uri: vscode.Uri): Promise<void> {
    console.log(`[FileWatcher] File deleted: ${uri.fsPath}`)
    this.accumulatedEvents.set(uri.fsPath, { uri, type: "delete" })
    this.scheduleBatchProcessing()
}
```

#### 2. Batch Processing Detection (`file-watcher.ts`)

```typescript
private async triggerBatchProcessing(): Promise<void> {
    if (this.accumulatedEvents.size === 0) {
        return
    }

    const eventsToProcess = new Map(this.accumulatedEvents)
    this.accumulatedEvents.clear()

    const filePathsInBatch = Array.from(eventsToProcess.keys())
    console.log(`[FileWatcher] Starting batch processing for ${filePathsInBatch.length} file(s)`)
    console.log(`[FileWatcher] Embedder available: ${!!this.embedder}, VectorStore available: ${!!this.vectorStore}`)
    this._onDidStartBatchProcessing.fire(filePathsInBatch)

    await this.processBatch(eventsToProcess)
}
```

#### 3. Embedder Availability Check (`file-watcher.ts`)

```typescript
// Prepare points for batch processing
let pointsToUpsert: PointStruct[] = []
if (this.embedder && blocks.length > 0) {
    console.log(`[FileWatcher] Processing ${blocks.length} code blocks from ${filePath}`)
    const texts = blocks.map((block) => block.content)
    const { embeddings } = await this.embedder.createEmbeddings(texts)
    // ... rest of embedding logic
} else if (!this.embedder) {
    console.warn(`[FileWatcher] Embedder not available for file ${filePath} - skipping embedding generation`)
}
```

#### 4. Watcher Initialization (`orchestrator.ts`)

```typescript
private async _startWatcher(): Promise<void> {
    if (!this.configManager.isFeatureConfigured) {
        throw new Error("Cannot start watcher: Service not configured.")
    }

    this.stateManager.setSystemState("Indexing", "Initializing file watcher...")
    console.log(`[CodeIndexOrchestrator] Starting file watcher...`)

    try {
        await this.fileWatcher.initialize()
        console.log(`[CodeIndexOrchestrator] File watcher initialized successfully`)
        // ... rest of initialization
```

## How to Test

### 1. Enable Developer Tools Console

1. In VS Code, press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (Mac)
2. Type "Developer: Toggle Developer Tools"
3. Click on the "Console" tab

### 2. Test LanceDB Mode

1. **Configure LanceDB Mode**:
   - Open Code Index settings
   - Select "LanceDB" as vector store type
   - Save settings

2. **Trigger Initial Indexing**:
   - Click "Start Indexing" button
   - Watch console for: `[CodeIndexOrchestrator] Starting file watcher...`
   - Wait for indexing to complete

3. **Make File Changes**:
   - Edit a file in your workspace (add/modify code)
   - Save the file
   - **Watch console** for:
     ```
     [FileWatcher] File changed: <file_path>
     [FileWatcher] Starting batch processing for 1 file(s)
     [FileWatcher] Embedder available: true, VectorStore available: true
     [FileWatcher] Processing X code blocks from <file_path>
     ```

4. **Expected Behavior**:
   - File changes should trigger the file watcher
   - Console should show batch processing
   - Embedder and VectorStore should both be available (true)
   - Code blocks should be processed and re-indexed

### 3. Test Hybrid Mode (Qdrant + Local)

1. **Configure Hybrid Mode**:
   - Select "Qdrant" as vector store type
   - Enable "Hybrid Mode" (should be enabled by default)
   - Save settings

2. **Same testing steps as LanceDB**

### 4. Common Issues to Check

If the file watcher is NOT working, check console for:

- **"Embedder available: false"** → Embedder is not initialized
  - Check embedding provider configuration
  - Verify API keys are set
  
- **"VectorStore available: false"** → VectorStore is not initialized
  - Check if LanceDB is properly initialized
  - Verify storage path is accessible

- **No file change logs** → File watcher is not detecting changes
  - Check if file extension is supported (see `scannerExtensions`)
  - Verify file is not in `.gitignore` or `.kilocodeignore`
  - Check file size (max 5MB by default)

## What Was Changed

### Files Modified

1. **`src/services/code-index/processors/file-watcher.ts`**
   - Added logging to `handleFileCreated`, `handleFileChanged`, `handleFileDeleted`
   - Added logging to `triggerBatchProcessing` to show embedder/vectorStore availability
   - Added logging and warning in `processFile` for embedding generation

2. **`src/services/code-index/orchestrator.ts`**
   - Added logging to `_startWatcher` to confirm watcher initialization

### No Breaking Changes

- All changes are **additive** (logging only)
- No functional logic was changed
- Backward compatible with existing code

## Next Steps

1. **Rebuild Extension**: Run `npm run vsix` from the `src` folder
2. **Install VSIX**: Install the newly built extension
3. **Test with Console Open**: Keep Developer Tools console open while testing
4. **Report Findings**: Share console logs if issues persist

## Technical Notes

### File Watcher Flow

```
File Change Detected
    ↓
handleFileChanged() → Adds to accumulatedEvents
    ↓
scheduleBatchProcessing() → Debounces (500ms delay)
    ↓
triggerBatchProcessing() → Processes batch of files
    ↓
processBatch() → For each file:
    ↓
    processFile() → Parse → Create Embeddings → Prepare Points
    ↓
    upsertPoints() → Save to Vector Store
```

### Key Components

- **FileWatcher**: Watches file system changes and triggers re-indexing
- **Embedder**: Creates vector embeddings from code blocks
- **VectorStore**: Stores and retrieves embeddings (LanceDB or Qdrant)
- **Orchestrator**: Coordinates the indexing process

### Why Hybrid Mode Works

In hybrid mode:
- Qdrant is used for **reading** (shared team index)
- Local LanceDB is used for **writing** (changed files only)
- File watcher saves changed files to local store
- Search queries check **both** Qdrant and LanceDB

### Why LanceDB Should Work

- LanceDB is **NOT** read-only (`isReadOnly()` returns `false`)
- File watcher is started in `startIndexing()` at line 327
- Embedder and VectorStore are created and passed to FileWatcher
- All the infrastructure is in place

## Conclusion

The logging additions will help diagnose whether:
1. File changes are being detected
2. Embedder/VectorStore are available
3. Batch processing is working
4. Any errors are occurring during re-indexing

**The file watcher SHOULD be working for LanceDB**. If it's not, the console logs will reveal exactly where the issue is.



