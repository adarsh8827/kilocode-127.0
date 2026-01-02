# LanceDB Testing Guide

## Overview

This guide provides comprehensive test cases for verifying LanceDB initialization, indexing, search functionality, file watcher integration, and configuration switching.

## Prerequisites

1. **Build and Install Extension**
   ```bash
   cd src
   pnpm bundle
   cd ..
   pnpm vsix
   # Install the VSIX file in VS Code
   ```

2. **Open Developer Tools**
   - Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (Mac)
   - Type "Developer: Toggle Developer Tools"
   - Click on the "Console" tab

3. **Create Test Workspace**
   ```
   test-workspace/
   ├── src/
   │   ├── auth/
   │   │   └── userAuth.ts
   │   ├── utils/
   │   │   └── helpers.ts
   │   └── main.ts
   └── README.md
   ```

## Test 1: LanceDB Initialization

### Test 1.1: Fresh Initialization

**Steps:**
1. Open VS Code settings
2. Search for "code index"
3. Set "Vector Store Provider" to "LanceDB"
4. Configure embedding provider (e.g., OpenAI with API key)
5. Click "Start Indexing"
6. Watch console logs

**Expected Console Output:**
```
[LanceDBVectorStore] Initializing LanceDB...
[LanceDBManager] Ensuring directory exists: {path}
[LanceDBVectorStore] Connecting to database...
[LanceDBVectorStore] Creating new table: vectors_{hash}
[LanceDBVectorStore] Initialization successful
```

**Verification:**
- ✅ No errors in console
- ✅ Database directory created at: `{globalStorage}/code-index/lancedb/{workspaceHash}/`
- ✅ Table file exists (`.lance` file)
- ✅ Indexing status shows "Indexed" or "Indexing"

### Test 1.2: Re-initialization (Existing Table)

**Steps:**
1. After Test 1.1 completes
2. Restart VS Code or click "Start Indexing" again
3. Check console logs

**Expected Console Output:**
```
[LanceDBVectorStore] Initializing LanceDB...
[LanceDBVectorStore] Opening existing table: vectors_{hash}
[LanceDBVectorStore] Initialization successful (existing table)
```

**Verification:**
- ✅ Table opened (not recreated)
- ✅ No data loss
- ✅ `initialize()` returns `false` (existing table)

### Test 1.3: Dimension Mismatch Handling

**Steps:**
1. Index with 512-dim embedding model
2. Change to 768-dim embedding model
3. Re-initialize
4. Check console logs

**Expected Console Output:**
```
[LanceDBVectorStore] Dimension mismatch detected: 512 != 768
[LanceDBVectorStore] Deleting old table...
[LanceDBVectorStore] Creating new table with dimensions: 768
[LanceDBVectorStore] Initialization successful
```

**Verification:**
- ✅ Old table deleted
- ✅ New table created with correct dimensions
- ✅ No errors during transition

## Test 2: Indexing Functionality

### Test 2.1: Basic File Indexing

**Steps:**
1. Create test file: `src/test.ts`
   ```typescript
   export function authenticateUser(username: string, password: string): boolean {
     // Authentication logic
     return true;
   }
   ```
2. Start indexing
3. Monitor console logs

**Expected Console Output:**
```
[DirectoryScanner] Processing file: src/test.ts
[DirectoryScanner] Parsed 1 code block
[DirectoryScanner] Generating embeddings...
[LanceDBVectorStore] Upserting 1 points...
[LanceDBVectorStore] Upserted 1 points successfully
```

**Verification:**
- ✅ File processed
- ✅ Code blocks parsed
- ✅ Embeddings generated
- ✅ Points stored in LanceDB
- ✅ Progress updates visible

### Test 2.2: Multiple Files Indexing

**Steps:**
1. Create multiple test files (5-10 files)
2. Start indexing
3. Monitor progress

**Expected Results:**
- ✅ All files processed
- ✅ Progress shows: "Processing file X of Y"
- ✅ All points stored
- ✅ No errors during batch processing

### Test 2.3: Large File Handling

**Steps:**
1. Create file with 500+ lines
2. Start indexing
3. Check behavior

**Expected Results:**
- ✅ File processed (may be truncated per config)
- ✅ Embeddings generated for available chunks
- ✅ Points stored successfully
- ✅ No timeouts or errors

