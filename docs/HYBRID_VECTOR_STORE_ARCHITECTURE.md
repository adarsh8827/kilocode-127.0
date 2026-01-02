# Hybrid Vector Store Architecture

## Team Mode with Local Development Support

---

## 📋 Executive Summary

The Hybrid Vector Store architecture enables seamless code indexing for team collaboration while supporting real-time local development. It combines a **centralized team index (Quadrant)** with **local indexing (LanceDB)** for changed files, providing developers with immediate context for their modifications without waiting for CI/CD pipelines.

**Key Value Proposition:**

- ✅ **Team Collaboration**: Shared central index for all team members
- ✅ **Real-Time Development**: Instant indexing of local changes
- ✅ **Zero Configuration**: Automatic detection and routing
- ✅ **Best of Both Worlds**: Team context + Local changes

---

## 🏗️ Architecture Overview

### System Architecture Diagram

```mermaid
graph TB
    subgraph "Hybrid Vector Store System"
        FW[File Watcher<br/>Monitors File Changes]
        CFT[Changed Files Tracker<br/>Git Status Detection]
        HVS[Hybrid Vector Store<br/>Router & Merger]

        subgraph "Vector Stores"
            QS[Quadrant Store<br/>Read-Only<br/>Team Index]
            LS[Local LanceDB Store<br/>Writable<br/>Changed Files]
        end

        subgraph "Search Service"
            SS[Search Service<br/>Query Processing]
        end

        FW -->|File Change Events| HVS
        CFT -->|Changed Files List| HVS
        HVS -->|Route Changed Files| LS
        HVS -->|Skip Unchanged Files| QS
        HVS -->|Search Both| QS
        HVS -->|Search Both| LS
        QS -->|Results| HVS
        LS -->|Results| HVS
        HVS -->|Merged Results| SS
        SS -->|Final Results| User[Developer]
    end

    style HVS fill:#4CAF50,stroke:#2E7D32,color:#fff
    style QS fill:#2196F3,stroke:#1565C0,color:#fff
    style LS fill:#FF9800,stroke:#E65100,color:#fff
    style CFT fill:#9C27B0,stroke:#6A1B9A,color:#fff
    style FW fill:#F44336,stroke:#C62828,color:#fff
```

### Component Interaction Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant FW as File Watcher
    participant CFT as Changed Files Tracker
    participant HVS as Hybrid Vector Store
    participant QS as Quadrant Store
    participant LS as Local Store
    participant UI as UI

    Dev->>FW: Save File (models.py)
    FW->>FW: Detect Change Event
    FW->>FW: Batch Processing (500ms debounce)
    FW->>UI: Show Progress: "Indexing..."
    FW->>HVS: upsertPoints(points)
    HVS->>CFT: Refresh Git Status
    CFT->>CFT: Run: git status --porcelain
    CFT-->>HVS: Changed Files: [models.py]
    HVS->>HVS: Route Decision: models.py changed?
    HVS->>LS: Index to Local Store
    LS-->>HVS: Success
    HVS-->>FW: Complete
    FW->>UI: Show: "Indexed to local store"

    Note over Dev,UI: Developer searches for code
    Dev->>HVS: search(query)
    HVS->>QS: Search Quadrant (parallel)
    HVS->>LS: Search Local (parallel)
    QS-->>HVS: Results (20)
    LS-->>HVS: Results (8)
    HVS->>HVS: Merge & Deduplicate
    HVS->>HVS: Prioritize Local Results
    HVS-->>Dev: Combined Results (23)
