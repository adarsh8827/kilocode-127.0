# LanceDB Vector Store: Complete Flow Explanation

## Overview
This document explains how the LanceDB vector store works from storing embeddings to retrieving them, step by step.

---

## 📦 **PHASE 1: INITIALIZATION**

### Step 1.1: Create Vector Store Instance
```typescript
// Location: service-factory.ts
const vectorStore = new LanceDBVectorStore(
    workspacePath,      // e.g., "C:\Users\...\Book-My-Show"
    vectorSize,         // e.g., 768 (from embedding model)
    globalStoragePath,  // VS Code global storage path
    dbPath              // Optional custom path
)
```

**What happens:**
- Generates a unique table name: `vectors_<workspaceHash>`
- Creates database path: `{globalStoragePath}/code-index/lancedb/{workspaceHash}/`
- Stores vector size (e.g., 768 dimensions)

### Step 1.2: Initialize Database
```typescript
await vectorStore.initialize()
```

**What happens:**
1. **Loads LanceDB module** from `dist/node_modules/@lancedb/lancedb`
2. **Creates database directory** if it doesn't exist
3. **Connects to LanceDB**: `await lancedb.connect(dbPath)`
4. **Checks if table exists**:
   - **If NEW table**: Creates table with schema:
     ```typescript
     {
       id: string,
       vector: Float32Array[768],  // Fixed-size array
       filePath: string,
       codeChunk: string,
       startLine: number,
       endLine: number
     }
     ```
   - **If EXISTING table**: 
     - Opens existing table
     - **Checks dimension mismatch** (e.g., table has 512 but need 768)
     - **Auto-recreates table** if dimensions don't match
5. **Returns**: `true` if new table created, `false` if existing

---

## 💾 **PHASE 2: STORING EMBEDDINGS**

### Step 2.1: Code Parsing
```typescript
// Location: scanner.ts or file-watcher.ts
const blocks = await codeParser.parseFile(filePath, { content, fileHash })
// Returns: Array of CodeBlock objects
// Example:
[
  {
    content: "public class MovieController { ... }",
    start_line: 10,
    end_line: 50,
    file_path: "src/Controllers/MovieController.java"
  },
  // ... more blocks
]
```

### Step 2.2: Generate Embeddings
```typescript
// Location: scanner.ts
const texts = blocks.map(block => block.content)
const { embeddings } = await embedder.createEmbeddings(texts)
// Returns: Array of number[] (each is 768-dimensional vector)
// Example:
[
  [0.0234, -0.1123, 0.4567, ...],  // 768 numbers for block 1
  [0.0456, 0.2345, -0.1234, ...],  // 768 numbers for block 2
  // ... more embeddings
]
```

**What happens:**
- Calls embedding API (OpenAI, Ollama, etc.)
- Each code block → one embedding vector (768 dimensions)
- Embeddings capture semantic meaning of code

### Step 2.3: Prepare Points for Storage
```typescript
// Location: scanner.ts
const points = blocks.map((block, index) => {
  const pointId = uuidv5(block.segmentHash, NAMESPACE)  // Unique ID
  
  return {
    id: pointId,                    // e.g., "a1b2c3d4-..."
    vector: embeddings[index],      // [0.0234, -0.1123, ...] (768 numbers)
    payload: {
      filePath: "src/Controllers/MovieController.java",
      codeChunk: "public class MovieController { ... }",
      startLine: 10,
      endLine: 50
    }
  }
})
```

### Step 2.4: Store in LanceDB
```typescript
// Location: lancedb-client.ts
await vectorStore.upsertPoints(points)
```

**What happens inside `upsertPoints()`:**

1. **Re-opens table** (fresh reference to avoid conflicts)
2. **Converts to LanceDB format**:
   ```typescript
   const records = points.map(point => ({
     id: point.id,
     vector: point.vector,           // Already number[]
     filePath: point.payload.filePath,
     codeChunk: point.payload.codeChunk,
     startLine: point.payload.startLine,
     endLine: point.payload.endLine
   }))
   ```

3. **Deletes existing records** (if any) with same IDs:
   ```typescript
   for (const id of ids) {
     await table.delete(`id = '${id}'`)  // LanceDB doesn't have native upsert
   }
   ```

4. **Adds new records**:
   ```typescript
   await table.add(records)
   ```

5. **Error handling**:
   - **Dimension mismatch**: Auto-recreates table with correct dimensions
   - **Commit conflicts**: Retries with exponential backoff (up to 5 times)

