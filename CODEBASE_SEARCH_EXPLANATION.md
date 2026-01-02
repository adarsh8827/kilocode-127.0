# How Codebase Search Tool Works

## Overview

The `codebase_search` tool performs **semantic search** on your codebase using a vector database (either Qdrant or LanceDB). It does **NOT** read files one by one - instead, it searches a pre-built index of code chunks.

## How It Works

### 1. **Indexing Phase** (Happens Once, in Background)
   - When you enable code indexing, the extension:
     - Scans your workspace files
     - Splits code into chunks (functions, classes, etc.)
     - Generates embeddings (vector representations) for each chunk
     - Stores these embeddings in the vector store (Qdrant or LanceDB)
   - This happens **once** when indexing starts, not during search

### 2. **Search Phase** (When You Query)
   When the AI uses the `codebase_search` tool:

   ```
   User Query → Embedding Generation → Vector Store Search → Results
   ```

   **Step-by-step:**
   1. **Query Processing**: Your query (e.g., "certificate management security") is converted to an embedding vector
   2. **Vector Search**: The vector store finds code chunks with similar embeddings
   3. **Results**: Returns the most relevant code chunks with:
      - File path
      - Line numbers (start/end)
      - Code snippet
      - Similarity score

### 3. **Vector Store Selection**

The tool automatically uses whichever vector store is configured:

- **Qdrant** (Remote): 
  - Searches shared team indexes
  - Collection name is configured in settings
  - Logs: `[QdrantVectorStore] Querying collection "..."`

- **LanceDB** (Local):
  - Searches your local index
  - Stored in VS Code global storage
  - Logs: `[LanceDBVectorStore] Searching table "..."`

## Key Points

✅ **Does NOT read files one by one** - searches pre-indexed embeddings
✅ **Semantic search** - finds code by meaning, not exact text match
✅ **Fast** - vector search is much faster than reading all files
✅ **Automatic** - AI decides when to use it based on your query
✅ **Works with both Qdrant and LanceDB** - automatically uses the configured store

## When Does It Trigger?

The AI automatically uses `codebase_search` when:
- You ask questions about your codebase
- You need to find specific functionality
- You mention "search codebase" or "find code"
- The query would benefit from semantic search

**Example queries that trigger codebase search:**
- "How does certificate management work?"
- "Find authentication code"
- "Where is the login function?"
- "Search for error handling patterns"

## Current Flow

```
User: "use codebase search tool for certificate management"
  ↓
AI: Uses <codebase_search> tool
  ↓
Tool: Generates embedding for "certificate management"
  ↓
Vector Store (Qdrant/LanceDB): Finds similar code chunks
  ↓
Results: Returns relevant code snippets with file paths and line numbers
  ↓
AI: Uses results to answer your question
```

## Logging

You can see which vector store is being used in the console:
- **Qdrant**: `[QdrantVectorStore] Querying collection "..." at ...`
- **LanceDB**: `[LanceDBVectorStore] Searching table "..." at ...`

## Configuration

- **Vector Store Type**: Set in settings (Qdrant or LanceDB)
- **Qdrant URL**: Configured in settings
- **Collection Name**: Auto-generated or custom
- **LanceDB Path**: Defaults to VS Code global storage

The tool automatically uses the configured vector store - no manual selection needed!