```

---

## 🔄 Complete System Flow

### Phase 1: Initialization (Plugin Startup)

```mermaid
flowchart TD
    Start([Plugin Opens]) --> Detect[Detect Git Repository]
    Detect --> Extract[Extract Branch Name]
    Extract --> Generate[Generate Index Name<br/>projectName-branchName]

    Generate --> Check{Check Quadrant<br/>Collection Exists?}

    Check -->|YES| Hybrid[Use Hybrid Mode<br/>Quadrant + Local]
    Check -->|NO| LanceDB[Switch to LanceDB Mode<br/>Local Only]

    Hybrid --> InitQ[Initialize Quadrant Store<br/>Read-Only]
    Hybrid --> InitL[Initialize Local Store<br/>Writable]
    Hybrid --> InitCFT[Initialize Changed Files Tracker]

    InitQ --> Refresh[Refresh Git Status]
    InitL --> Refresh
    InitCFT --> Refresh

    Refresh --> DetectFiles[Detect Changed Files]
    DetectFiles --> StartFW[Start File Watcher]

    LanceDB --> StartFW

    StartFW --> Monitor[Monitor File Changes<br/>Create/Modify/Delete]
    Monitor --> Batch[Batch Processing<br/>500ms debounce]
    Batch --> Ready([System Ready])

    style Hybrid fill:#4CAF50,stroke:#2E7D32,color:#fff
    style LanceDB fill:#FF9800,stroke:#E65100,color:#fff
    style Ready fill:#2196F3,stroke:#1565C0,color:#fff
```

**Result:** System ready, file watcher active, changed files detected.

---

### Phase 2: File Change Detection & Indexing

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant FS as File System
    participant FW as File Watcher
    participant Parser as Code Parser
    participant Embedder as Embedder
    participant HVS as Hybrid Store
    participant CFT as Changed Files Tracker
    participant LS as Local Store
    participant UI as UI

    Dev->>FS: Save File (models.py)
    FS->>FW: File Change Event
    FW->>FW: Add to Batch Queue
    FW->>FW: Debounce Timer (500ms)

    FW->>UI: Show: "Starting batch processing"
    FW->>Parser: Parse File
    Parser->>Parser: Extract Code Blocks
    Parser-->>FW: Code Blocks

    FW->>Embedder: Generate Embeddings
    Embedder-->>FW: Embedding Vectors

    FW->>FW: Prepare Points for Upsert
    FW->>HVS: upsertPoints(points)

    HVS->>CFT: Refresh Git Status
    CFT->>CFT: Run: git status --porcelain
    CFT-->>HVS: Changed Files Set

    HVS->>HVS: Check: models.py in changed files?
    alt File Changed
        HVS->>LS: Index to Local Store
        LS-->>HVS: Success
        HVS->>UI: Update: "Indexing X/Y files..."
    else File Unchanged
        HVS->>HVS: Skip (already in Quadrant)
    end

    HVS-->>FW: Complete
    FW->>UI: Show: "Indexed to local store"
```

**Result:** Changed file indexed to local store in real-time.

---

### Phase 3: Search Operation

```mermaid
flowchart LR
    Start([Developer Searches<br/>user authentication]) --> Embed[Generate Query<br/>Embedding]

    Embed --> Parallel{Parallel Search}

    Parallel --> QSearch[Search Quadrant Store<br/>Unchanged Files]
    Parallel --> LSearch[Search Local Store<br/>Changed Files]

    QSearch --> QResults[20 Results<br/>Team Code]
    LSearch --> LResults[8 Results<br/>Your Changes]

    QResults --> Merge[Merge & Deduplicate]
    LResults --> Merge

    Merge --> Dedup[Deduplicate by<br/>filePath + startLine]
    Dedup --> Priority[Priority: Local Wins]
    Priority --> Sort[Sort by Score]
    Sort --> Limit[Apply maxResults Limit]
    Limit --> Final[23 Unique Results<br/>8 Local + 15 Quadrant]

    Final --> Return([Return to Developer])

    style Parallel fill:#4CAF50,stroke:#2E7D32,color:#fff
    style Merge fill:#2196F3,stroke:#1565C0,color:#fff
    style Final fill:#FF9800,stroke:#E65100,color:#fff
```

**Result:** Comprehensive search results from both team index and local changes.

---

## 🎯 Developer Experience Flow

### Scenario: Developer Working on Feature Branch