## Test 3: Search Functionality

### Test 3.1: Basic Semantic Search

**Steps:**
1. After indexing completes
2. In chat, ask: "Find user authentication code"
3. AI should use `codebase_search` tool
4. Check results

**Expected Results:**
- ✅ Results returned
- ✅ Results include:
  - File paths
  - Line numbers
  - Code snippets
  - Similarity scores
- ✅ Results sorted by relevance (highest score first)
- ✅ Console shows: `[LanceDBVectorStore] Searching table...`

**Console Output:**
```
[LanceDBVectorStore] Searching table: vectors_{hash}
[LanceDBVectorStore] Query vector: [0.123, -0.456, ...]
[LanceDBVectorStore] Found 5 results
[LanceDBVectorStore] Filtered to 3 results (score >= 0.4)
```

### Test 3.2: Directory Prefix Filtering

**Steps:**
1. Index files in multiple directories
2. In chat, ask: "Find authentication code in src/auth directory"
3. Check results

**Expected Results:**
- ✅ Only results from `src/auth/` directory
- ✅ Filter applied: `filePath LIKE 'src/auth/%'`
- ✅ Results still sorted by score

**Verification:**
- All result file paths start with `src/auth/`
- No results from other directories

### Test 3.3: Score Threshold

**Steps:**
1. Search with query that should return mixed relevance
2. Check results

**Expected Results:**
- ✅ Only results with score >= 0.4 (default threshold)
- ✅ Lower relevance results filtered out
- ✅ Results sorted by score

### Test 3.4: Max Results Limit

**Steps:**
1. Search with query that should return many results
2. Check result count

**Expected Results:**
- ✅ Maximum 50 results (default limit)
- ✅ Top 50 most relevant results
- ✅ Sorted by score

## Test 4: File Watcher Integration

### Test 4.1: File Change Detection

**Steps:**
1. After initial indexing
2. Open an indexed file: `src/test.ts`
3. Modify the code
4. Save the file (Ctrl+S)
5. Watch console logs

**Expected Console Output:**
```
[FileWatcher] File changed: src/test.ts
[FileWatcher] Starting batch processing for 1 file(s)
[FileWatcher] Embedder available: true, VectorStore available: true
[FileWatcher] Processing 1 code blocks from src/test.ts
[LanceDBVectorStore] Upserting 1 points...
[LanceDBVectorStore] Upserted 1 points successfully
[FileWatcher] Batch processing completed
```

**Verification:**
- ✅ Change detected within 500ms
- ✅ File re-indexed
- ✅ New embeddings stored
- ✅ Old embeddings replaced (upsert)

### Test 4.2: New File Creation

**Steps:**
1. Create new file: `src/newFile.ts`
2. Add some code
3. Save file
4. Check console logs

**Expected Console Output:**
```
[FileWatcher] File created: src/newFile.ts
[FileWatcher] Starting batch processing for 1 file(s)
[FileWatcher] Processing X code blocks from src/newFile.ts
[LanceDBVectorStore] Upserting X points...
```

**Verification:**
- ✅ File automatically indexed
- ✅ Points stored in LanceDB
- ✅ Searchable immediately after indexing

### Test 4.3: File Deletion

**Steps:**
1. Delete an indexed file: `src/test.ts`
2. Check console logs

**Expected Console Output:**
```
[FileWatcher] File deleted: src/test.ts
[FileWatcher] Starting batch processing for 1 file(s)
[LanceDBVectorStore] Deleting points for file: src/test.ts
[LanceDBVectorStore] Deleted points successfully
```

**Verification:**
- ✅ Deletion detected
- ✅ Points removed from LanceDB
- ✅ Search for deleted file returns no results

### Test 4.4: Batch File Changes

**Steps:**
1. Quickly modify 3-5 files
2. Save all files
3. Check console logs

**Expected Console Output:**
```
[FileWatcher] File changed: src/file1.ts
[FileWatcher] File changed: src/file2.ts
[FileWatcher] File changed: src/file3.ts
[FileWatcher] Starting batch processing for 3 file(s)
[FileWatcher] Processing batch...
```

**Verification:**
- ✅ Changes batched (500ms debounce)
- ✅ All files processed in single batch
- ✅ Progress updates show batch size

