# LanceDB vs Qdrant: Complete Process & Result Comparison

## Overview

Both LanceDB and Qdrant implement semantic vector search, but they differ significantly in architecture, data extraction, filtering, and result processing. This document explains the complete process for each and highlights key differences.

---

## 🔍 **SEARCH PROCESS COMPARISON**

### **1. QUERY PREPARATION**

#### **LanceDB**

```typescript
// 1. Convert query vector to Float32Array (REQUIRED)
const queryVectorTyped = queryVector instanceof Float32Array ? queryVector : new Float32Array(queryVector)

// 2. Build SQL-like filter string for directory prefix
let filter = ""
if (directoryPrefix && directoryPrefix !== "." && directoryPrefix !== "./") {
	const normalizedPrefix = path.posix.normalize(directoryPrefix.replace(/\\/g, "/"))
	const cleanedPrefix =
		normalizedPrefix.startsWith("./") && normalizedPrefix !== "./" ? normalizedPrefix.slice(2) : normalizedPrefix

	if (cleanedPrefix !== "." && cleanedPrefix !== "./") {
		const escapedPrefix = cleanedPrefix.replace(/'/g, "''")
		filter = `filePath LIKE '${escapedPrefix}%'` // SQL-like syntax
	}
}
```

#### **Qdrant**

```typescript
// 1. Use query vector as-is (number[] is fine)
// No type conversion needed

// 2. Build structured filter object for directory prefix
let filter = undefined
if (directoryPrefix) {
	const normalizedPrefix = path.posix.normalize(directoryPrefix.replace(/\\/g, "/"))
	if (normalizedPrefix !== "." && normalizedPrefix !== "./") {
		const cleanedPrefix = path.posix.normalize(
			normalizedPrefix.startsWith("./") ? normalizedPrefix.slice(2) : normalizedPrefix,
		)
		const segments = cleanedPrefix.split("/").filter(Boolean)
		if (segments.length > 0) {
			filter = {
				must: segments.map((segment, index) => ({
					key: `pathSegments.${index}`, // Uses indexed path segments
					match: { value: segment },
				})),
			}
		}
	}
}
```

**Key Differences:**

- **LanceDB**: Requires `Float32Array` conversion, uses SQL-like `LIKE` filter
- **Qdrant**: Accepts `number[]`, uses structured JSON filter with indexed path segments

---

### **2. QUERY EXECUTION**

#### **LanceDB**

```typescript
// 1. Re-open table for fresh reference (prevents stale state)
this.table = await this.db.openTable(this.tableName)

// 2. Build query using fluent API
const queryBuilder = actualTable.query()
let searchQuery = queryBuilder.nearestTo(queryVectorTyped)

// 3. Select specific columns (optional but recommended)
if (searchQuery && typeof searchQuery.select === "function") {
	searchQuery = searchQuery.select(["id", "filePath", "codeChunk", "startLine", "endLine", "_distance"])
}

// 4. Apply SQL-like WHERE filter
if (filter !== "" && searchQuery && typeof searchQuery.where === "function") {
	searchQuery = searchQuery.where(filter)
}

// 5. Apply limit
if (searchQuery && typeof searchQuery.limit === "function") {
	searchQuery = searchQuery.limit(limit)
}

// 6. Execute query - returns RecordBatchIterator
const executeResult = await searchQuery.execute()
```

#### **Qdrant**

```typescript
// 1. Build complete search request object
const searchRequest: any = {
	query: queryVector, // Direct number[] array
	score_threshold: minScore ?? DEFAULT_SEARCH_MIN_SCORE,
	limit: maxResults ?? DEFAULT_MAX_SEARCH_RESULTS,
	params: {
		hnsw_ef: 128, // HNSW algorithm parameter
		exact: false,
	},
	with_payload: {
		include: ["filePath", "codeChunk", "startLine", "endLine", "pathSegments"],
	},
}

// 2. Add filter only if defined (Qdrant rejects undefined)
if (filter !== undefined) {
	searchRequest.filter = filter
}

// 3. Execute single query call - returns structured response
const operationResult = await this.client.query(this.collectionName, searchRequest)
```

**Key Differences:**

- **LanceDB**: Fluent API with method chaining, returns `RecordBatchIterator` (Apache Arrow format)
- **Qdrant**: Single request object, returns structured JSON response with `points` array

---

### **3. RESULT EXTRACTION**

#### **LanceDB** (Complex - Multiple Fallback Methods)