```mermaid
gantt
    title Developer Workflow Timeline
    dateFormat HH:mm
    axisFormat %H:%M

    section Day 1: Morning
    Open VS Code           :a1, 09:00, 1m
    Auto-detect Branch     :a2, after a1, 30s
    Check Quadrant         :a3, after a2, 2s
    Start File Watcher     :a4, after a3, 1s
    Ready for Development  :a5, after a4, 1s

    section Day 1: Development
    Modify models.py        :b1, 10:00, 5m
    Save File              :b2, after b1, 1s
    Auto-Index (< 1s)      :b3, after b2, 1s
    Search Query           :b4, after b3, 2m
    Get Results (23)       :b5, after b4, 1s

    section Day 1: Afternoon
    Modify 5 Files         :c1, 14:00, 30m
    Auto-Index All         :c2, after c1, 5s
    Continue Development   :c3, after c2, 2h

    section Day 2: After CI/CD
    Changes Merged         :d1, 09:00, 1m
    CI/CD Indexes          :d2, after d1, 10m
    Local Cleanup          :d3, after d2, 1s
    Seamless Transition    :d4, after d3, 1s
```

### Developer Workflow Diagram

```mermaid
stateDiagram-v2
    [*] --> OpenVSCode: Developer Opens VS Code
    OpenVSCode --> AutoDetect: Plugin Initializes
    AutoDetect --> CheckQuadrant: Detect Git Branch
    CheckQuadrant --> HybridMode: Collection Exists
    CheckQuadrant --> LanceDBMode: Collection Not Found

    HybridMode --> FileWatcherActive: Start File Watcher
    LanceDBMode --> FileWatcherActive: Start File Watcher

    FileWatcherActive --> Development: Ready

    state Development {
        [*] --> ModifyFile
        ModifyFile --> SaveFile
        SaveFile --> FileWatcherDetects
        FileWatcherDetects --> AutoIndex
        AutoIndex --> Indexed
        Indexed --> Search
        Search --> GetResults
        GetResults --> ModifyFile
    }

    Development --> CI_CD: Changes Committed
    CI_CD --> Merged: CI/CD Pipeline
    Merged --> Cleanup: Local Store Cleanup
    Cleanup --> [*]
```

---

## 🔍 Technical Architecture Details

### Component: HybridVectorStore

**Responsibilities:**

- Routes upserts to appropriate store
- Merges search results from both stores
- Manages changed files tracking
- Handles deduplication logic

**Key Methods:**

```typescript
class HybridVectorStore {
    // Route changed files to local, skip unchanged
    async upsertPoints(points): Promise<void>

    // Search both stores in parallel, merge results
    async search(queryVector, ...): Promise<VectorStoreSearchResult[]>

    // Initialize both stores
    async initialize(): Promise<boolean>
}
```

### Component: ChangedFilesTracker

**Responsibilities:**

- Detects changed files using git status
- Caches results (5-second TTL)
- Provides real-time file change detection

**Key Methods:**

```typescript
class ChangedFilesTracker {
	// Get current changed files (cached)
	async getChangedFiles(): Promise<Set<string>>

	// Check if specific file is changed
	async isFileChanged(filePath): Promise<boolean>

	// Force refresh from git
	async refresh(): Promise<void>
}
```

### Component: FileWatcher

**Responsibilities:**

- Monitors file system changes
- Batches processing (500ms debounce)
- Triggers indexing on save

**Key Events:**

- `onDidStartBatchProcessing` - Batch started
- `onBatchProgressUpdate` - Progress update
- `onDidFinishBatchProcessing` - Batch complete

---

## ✅ Pros (Advantages)

### 1. **Team Collaboration**

- ✅ **Centralized Index**: Single source of truth for team
- ✅ **Consistency**: All developers use same base index
- ✅ **Efficiency**: No duplicate indexing across team
- ✅ **Scalability**: Handles large codebases efficiently

### 2. **Developer Productivity**

- ✅ **Real-Time Context**: Immediate indexing of changes
- ✅ **No Waiting**: Don't wait for CI/CD to see your changes
- ✅ **Seamless Experience**: Works automatically
- ✅ **Better Search**: Results include both team code and your changes

### 3. **Performance**

- ✅ **Parallel Search**: Both stores searched simultaneously
- ✅ **Fast Local Store**: Local LanceDB is very fast
- ✅ **Efficient Routing**: Only changed files indexed locally
- ✅ **Minimal Overhead**: < 100ms additional latency

