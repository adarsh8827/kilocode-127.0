# Missing Fixes Integration Plan

## Analysis Summary

Based on `DEV_V140_FEATURES_AND_FIXES.md`, **most fixes are already implemented in v140**. This plan identifies only the fixes that need verification or are missing.

## Already Implemented in v140 (Per DEV_V140_FEATURES_AND_FIXES.md)

✅ Duplicate tool fixes (Anthropic, Chutes, DeepInfra, LiteLLM, xAI, OpenAI-compatible)  
✅ read_file error fixes for Claude models  
✅ text.startsWith crash fix  
✅ Image generation handler fix  
✅ Agent Manager terminal switching  
✅ Agent Manager macOS launch fix  
✅ Agent Manager error handling  
✅ Chat autocomplete telemetry  
✅ Jetbrains autocomplete telemetry  
✅ Removed redundant Agent Manager buttons  
✅ gemini-3-flash-preview model  
✅ GLM-4.6V and GLM-4.7 models  
✅ GPT-5.2 model  
✅ Tool protocol dropdown fixes  
✅ Empty Gemini responses fix  
✅ Missing tool_result blocks fix  
✅ Orphaned tool_results fix  
✅ Reasoning effort support fixes  
✅ API error message fixes  
✅ Rate limit error filtering  
✅ Finish reason processing fixes  
✅ Tool result ID validation  
✅ Line endings normalization in search replace  
✅ Apply diff exclusion fix  
✅ Windows cmd.exe spawn fix  
✅ AbortSignal memory leak fix  
✅ Share authentication with agent manager  
✅ Parent session ID  
✅ Organization ID and last mode  
✅ Speech-to-Text experiment  
✅ STT tooltip  
✅ Remove ffmpeg check if STT disabled  
✅ Managed indexer error handling  
✅ And many more...

## Fixes That Need Verification/Application

### 1. Prevent Empty Checkpoints (#4725) - NEEDS FIX

**File**: `src/core/assistant-message/presentAssistantMessage.ts`  
**Line**: 1232  
**Current Code**:
```typescript
async function checkpointSaveAndMark(task: Task) {
	if (task.currentStreamingDidCheckpoint) {
		return
	}
	try {
		task.currentStreamingDidCheckpoint = true
		await task.checkpointSave(true)  // ← This creates empty checkpoints
	} catch (error) {
		console.error(`[Task#presentAssistantMessage] Error saving checkpoint: ${error.message}`, error)
	}
}
```

**Fix Required**:
```typescript
async function checkpointSaveAndMark(task: Task) {
	if (task.currentStreamingDidCheckpoint) {
		return
	}
	try {
		task.currentStreamingDidCheckpoint = true
		await task.checkpointSave(false)  // ← Don't allow empty checkpoints
	} catch (error) {
		console.error(`[Task#presentAssistantMessage] Error saving checkpoint: ${error.message}`, error)
	}
}
```

**Rationale**: The `saveCheckpoint` method already supports `allowEmpty: false` (verified in tests). When `force = false`, it passes `allowEmpty: false` to `saveCheckpoint`, which prevents empty checkpoint creation. Currently passing `true` creates empty checkpoints on every tool use.

### 2. Skip VSCode Diagnostics in CLI Mode (#4736) - NEEDS VERIFICATION

**File**: `cli/src/host/VSCode.ts`  
**Current State**: `getDiagnostics` returns empty arrays (lines 1999-2006)  
**Action Needed**: 
1. Verify all diagnostic operations are no-ops in CLI mode
2. Check `createDiagnosticCollection.set` and other diagnostic methods
3. Ensure no diagnostic operations are actually executed

**Current Implementation**:
```typescript
getDiagnostics: (uri?: Uri): [Uri, Diagnostic[]][] | Diagnostic[] => {
	// In CLI mode, we don't have real diagnostics
	// Return empty array or empty diagnostics for the specific URI
	if (uri) {
		return []
	}
	return []
},
createDiagnosticCollection: (name?: string): DiagnosticCollection => {
	const diagnostics = new Map<string, Diagnostic[]>()
	const collection: DiagnosticCollection = {
		// ... implementation
		set: (uriOrEntries, diagnosticsOrUndefined?) => {
			// This might need to be a no-op for performance
		}
	}
}
```

**Fix**: Ensure `set` method in `createDiagnosticCollection` is a no-op (does nothing) for better performance.

### 3. Enable Chat Autocomplete by Default (#4723) - NEEDS VERIFICATION

**Files to Check**:
- Settings configuration files
- Autocomplete initialization code

**Action**: 
1. Find where chat autocomplete default is configured
2. Verify current default value
3. Change to `true` if currently `false`

### 4. Session Title Generated Event (#4590) - NEEDS VERIFICATION

**File**: CLI session management  
**Action**: Verify `session_title_generated` event is emitted in CLI

### 5. Batch Size and Retries Configuration (#3571) - NEEDS VERIFICATION

**Files**: 
- `src/services/code-index/config-manager.ts`
- `src/services/code-index/service-factory.ts`

**Current State**: You have `embeddingBatchSize` and `scannerMaxBatchRetries` in config  
**Action**: Verify implementation matches latest and is properly used

## Implementation Steps

### Step 1: Fix Empty Checkpoints
1. Open `src/core/assistant-message/presentAssistantMessage.ts`
2. Find `checkpointSaveAndMark` function (line 1225)
3. Change line 1232: `await task.checkpointSave(true)` → `await task.checkpointSave(false)`
4. Test: Verify empty checkpoints are not created

### Step 2: Verify CLI Diagnostics Skip
1. Open `cli/src/host/VSCode.ts`
2. Check `createDiagnosticCollection` implementation
3. Ensure `set` method is a no-op (does nothing)
4. Verify no diagnostic operations execute in CLI mode

### Step 3: Verify Chat Autocomplete Default
1. Search for autocomplete default configuration
2. Verify current value
3. Update to `true` if needed

### Step 4: Verify Other Features
1. Compare model definitions with latest
2. Verify provider implementations
3. Check for any newer fixes not in v140

## Files to Modify

### Critical (Must Fix)
1. `src/core/assistant-message/presentAssistantMessage.ts` - Empty checkpoint fix

### Verification Needed
2. `cli/src/host/VSCode.ts` - Diagnostics skip
3. Settings files - Chat autocomplete default
4. CLI files - Session title event
5. Code indexing config - Batch size verification

## Testing Checklist

After applying fixes:
- [ ] Test checkpoint creation - should NOT create empty checkpoints
- [ ] Test CLI mode - verify diagnostics are skipped (performance check)
- [ ] Test chat autocomplete - verify enabled by default
- [ ] Verify no regressions in existing v140 features
- [ ] Test all existing functionality still works

## Notes

- Most fixes (90%+) are already in v140
- This is primarily a gap-filling exercise
- Focus on the 3-5 missing fixes identified above
- Preserve all `kilocode_change` markers
- Your v140 branch is newer than main, so you likely have most fixes already