```typescript
// LanceDB returns RecordBatchIterator (Apache Arrow format)
// Requires complex extraction logic with multiple fallbacks:

private async extractResultsFromIterator(iterator: any): Promise<any[]> {
    // Method 1: Check if already an array
    if (Array.isArray(iterator)) {
        return iterator
    }

    // Method 2: Try Apache Arrow Table.fromAsync()
    let arrow = require("apache-arrow")
    if (arrow && arrow.Table && typeof arrow.Table.fromAsync === "function") {
        const table = await arrow.Table.fromAsync(iterator)
        if (table && typeof table.toArray === "function") {
            return await table.toArray()
        }
    }

    // Method 3: Try async iteration
    if (iterator && typeof iterator[Symbol.asyncIterator] === "function") {
        const results: any[] = []
        for await (const batch of iterator) {
            if (typeof batch.toArray === "function") {
                results.push(...await batch.toArray())
            }
        }
        return results
    }

    // Method 4: Manual iteration with next()
    const results: any[] = []
    while (true) {
        const nextResult = await iterator.next()
        if (!nextResult || nextResult.done) break

        const batch = nextResult.value
        // Try multiple extraction methods on batch...
        // (toArray(), toJSON(), direct array, .data property, etc.)
    }

    return results
}
```

#### **Qdrant** (Simple - Direct Access)

```typescript
// Qdrant returns structured response - direct access
const operationResult = await this.client.query(this.collectionName, searchRequest)

// Results are directly in operationResult.points array
// Each point has: { id, score, payload: { filePath, codeChunk, ... } }
const filteredPoints = operationResult.points.filter((p) => this.isPayloadValid(p.payload))

// Return as-is (already in correct format)
return filteredPoints as VectorStoreSearchResult[]
```

**Key Differences:**

- **LanceDB**: Complex extraction from Apache Arrow `RecordBatchIterator` with 4+ fallback methods
- **Qdrant**: Direct access to `points` array - no extraction needed

---

### **4. SCORE CONVERSION**

#### **LanceDB**

```typescript
// LanceDB returns _distance (lower is better for cosine distance)
// Need to convert to similarity score (higher is better)
const score =
	r._distance !== undefined
		? r._distance <= 1
			? 1 - r._distance // For cosine distance (0-1 range)
			: 1 / (1 + r._distance) // For other distance metrics
		: r.score || 0
```

#### **Qdrant**

```typescript
// Qdrant already returns similarity score (higher is better)
// No conversion needed - score is already in 0-1 range
// Direct use: point.score
```

**Key Differences:**

- **LanceDB**: Returns `_distance` (lower = better), requires conversion to similarity score
- **Qdrant**: Returns `score` (higher = better), already normalized

---

### **5. RESULT PROCESSING**

#### **LanceDB**

```typescript
private async processResults(results: any[], threshold: number, limit: number): Promise<VectorStoreSearchResult[]> {
    // 1. Convert distance to similarity score
    let filteredResults = results.map((r: any) => {
        const score = r._distance !== undefined
            ? (r._distance <= 1 ? (1 - r._distance) : (1 / (1 + r._distance)))
            : (r.score || 0)

        return {
            id: r.id,
            score: score,
            payload: {
                filePath: r.filePath,
                codeChunk: r.codeChunk,
                startLine: r.startLine,
                endLine: r.endLine,
            },
        }
    })

    // 2. Filter by threshold
    filteredResults = filteredResults.filter((r) => r.score >= threshold)

    // 3. Filter by payload validity
    filteredResults = filteredResults.filter((r) => this.isPayloadValid(r.payload))

    // 4. Apply limit
    if (filteredResults.length > limit) {
        filteredResults = filteredResults.slice(0, limit)
    }

    return filteredResults
}
```

#### **Qdrant**

```typescript
// Qdrant handles threshold and limit server-side
// Only need to validate payloads client-side
const filteredPoints = operationResult.points.filter((p) => this.isPayloadValid(p.payload))

// Results already filtered by:
// - score_threshold (server-side)
// - limit (server-side)
// - Payload validation (client-side)

return filteredPoints as VectorStoreSearchResult[]
```

**Key Differences:**

- **LanceDB**: Client-side filtering (threshold, limit, payload validation)
- **Qdrant**: Server-side filtering (threshold, limit), only payload validation client-side

---

## 📊 **RESULT FORMAT COMPARISON**

### **LanceDB Result Structure**

```typescript
{
    id: string,
    score: number,  // Converted from _distance (1 - distance)
    payload: {
        filePath: string,
        codeChunk: string,
        startLine: number,
        endLine: number,
    }
}
```

### **Qdrant Result Structure**

```typescript
{
    id: string,
    score: number,  // Already similarity score (0-1)
    payload: {
        filePath: string,
        codeChunk: string,
        startLine: number,
        endLine: number,
        pathSegments: { "0": "src", "1": "main", ... }  // Additional metadata
    }
}
```

---

## 🔄 **FILTERING DIFFERENCES**

### **LanceDB Filtering**

- **Type**: SQL-like string (`filePath LIKE 'src/%'`)
- **Method**: Applied via `.where()` method on query builder
- **Execution**: Client-side filtering after query execution
- **Limitation**: Only supports prefix matching via `LIKE`

### **Qdrant Filtering**

- **Type**: Structured JSON object with `must`/`should`/`must_not` clauses
- **Method**: Included in search request object
- **Execution**: Server-side filtering (more efficient)
- **Advantage**: Supports complex queries, indexed path segments for fast filtering