### 4. **Reliability**

- ✅ **Graceful Degradation**: Falls back if one store fails
- ✅ **Timeout Protection**: 5s Qdrant, 2s Local
- ✅ **Error Handling**: Continues working on partial failure
- ✅ **Automatic Recovery**: Self-healing on errors

### 5. **Maintenance**

- ✅ **Zero Configuration**: Auto-detects everything
- ✅ **Git Integration**: Uses existing git workflow
- ✅ **Automatic Cleanup**: Removes local data when merged
- ✅ **Logging**: Comprehensive logs for debugging

---

## ❌ Cons (Limitations & Considerations)

### 1. **Git Dependency**

- ⚠️ **Requires Git**: Only works in git repositories
- ⚠️ **Git Status Performance**: Can be slow on very large repos (10k+ files)
- ⚠️ **Mitigation**: Caching (5s TTL) + timeout (2s max)

### 2. **Storage Overhead**

- ⚠️ **Local Storage**: Changed files stored locally (typically < 100 files)
- ⚠️ **Disk Space**: Minimal impact (only changed files)
- ⚠️ **Mitigation**: Auto-cleanup when files revert

### 3. **Complexity**

- ⚠️ **More Components**: Hybrid store, changed files tracker
- ⚠️ **Debugging**: More moving parts to troubleshoot
- ⚠️ **Mitigation**: Comprehensive logging (`[HYBRID]` prefix)

### 4. **Edge Cases**

- ⚠️ **Path Matching**: Windows vs Unix path differences
- ⚠️ **Git Status Timing**: Small delay between save and git status update
- ⚠️ **Mitigation**: Path normalization + refresh before routing

### 5. **Initial Setup**

- ⚠️ **Quadrant Required**: Needs central Qdrant instance
- ⚠️ **CI/CD Integration**: Requires indexing pipeline
- ⚠️ **Mitigation**: Falls back to LanceDB-only if Quadrant unavailable

---

## 📊 Performance Metrics

### Search Performance Comparison

```mermaid
graph LR
    subgraph "Search Latency"
        Q1[Quadrant Only<br/>100-300ms]
        L1[LanceDB Only<br/>50-150ms]
        H1[Hybrid Mode<br/>100-400ms<br/>Parallel]
    end

    subgraph "Result Coverage"
        Q2[Team Code Only]
        L2[Local Code Only]
        H2[Both: Team + Local]
    end

    subgraph "Features"
        Q3[No Parallel<br/>No Timeout]
        L3[No Parallel<br/>No Timeout]
        H3[Parallel Search<br/>Timeout Protection]
    end

    style H1 fill:#4CAF50,stroke:#2E7D32,color:#fff
    style H2 fill:#4CAF50,stroke:#2E7D32,color:#fff
    style H3 fill:#4CAF50,stroke:#2E7D32,color:#fff
```

### Indexing Performance Comparison

| Metric               | Quadrant Only   | LanceDB Only  | Hybrid Mode        |
| -------------------- | --------------- | ------------- | ------------------ |
| **Initial Indexing** | N/A (read-only) | Full scan     | File watcher only  |
| **Change Detection** | N/A             | Real-time     | Real-time          |
| **Indexing Speed**   | N/A             | Fast          | Fast (local only)  |
| **Storage Used**     | 0 (read-only)   | Full codebase | Changed files only |

---

## 🚀 Developer Workflow Benefits

### Before vs After Comparison

```mermaid
graph TB
    subgraph "Before: Quadrant Only"
        B1[Make Changes] --> B2[Wait for CI/CD<br/>Hours/Days]
        B2 --> B3[Search Excludes<br/>Your Changes]
        B3 --> B4[Work Without<br/>Full Context]
    end

    subgraph "After: Hybrid Mode"
        A1[Make Changes] --> A2[Save File<br/>< 1 Second]
        A2 --> A3[Auto-Indexed<br/>Immediately]
        A3 --> A4[Search Includes<br/>Your Changes]
        A4 --> A5[Work With<br/>Full Context]
    end

    style B2 fill:#F44336,stroke:#C62828,color:#fff
    style B3 fill:#F44336,stroke:#C62828,color:#fff
    style A2 fill:#4CAF50,stroke:#2E7D32,color:#fff
    style A3 fill:#4CAF50,stroke:#2E7D32,color:#fff
    style A5 fill:#4CAF50,stroke:#2E7D32,color:#fff
```