**Storage format in LanceDB:**
```
Table: vectors_<workspaceHash>
┌─────────────┬──────────────────────────┬──────────────────────┬─────────────┬───────────┐
│ id          │ vector (768 dims)        │ filePath             │ codeChunk   │ startLine │
├─────────────┼──────────────────────────┼──────────────────────┼─────────────┼───────────┤
│ uuid-1      │ [0.0234, -0.1123, ...]  │ src/Controllers/...  │ class ...   │ 10        │
│ uuid-2      │ [0.0456, 0.2345, ...]   │ src/Controllers/...  │ method ...  │ 20        │
│ ...         │ ...                      │ ...                  │ ...         │ ...       │
└─────────────┴──────────────────────────┴──────────────────────┴─────────────┴───────────┘
```

---

## 🔍 **PHASE 3: RETRIEVING EMBEDDINGS (SEARCH)**

### Step 3.1: User Query
```typescript
// User asks: "How to handle user authentication?"
// Location: codebaseSearchTool.ts
const query = "How to handle user authentication?"
```

### Step 3.2: Generate Query Embedding
```typescript
// Location: search-service.ts
const { embeddings } = await embedder.createEmbeddings([query])
const queryVector = embeddings[0]  // [0.1234, -0.5678, ...] (768 dimensions)
```

**What happens:**
- Same embedding model used for indexing
- Query text → 768-dimensional vector
- This vector represents the semantic meaning of the query

### Step 3.3: Search in LanceDB
```typescript
// Location: lancedb-client.ts
const results = await vectorStore.search(
  queryVector,           // [0.1234, -0.5678, ...]
  directoryPrefix,       // Optional: "src/Controllers/"
  minScore,             // Optional: 0.4 (minimum similarity)
  maxResults            // Optional: 50 (max results)
)
```

**What happens inside `search()`:**

#### Step 3.3.1: Prepare Query
```typescript
// Convert to Float32Array (required by LanceDB)
const queryVectorTyped = new Float32Array(queryVector)

// Re-open table for fresh reference
this.table = await this.db.openTable(this.tableName)
```

#### Step 3.3.2: Build Filter (if directory specified)
```typescript
// If searching in specific directory
if (directoryPrefix === "src/Controllers/") {
  filter = "filePath LIKE 'src/Controllers/%'"
}
```

#### Step 3.3.3: Execute Vector Search
```typescript
// Method 1: table.search() API (preferred)
let searchQuery = table.search(queryVectorTyped)
  .where(filter)                    // Apply directory filter
  .limit(50)                        // Limit results
  .distanceType("cosine")           // Use cosine similarity

// Get results directly as array
const results = await searchQuery.toArray()
```

**What LanceDB does internally:**
1. **Calculates cosine distance** between query vector and all stored vectors
2. **Finds nearest neighbors** (most similar vectors)
3. **Applies filters** (directory, etc.)
4. **Returns top N results** sorted by similarity

#### Step 3.3.4: Extract Results
```typescript
// Results from LanceDB look like:
[
  {
    id: "uuid-1",
    _distance: 0.234,              // Cosine distance (lower = more similar)
    filePath: "src/Controllers/UserController.java",
    codeChunk: "public class UserController { ... }",
    startLine: 10,
    endLine: 50
  },
  // ... more results
]
```

#### Step 3.3.5: Convert Distance to Similarity Score
```typescript
// Cosine distance: 0 = identical, 1 = opposite
// Convert to similarity: 1 - distance (higher = more similar)
results.map(r => ({
  id: r.id,
  score: 1 - r._distance,           // Convert: 0.234 → 0.766 (76.6% similar)
  payload: {
    filePath: r.filePath,
    codeChunk: r.codeChunk,
    startLine: r.startLine,
    endLine: r.endLine
  }
}))
```

#### Step 3.3.6: Filter by Threshold
```typescript
// Only keep results above minimum score
filteredResults = results.filter(r => r.score >= 0.4)  // minScore = 0.4
```

#### Step 3.3.7: Apply Post-Filtering (if needed)
```typescript
// If directory filter wasn't applied in query, filter now
if (directoryFilter) {
  filteredResults = filteredResults.filter(r => 
    r.payload.filePath.startsWith("src/Controllers/")
  )
}
```

#### Step 3.3.8: Limit Results
```typescript
// Take top N results
return filteredResults.slice(0, 50)  // maxResults = 50
```

### Step 3.4: Return Results
```typescript
// Final results format:
[
  {
    id: "uuid-1",
    score: 0.766,                    // 76.6% similarity
    payload: {
      filePath: "src/Controllers/UserController.java",
      codeChunk: "public class UserController { ... }",
      startLine: 10,
      endLine: 50
    }
  },
  // ... more results (sorted by score, highest first)
]
```