**Example Qdrant Filter:**

```typescript
{
	must: [
		{ key: "pathSegments.0", match: { value: "src" } },
		{ key: "pathSegments.1", match: { value: "main" } },
	]
}
```

---

## ⚡ **PERFORMANCE CHARACTERISTICS**

### **LanceDB**

- **Storage**: Local file-based (embedded)
- **Query Speed**: Fast for local queries, but requires:
    - Table re-opening for fresh state
    - Complex Arrow extraction
    - Client-side filtering
- **Scalability**: Limited by local disk I/O
- **Network**: No network overhead (local only)

### **Qdrant**

- **Storage**: Remote server (or local)
- **Query Speed**: Very fast with:
    - Server-side filtering and limiting
    - Optimized HNSW index
    - Direct JSON response
- **Scalability**: Excellent (distributed architecture)
- **Network**: Network latency (if remote)

---

## 🐛 **COMMON ISSUES & SOLUTIONS**

### **LanceDB Issues**

1. **"Get TypedArray info failed"**

    - **Cause**: Passing `number[]` instead of `Float32Array`
    - **Fix**: Convert to `Float32Array` before `nearestTo()`

2. **"Search returned 0 results"**

    - **Cause**: `RecordBatchIterator` not properly extracted
    - **Fix**: Use Apache Arrow `Table.fromAsync()` or manual iteration

3. **"Table not found" after recreation**

    - **Cause**: Stale table reference
    - **Fix**: Re-open table before each operation

4. **Dimension mismatch during indexing**
    - **Cause**: Table schema has different vector dimension
    - **Fix**: Delete old table and re-index (no automatic fix)

### **Qdrant Issues**

1. **"Bad Request" error**

    - **Cause**: `undefined` filter in request object
    - **Fix**: Only include filter if `filter !== undefined`

2. **"Vector dimension error: expected dim: 512, got 768"**

    - **Cause**: Collection dimension doesn't match query vector
    - **Fix**: Use correct embedding model or re-index collection

3. **"Collection not found"**
    - **Cause**: Collection doesn't exist or wrong name
    - **Fix**: Check collection name hash or create collection

---

## 📈 **WHEN TO USE WHICH**

### **Use LanceDB When:**

- ✅ Local development only
- ✅ No network/server setup needed
- ✅ Privacy-sensitive (data stays local)
- ✅ Simple prefix filtering is sufficient
- ✅ Small to medium codebases

### **Use Qdrant When:**

- ✅ Team collaboration (shared index)
- ✅ Need complex filtering queries
- ✅ Large codebases (better scalability)
- ✅ Server infrastructure available
- ✅ Need read-only access to shared indexes

---

## 🎯 **SUMMARY OF KEY DIFFERENCES**

| Aspect                | LanceDB                            | Qdrant                     |
| --------------------- | ---------------------------------- | -------------------------- |
| **Architecture**      | Embedded local DB                  | Remote server              |
| **Query Vector**      | Must be `Float32Array`             | `number[]` is fine         |
| **Filter Type**       | SQL-like string                    | Structured JSON            |
| **Filter Execution**  | Client-side                        | Server-side                |
| **Result Format**     | Apache Arrow `RecordBatchIterator` | Direct JSON `points` array |
| **Result Extraction** | Complex (4+ fallback methods)      | Simple (direct access)     |
| **Score Format**      | `_distance` (lower = better)       | `score` (higher = better)  |
| **Score Conversion**  | Required (1 - distance)            | Not needed                 |
| **Threshold/Limit**   | Client-side                        | Server-side                |
| **Path Filtering**    | `LIKE` prefix match                | Indexed path segments      |
| **Network**           | None (local)                       | Required (if remote)       |
| **Setup Complexity**  | Low (embedded)                     | Medium (server setup)      |

---

## 🔍 **ACTUAL SEARCH FLOW**

### **LanceDB Flow:**

```
1. Convert queryVector → Float32Array
2. Build SQL filter string (if directoryPrefix)
3. table.query().nearestTo(vector).select().where().limit()
4. Execute → RecordBatchIterator
5. Extract from Arrow (Table.fromAsync or manual iteration)
6. Convert _distance → similarity score
7. Filter by threshold (client-side)
8. Filter by payload validity
9. Apply limit (client-side)
10. Return results
```

### **Qdrant Flow:**

```
1. Use queryVector as-is (number[])
2. Build JSON filter object (if directoryPrefix)
3. Build search request object
4. client.query(collection, request)
5. Get operationResult.points (direct array)
6. Filter by payload validity (client-side)
7. Return results (already filtered by server)
```

---

## 📝 **CONCLUSION**

**LanceDB** is simpler to set up (no server) but requires more complex result extraction and client-side processing. It's ideal for local development.

**Qdrant** requires server setup but provides cleaner APIs, server-side optimization, and better scalability. It's ideal for team collaboration and production use.

Both implementations produce the same final result format (`VectorStoreSearchResult[]`), ensuring compatibility with the rest of the codebase.