### Workflow Timeline Comparison

```mermaid
gantt
    title Workflow Comparison: Before vs After
    dateFormat HH:mm
    axisFormat %H:%M

    section Before: Quadrant Only
    Make Changes           :b1, 09:00, 30m
    Wait for CI/CD         :b2, after b1, 4h
    Search (No Changes)    :b3, after b2, 5m
    Work Without Context   :b4, after b3, 2h

    section After: Hybrid Mode
    Make Changes           :a1, 09:00, 30m
    Auto-Index (< 1s)      :a2, after a1, 1s
    Search (With Changes)  :a3, after a2, 5m
    Work With Full Context :a4, after a3, 2h
```

### Key Improvements

- ⚡ **10,000x faster**: Seconds vs hours for indexing
- 🎯 **Better Context**: See your changes in search results
- 🔄 **Real-Time**: Always up-to-date
- 🤖 **Automatic**: Zero manual intervention

---

## 🔧 Implementation Details

### Automatic Detection Logic

```mermaid
flowchart TD
    Start([Plugin Startup]) --> Git{Git Repository?}
    Git -->|No| NonGit[Non-Git Project]
    Git -->|Yes| Branch[Extract Branch Name]

    NonGit --> LanceDBOnly[LanceDB Mode Only]

    Branch --> Generate[Generate Index Name<br/>projectName-branchName]
    Generate --> Check{Check Quadrant<br/>Collection Exists?}

    Check -->|YES| Hybrid[Hybrid Mode<br/>Quadrant + Local]
    Check -->|NO| LanceDB[LanceDB Mode<br/>Local Only]

    Hybrid --> StartFW[Start File Watcher]
    LanceDB --> StartFW
    LanceDBOnly --> StartFW

    StartFW --> Monitor[Monitor File Changes]

    style Hybrid fill:#4CAF50,stroke:#2E7D32,color:#fff
    style LanceDB fill:#FF9800,stroke:#E65100,color:#fff
```

### File Routing Logic

```mermaid
flowchart LR
    Save[File Save Event] --> Detect[File Watcher Detects]
    Detect --> Process[Process File<br/>Parse & Embed]
    Process --> Check{Check Git Status<br/>Is File Changed?}

    Check -->|YES| RouteLocal[Route to Local Store ✅]
    Check -->|NO| Skip[Skip<br/>Already in Quadrant ⏭️]

    RouteLocal --> Index[Index to Local LanceDB]
    Index --> Complete[Complete]
    Skip --> Complete

    style RouteLocal fill:#4CAF50,stroke:#2E7D32,color:#fff
    style Skip fill:#9E9E9E,stroke:#616161,color:#fff
```

### Search Merging Logic

```mermaid
flowchart TD
    Query[Search Query] --> Embed[Generate Embedding]
    Embed --> Parallel{Parallel Search}

    Parallel --> QSearch[Search Quadrant<br/>Unchanged Files]
    Parallel --> LSearch[Search Local<br/>Changed Files]

    QSearch --> QRes[Qdrant Results<br/>20 results]
    LSearch --> LRes[Local Results<br/>8 results]

    QRes --> Merge[Merge Results]
    LRes --> Merge

    Merge --> Dedup[Deduplicate<br/>by filePath + startLine]
    Dedup --> Priority[Priority: Local Wins]
    Priority --> Sort[Sort by Score]
    Sort --> Limit[Apply Limit]
    Limit --> Return[Return Results<br/>23 unique]

    style Parallel fill:#4CAF50,stroke:#2E7D32,color:#fff
    style Merge fill:#2196F3,stroke:#1565C0,color:#fff
```

---

## 📈 Business Value