---

## 🔄 **COMPLETE FLOW DIAGRAM**

```
┌─────────────────────────────────────────────────────────────────┐
│                    STORING EMBEDDINGS                           │
└─────────────────────────────────────────────────────────────────┘

1. Code File
   └─> Parse Code (scanner.ts)
       └─> Code Blocks: [{content, startLine, endLine, ...}]
           └─> Generate Embeddings (embedder.createEmbeddings)
               └─> Embeddings: [[0.0234, ...], [0.0456, ...]]
                   └─> Prepare Points: [{id, vector, payload}]
                       └─> upsertPoints() (lancedb-client.ts)
                           └─> Delete Old Records (if any)
                               └─> table.add(records)
                                   └─> ✅ Stored in LanceDB Table


┌─────────────────────────────────────────────────────────────────┐
│                  RETRIEVING EMBEDDINGS                          │
└─────────────────────────────────────────────────────────────────┘

2. User Query: "How to handle authentication?"
   └─> Generate Query Embedding (embedder.createEmbeddings)
       └─> Query Vector: [0.1234, -0.5678, ...]
           └─> search() (lancedb-client.ts)
               └─> table.search(queryVector)
                   └─> .where(filter)      // Optional directory filter
                       └─> .limit(50)      // Max results
                           └─> .distanceType("cosine")
                               └─> .toArray()
                                   └─> Raw Results: [{id, _distance, ...}]
                                       └─> Convert Distance → Score
                                           └─> Filter by Threshold (score >= 0.4)
                                               └─> Sort by Score (highest first)
                                                   └─> Limit to Top N
                                                       └─> ✅ Return Results
```

---

## 🎯 **KEY CONCEPTS**

### 1. **Vector Similarity**
- **Cosine Distance**: Measures angle between vectors (0-1 scale)
  - `0.0` = Identical (same direction)
  - `1.0` = Opposite (opposite direction)
- **Similarity Score**: `1 - distance` (higher = more similar)
  - `0.9` = 90% similar (very relevant)
  - `0.4` = 40% similar (minimum threshold)

### 2. **Dimension Mismatch Handling**
- If table has 512-dim vectors but you try to add 768-dim:
  - **Auto-detects** during `initialize()` or `upsertPoints()`
  - **Deletes old table** automatically
  - **Creates new table** with correct dimensions
  - **Retries operation**

### 3. **Upsert Strategy**
- LanceDB doesn't have native `upsert()`
- **Our approach**: Delete old + Add new
  ```typescript
  await table.delete(`id = '${id}'`)  // Delete if exists
  await table.add(records)             // Add new
  ```

### 4. **Search API Priority**
1. **First try**: `table.search()` API (simpler, more reliable)
2. **Fallback**: `query().nearestTo()` API (if search() not available)

### 5. **Filtering**
- **Pre-filter**: Applied in LanceDB query (faster)
  ```typescript
  .where("filePath LIKE 'src/Controllers/%'")
  ```
- **Post-filter**: Applied after search (if pre-filter failed)
  ```typescript
  results.filter(r => r.payload.filePath.startsWith("src/Controllers/"))
  ```

---

## 📊 **EXAMPLE: Complete Flow**

### Storing:
```
File: UserController.java
  └─> Parse: 3 code blocks
      └─> Embed: 3 vectors (768 dims each)
          └─> Store: 3 records in LanceDB
              ✅ Indexed!
```

### Searching:
```
Query: "user login authentication"
  └─> Embed: 1 vector (768 dims)
      └─> Search: Find similar vectors
          └─> Results: 5 matches
              ├─> UserController.java (score: 0.89) ✅
              ├─> AuthService.java (score: 0.76) ✅
              ├─> LoginHandler.java (score: 0.65) ✅
              ├─> MovieController.java (score: 0.35) ❌ (below threshold)
              └─> ...
          └─> Return: Top 3 results (above 0.4 threshold)
```

---

## 🔧 **Optimization Features**

### 1. **Table Optimization**
```typescript
await vectorStore.optimizeTable()
```
- Compacts table
- Prunes old versions
- Reduces disk space
- Called after `clearCollection()`

### 2. **Retry Logic**
- **Commit conflicts**: Retry with exponential backoff
- **Dimension mismatches**: Auto-recreate table
- **Max retries**: 5 attempts

### 3. **Connection Management**
- Re-opens table before each operation (fresh reference)
- Prevents stale connection issues

---

This is how the complete flow works from storing embeddings to retrieving them! 🚀