### Test 4.5: File Watcher Initialization

**Steps:**
1. Check console on extension startup
2. Verify watcher started

**Expected Console Output:**
```
[CodeIndexOrchestrator] Starting file watcher...
[CodeIndexOrchestrator] File watcher initialized successfully
```

**Verification:**
- ✅ Watcher started automatically
- ✅ No errors during initialization

## Test 5: Configuration Switching

### Test 5.1: Switch from Qdrant to LanceDB

**Steps:**
1. Start with Qdrant configured and indexed
2. Open settings
3. Change "Vector Store Provider" to "LanceDB"
4. Restart indexing
5. Check console logs

**Expected Results:**
- ✅ Configuration updated
- ✅ LanceDB initialized
- ✅ New indexing uses LanceDB
- ✅ Old Qdrant index preserved
- ✅ Search uses LanceDB

**Verification:**
- Settings show LanceDB as provider
- Console shows LanceDB initialization
- Search results come from LanceDB

### Test 5.2: Switch from LanceDB to Qdrant

**Steps:**
1. Start with LanceDB configured and indexed
2. Open settings
3. Change "Vector Store Provider" to "Qdrant"
4. Configure Qdrant URL and API key
5. Restart indexing
6. Check console logs

**Expected Results:**
- ✅ Configuration updated
- ✅ Qdrant connection established
- ✅ New indexing uses Qdrant
- ✅ Old LanceDB index preserved
- ✅ Search uses Qdrant

**Verification:**
- Settings show Qdrant as provider
- Console shows Qdrant connection
- Search results come from Qdrant

### Test 5.3: Configuration Persistence

**Steps:**
1. Set vector store to LanceDB
2. Restart VS Code
3. Check configuration

**Expected Results:**
- ✅ Configuration persists
- ✅ LanceDB still selected
- ✅ No need to reconfigure

## Test 6: Error Handling

### Test 6.1: Invalid Embedding Provider

**Steps:**
1. Configure LanceDB with invalid/missing API key
2. Try to start indexing

**Expected Results:**
- ✅ Error message displayed
- ✅ Indexing fails gracefully
- ✅ No crashes
- ✅ Error logged to console

### Test 6.2: Database Path Issues

**Steps:**
1. Set invalid database path (if configurable)
2. Try to initialize

**Expected Results:**
- ✅ Error caught and logged
- ✅ Fallback to default path or clear error message
- ✅ No crashes

## Test 7: Performance

### Test 7.1: Indexing Speed

**Steps:**
1. Create 100 test files
2. Start indexing
3. Time the process

**Expected Results:**
- ✅ Reasonable indexing speed (< 1s per file average)
- ✅ Progress updates visible
- ✅ No significant slowdowns

### Test 7.2: Search Speed

**Steps:**
1. After indexing 1000+ files
2. Perform multiple searches
3. Time search queries

**Expected Results:**
- ✅ Search completes in < 300ms
- ✅ Results returned quickly
- ✅ No timeouts

## Success Criteria

All tests pass when:
- ✅ LanceDB initializes without errors
- ✅ Files index successfully
- ✅ Search returns relevant results
- ✅ File watcher updates index on changes
- ✅ Configuration switching works
- ✅ No crashes or memory leaks
- ✅ Performance is acceptable
- ✅ Error handling is graceful

## Troubleshooting

### Issue: LanceDB not initializing
- Check console for errors
- Verify `@lancedb/lancedb` package is installed
- Check database path permissions
- Verify embedding provider is configured

### Issue: File watcher not working
- Check console for initialization logs
- Verify file watcher started: `[CodeIndexOrchestrator] File watcher initialized`
- Check file is not in `.kilocodeignore` or `.gitignore`
- Verify file extension is supported

### Issue: Search returns no results
- Verify indexing completed
- Check search query is relevant
- Lower score threshold if needed
- Verify embeddings were generated

### Issue: Configuration not persisting
- Check VS Code settings storage
- Verify global state is saved
- Check for settings sync conflicts

## Next Steps

After manual testing, consider creating automated tests:
1. Unit tests for `LanceDBVectorStore`
2. Unit tests for `LanceDBManager`
3. Integration tests for file watcher
4. End-to-end tests for full workflow