### For Development Teams

- **Faster Development**: Immediate context for changes
- **Better Code Quality**: More relevant search results
- **Reduced Friction**: No waiting for CI/CD
- **Improved Collaboration**: Shared team index + local changes

### For Organizations

- **Cost Efficiency**: Centralized indexing (no duplication)
- **Scalability**: Handles large teams and codebases
- **Maintainability**: Automatic, self-managing system
- **Developer Satisfaction**: Better tooling experience

---

## 🔄 LanceDB-Only Mode (Fallback)

### When Quadrant is Not Available

When the Quadrant collection is not found (or Quadrant server is unavailable), the system automatically falls back to **LanceDB-only mode**. This ensures the system always works, even without a central team index.

### LanceDB-Only Mode Flow

```mermaid
flowchart TD
    Start([Plugin Opens]) --> Detect[Detect Git Branch]
    Detect --> Check{Check Quadrant<br/>Collection Exists?}

    Check -->|NO| LanceDB[LanceDB-Only Mode]
    Check -->|ERROR| LanceDB

    LanceDB --> Init[Initialize LanceDB Store]
    Init --> Scan[Full Workspace Scan]
    Scan --> Index[Index All Files<br/>Complete Codebase]
    Index --> FW[Start File Watcher]

    FW --> Monitor[Monitor File Changes]
    Monitor --> Change{File Changed?}
    Change -->|YES| ReIndex[Re-Index File<br/>Real-Time]
    Change -->|NO| Monitor

    ReIndex --> Ready[Ready for Search]
    Ready --> Search[Developer Searches]
    Search --> LSearch[Search LanceDB Only]
    LSearch --> Results[Return Results<br/>All Files]

    style LanceDB fill:#FF9800,stroke:#E65100,color:#fff
    style Scan fill:#FF9800,stroke:#E65100,color:#fff
    style LSearch fill:#FF9800,stroke:#E65100,color:#fff
```

### LanceDB-Only Mode Characteristics

#### **Initial Indexing**

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant System as System
    participant Scanner as Directory Scanner
    participant Parser as Code Parser
    participant Embedder as Embedder
    participant LanceDB as LanceDB Store
    participant FW as File Watcher

    Dev->>System: Open VS Code
    System->>System: Check Quadrant (Not Found)
    System->>System: Switch to LanceDB Mode
    System->>LanceDB: Initialize Store

    System->>Scanner: Scan Workspace
    Scanner->>Scanner: Find All Files
    Scanner->>Parser: Parse Each File
    Parser->>Parser: Extract Code Blocks
    Parser->>Embedder: Generate Embeddings
    Embedder->>LanceDB: Index All Blocks

    Note over System,LanceDB: Full Codebase Indexed

    System->>FW: Start File Watcher
    FW-->>Dev: System Ready
    System-->>Dev: "Indexing complete. File watcher started."
```

**Key Points:**

- ✅ **Full Indexing**: Indexes entire codebase (not just changed files)
- ✅ **Complete Coverage**: All files available for search
- ✅ **Real-Time Updates**: File watcher monitors changes
- ✅ **Self-Contained**: No external dependencies

#### **File Change Handling**

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant FW as File Watcher
    participant Parser as Code Parser
    participant Embedder as Embedder
    participant LanceDB as LanceDB Store
    participant UI as UI

    Dev->>FW: Save File (models.py)
    FW->>FW: Detect Change
    FW->>UI: Show: "Indexing 1 / 1 files..."

    FW->>Parser: Parse File
    Parser->>Parser: Extract Code Blocks
    Parser-->>FW: Code Blocks

    FW->>Embedder: Generate Embeddings
    Embedder-->>FW: Embedding Vectors

    FW->>LanceDB: upsertPoints(blocks)
    LanceDB->>LanceDB: Update Index
    LanceDB-->>FW: Success

    FW->>UI: Show: "Files indexed to local store"
    UI-->>Dev: Ready for Search
```

**Key Points:**

- ✅ **All Files Indexed**: Every file in workspace
- ✅ **Real-Time Updates**: Changes indexed immediately
- ✅ **Complete Search**: Search includes all files
- ✅ **Local Storage**: Stored on developer's machine

#### **Search Operation**

```mermaid
flowchart LR
    Query[Search Query] --> Embed[Generate Embedding]
    Embed --> Search[Search LanceDB]
    Search --> Results[All Results<br/>From Local Index]
    Results --> Return[Return to Developer]

    style Search fill:#FF9800,stroke:#E65100,color:#fff
    style Results fill:#FF9800,stroke:#E65100,color:#fff
```

**Key Points:**

- ✅ **Single Store**: Only searches LanceDB
- ✅ **Fast Search**: 50-150ms latency
- ✅ **Complete Results**: All indexed files included
- ✅ **No Merging**: Direct results (simpler)

### LanceDB-Only vs Hybrid Mode Comparison

```mermaid
graph TB
    subgraph "LanceDB-Only Mode"
        L1[Full Workspace Scan] --> L2[Index All Files]
        L2 --> L3[Local Storage Only]
        L3 --> L4[Search Local Only]
    end

    subgraph "Hybrid Mode"
        H1[No Initial Scan] --> H2[Index Changed Files Only]
        H2 --> H3[Local + Quadrant Storage]
        H3 --> H4[Search Both Stores]
    end

    style L1 fill:#FF9800,stroke:#E65100,color:#fff
    style H1 fill:#4CAF50,stroke:#2E7D32,color:#fff
```

| Aspect                 | LanceDB-Only        | Hybrid Mode             |
| ---------------------- | ------------------- | ----------------------- |
| **Initial Indexing**   | Full workspace scan | File watcher only       |
| **Storage**            | All files locally   | Changed files only      |
| **Search Source**      | Local only          | Local + Quadrant        |
| **Team Collaboration** | No (local only)     | Yes (shared index)      |
| **Setup Time**         | Initial scan needed | Instant (uses Quadrant) |
| **Storage Usage**      | Full codebase       | Changed files only      |

### When LanceDB-Only Mode is Used

```mermaid
flowchart TD
    Start([System Startup]) --> Check{Quadrant Available?}

    Check -->|Collection Not Found| LanceDB1[LanceDB-Only Mode]
    Check -->|Server Unavailable| LanceDB2[LanceDB-Only Mode]
    Check -->|No Git Repository| LanceDB3[LanceDB-Only Mode]
    Check -->|Error Connecting| LanceDB4[LanceDB-Only Mode]
    Check -->|Collection Exists| Hybrid[Hybrid Mode]

    LanceDB1 --> FullIndex[Full Workspace Indexing]
    LanceDB2 --> FullIndex
    LanceDB3 --> FullIndex
    LanceDB4 --> FullIndex

    FullIndex --> Ready[System Ready]
    Hybrid --> Ready

    style LanceDB1 fill:#FF9800,stroke:#E65100,color:#fff
    style LanceDB2 fill:#FF9800,stroke:#E65100,color:#fff
    style LanceDB3 fill:#FF9800,stroke:#E65100,color:#fff
    style LanceDB4 fill:#FF9800,stroke:#E65100,color:#fff
    style Hybrid fill:#4CAF50,stroke:#2E7D32,color:#fff
```

**Scenarios:**

1. **Quadrant Collection Not Found**: New project, not yet indexed
2. **Quadrant Server Unavailable**: Network issues, server down
3. **No Git Repository**: Non-git projects
4. **Connection Errors**: Authentication, network problems

### LanceDB-Only Mode Benefits

#### ✅ **Advantages**

- ✅ **Self-Contained**: No external dependencies
- ✅ **Complete Coverage**: All files indexed
- ✅ **Fast Local Search**: Very fast (50-150ms)
- ✅ **Privacy**: All data stored locally
- ✅ **Offline Capable**: Works without network

#### ⚠️ **Limitations**

- ⚠️ **No Team Sharing**: Each developer has separate index
- ⚠️ **Initial Scan Required**: First-time indexing takes time
- ⚠️ **Storage Usage**: Full codebase stored locally
- ⚠️ **No Central Updates**: Each developer maintains own index

### LanceDB-Only Mode Flow Diagram

```mermaid
stateDiagram-v2
    [*] --> CheckQuadrant: Plugin Opens
    CheckQuadrant --> LanceDBMode: Collection Not Found
    CheckQuadrant --> HybridMode: Collection Found

    state LanceDBMode {
        [*] --> Initialize: Initialize LanceDB
        Initialize --> FullScan: Start Full Scan
        FullScan --> Indexing: Index All Files
        Indexing --> FileWatcher: Start Watcher
        FileWatcher --> Ready: System Ready

        Ready --> Monitor: Monitor Changes
        Monitor --> ReIndex: File Changed
        ReIndex --> Monitor: Continue Monitoring
    }

    LanceDBMode --> [*]: System Ready
```

### Complete LanceDB-Only Workflow

```mermaid
journey
    title LanceDB-Only Mode: Complete Workflow
    section Initialization
      Open VS Code: 5: Developer
      Check Quadrant: 3: System
      Not Found: 2: System
      Switch to LanceDB: 5: System
      Full Workspace Scan: 4: System
      Index All Files: 4: System
      Start File Watcher: 5: System
      Ready: 5: Developer
    section Development
      Modify File: 5: Developer
      Save File: 5: Developer
      Auto-Index: 5: System
      Search Works: 5: Developer
    section Ongoing
      All Changes Indexed: 5: System
      Full Context Available: 5: Developer
      No External Dependency: 5: Developer
```

---

## 🎓 Summary

### Architecture Overview Diagram

```mermaid
graph TB
    subgraph "Hybrid Vector Store System"
        direction TB

        subgraph "Input Layer"
            Dev[Developer]
            FS[File System]
        end

        subgraph "Detection Layer"
            FW[File Watcher<br/>Real-Time Monitoring]
            CFT[Changed Files Tracker<br/>Git Status Detection]
        end

        subgraph "Storage Layer"
            QS[Quadrant Store<br/>Read-Only<br/>Team Index]
            LS[Local LanceDB<br/>Writable<br/>Changed Files]
        end

        subgraph "Processing Layer"
            HVS[Hybrid Vector Store<br/>Router & Merger]
        end

        subgraph "Output Layer"
            Search[Search Results<br/>Merged & Deduplicated]
        end

        Dev -->|Saves File| FS
        FS -->|Change Event| FW
        FW -->|Batch Process| HVS
        CFT -->|Changed Files| HVS
        HVS -->|Route Changed| LS
        HVS -->|Skip Unchanged| QS
        HVS -->|Search Both| QS
        HVS -->|Search Both| LS
        QS -->|Results| HVS
        LS -->|Results| HVS
        HVS -->|Merged Results| Search
        Search -->|Final Results| Dev
    end

    style HVS fill:#4CAF50,stroke:#2E7D32,color:#fff
    style QS fill:#2196F3,stroke:#1565C0,color:#fff
    style LS fill:#FF9800,stroke:#E65100,color:#fff
    style CFT fill:#9C27B0,stroke:#6A1B9A,color:#fff
    style FW fill:#F44336,stroke:#C62828,color:#fff
```

### Key Architecture Principles

The Hybrid Vector Store architecture provides a **best-of-both-worlds** solution:

1. **Team Index (Quadrant)**: Centralized, shared, efficient
2. **Local Index (LanceDB)**: Real-time, personal, fast
3. **Smart Routing**: Automatic, git-based, zero-config
4. **Seamless Merging**: Parallel search, intelligent deduplication

**Result**: Developers get immediate context for their changes while benefiting from the team's shared knowledge base.

---

## 📝 Technical Specifications

- **Language**: TypeScript
- **Vector Store**: Qdrant (team) + LanceDB (local)
- **File Detection**: Git status (`git status --porcelain`)
- **Caching**: 5-second TTL for changed files
- **Timeout**: 5s (Qdrant), 2s (Local)
- **Deduplication**: By `filePath + startLine`
- **Priority**: Local results override Quadrant results

---

_Document Version: 1.0_  
_Last Updated: 2024_
