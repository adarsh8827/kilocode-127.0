# Dev Branch Features Integration Plan

## Overview
Integrate ALL features and fixes from dev branch (v140) into current workspace (main-based v116), preserving all `kilocode_change` markers.

## Integration Strategy
- **Preserve**: All `kilocode_change` markers and custom modifications
- **Add**: All new features and fixes from dev branch
- **Merge**: When conflicts occur, merge both changes
- **Verify**: Test each integration step

---

## Phase 1: Critical Bug Fixes (Priority 1)

### 1.1 Prevent Empty Checkpoints (#4725)
**File**: `src/core/assistant-message/presentAssistantMessage.ts`
**Line**: ~1232
**Change**:
```typescript
// Current:
await task.checkpointSave(true)

// Fix:
await task.checkpointSave(false)  // Don't allow empty checkpoints
```
**Preserve**: All `kilocode_change` markers in this file

### 1.2 Skip VSCode Diagnostics in CLI Mode (#4736)
**File**: `cli/src/host/VSCode.ts`
**Action**: Verify `createDiagnosticCollection.set` is a no-op for performance
**Preserve**: Any CLI-specific customizations

### 1.3 Fix Duplicate Tool Use in Anthropic (#4596, #4620)
**Files**: 
- `src/api/providers/anthropic.ts`
**Action**: Add duplicate tool call detection and filtering
**Preserve**: Any custom provider logic

### 1.4 Fix Duplicate Tool Processing in Multiple Providers (#4620)
**Files**:
- `src/api/providers/chutes.ts`
- `src/api/providers/deepinfra.ts`
- `src/api/providers/litellm.ts`
- `src/api/providers/xai.ts`
**Action**: Add duplicate tool call filtering
**Preserve**: Any custom provider logic

### 1.5 Fix read_file Errors with Claude Models (#4526)
**File**: `src/core/tools/ReadFileTool.ts`
**Action**: Improve error handling and parameter parsing
**Preserve**: Any custom read_file logic

### 1.6 Fix text.startsWith Crash (#4519)
**Files**: Multiple files using `text.startsWith`
**Action**: Add type checking before calling `startsWith`
**Preserve**: All existing logic

### 1.7 Fix Image Generation Handler (#4536)
**File**: `src/api/providers/utils/image-generation.ts`
**Action**: Ensure proper Kilo Gateway usage
**Preserve**: Any `kilocode_change` markers (4 found)

---

## Phase 2: Model & Provider Updates (Priority 2)

### 2.1 Gemini Models Updates (#4560)
**Files**:
- `src/api/providers/gemini.ts` (CLI provider)
- `packages/types/src/providers/bedrock.ts` (Vertex models)
**Changes**:
- Add `gemini-3-flash-preview` model
- Update `maxThinkingTokens` for `gemini-3-pro-preview` to 32,768
- Reorder model definitions to prioritize newer versions
**Preserve**: Any custom model configurations

### 2.2 GLM Models (#4530, #4538)
**Files**:
- `src/api/providers/z-ai.ts`
**Changes**:
- Add GLM-4.6V model support
- Add GLM-4.7 model support
- Add model selection support below prompt
**Preserve**: Any custom z.ai provider logic

### 2.3 GPT-5.2 Model (#4509)
**File**: `src/api/providers/openai-native.ts`
**Action**: Add GPT-5.2 model configuration
**Preserve**: Any custom OpenAI provider logic

### 2.4 MiniMax Models (#3295)
**Files**:
- `src/api/providers/minimax.ts`
**Changes**:
- Add MiniMax-M2.1 model
- Verify MiniMax provider implementation
**Preserve**: Any custom MiniMax logic

### 2.5 Other Provider Updates
**Files**: Various provider files
**Actions**:
- Update DeepSeek models to V3.2
- Add Kimi, MiniMax, Qwen for Bedrock
- Add DeepSeek V3-2 for Baseten
- Update xAI models catalog
- Add xhigh reasoning effort support for gpt-5.1-codex-max
**Preserve**: All custom provider logic

---

## Phase 3: Tool System Improvements (Priority 2)

### 3.1 Tool Alias Support (#4509)
**Files**:
- `src/core/task/build-tools.ts` (5 kilocode_change markers found)
- `src/shared/tool-aliases.ts` (1 kilocode_change marker found)
**Action**: Add model-specific tool customization via tool aliases
**Preserve**: All `kilocode_change` markers

### 3.2 New search_replace Tool (#4491)
**Files**:
- `src/core/tools/SearchReplaceTool.ts` (may need to be created)
- `src/core/assistant-message/presentAssistantMessage.ts`
**Action**: Add search_replace native tool for single-replacement operations
**Preserve**: All existing tool handling logic

### 3.3 Normalize Line Endings in Search Replace (#4472)
**File**: `src/core/tools/SearchReplaceTool.ts` or similar
**Action**: Normalize line endings in search and replace operations
**Preserve**: Existing functionality

### 3.4 Fix Tool Protocol Dropdown (#4533, #4531)
**Files**:
- `src/api/providers/litellm.ts`
- `src/api/providers/openai-compatible.ts`
**Action**: Ensure tool protocol dropdown shows for all providers
**Preserve**: Provider-specific logic

### 3.5 Fix Missing tool_result Blocks (#4596)
**Files**: Multiple provider files
**Action**: Add missing tool_result blocks to prevent API errors
**Preserve**: Provider-specific implementations

### 3.6 Fix Orphaned tool_results (#4596)
**Files**: Multiple provider files
**Action**: Filter orphaned tool_results when more results than tool_uses
**Preserve**: Provider-specific logic

---

## Phase 4: Agent Manager Features (Priority 3)

### 4.1 Agent Manager Terminal Switching (#4615)
**Files**:
- `src/core/kilocode/agent-manager/` directory files
**Action**: Add terminal switching so existing session terminals are revealed
**Preserve**: Any custom Agent Manager logic

### 4.2 Agent Manager macOS Fix (#4586)
**Files**: Agent Manager files
**Action**: Fix failing to start on macOS when launched from Finder/Spotlight
**Preserve**: Custom Agent Manager features

### 4.3 Agent Manager Error Handling (#4597)
**Files**: Agent Manager files
**Action**: Show error when CLI is misconfigured with options to run `kilocode auth` or `kilocode config`
**Preserve**: Custom error handling

### 4.4 Remove Redundant Buttons (#4568)
**Files**: Agent Manager UI files
**Action**: Remove "New Agent" and "Refresh messages" buttons from session detail header
**Preserve**: UI customizations

### 4.5 Improved Command Output Rendering (#4481)
**Files**: Agent Manager UI files
**Action**: Add CommandExecutionBlock component with status indicators, collapsible sections
**Preserve**: UI customizations

### 4.6 Branch Picker (#4483)
**Files**: Agent Manager files
**Action**: Add branch picker for selecting base branch in worktree mode
**Preserve**: Worktree functionality

### 4.7 Multi-Version Feature (#4380)
**Files**: Agent Manager files
**Action**: Add multi-version feature - launch 1-4 parallel agents on git worktrees
**Preserve**: Existing Agent Manager features

### 4.8 Interactive Worktree Sessions (#4428)
**Files**: Agent Manager files
**Action**: Start without auto-execution, allow manual "Finish to Branch" click
**Preserve**: Worktree logic

### 4.9 Parent Session ID (#4425)
**Files**: Agent Manager files
**Action**: Add parent session id when creating a session
**Preserve**: Session management logic

### 4.10 Session Versioning (#4317)
**Files**: Agent Manager files
**Action**: Add session versioning
**Preserve**: Session management

---

## Phase 5: Autocomplete Features (Priority 3)

### 5.1 Enable Chat Autocomplete by Default (#4723)
**Files**: Settings/configuration files
**Action**: Change default from `false` to `true`
**Preserve**: Settings structure

### 5.2 Chat Autocomplete Telemetry (#4523, #4582)
**Files**: Autocomplete and telemetry files
**Action**: Add telemetry tracking for chat autocomplete
**Preserve**: Existing telemetry logic

### 5.3 Jetbrains Autocomplete Telemetry (#4488)
**Files**: Jetbrains integration files
**Action**: Add autocomplete telemetry for Jetbrains
**Preserve**: Jetbrains-specific logic

### 5.4 Snooze for Autocomplete (#4424)
**Files**: Settings files
**Action**: Add snooze option in settings
**Preserve**: Settings structure

### 5.5 Prevent Autocomplete Duplicates (#4491)
**Files**: Autocomplete files
**Action**: Prevent suggestions duplicating previous or next line
**Preserve**: Autocomplete logic

### 5.6 Split Autocomplete Suggestion (#4426)
**Files**: Autocomplete files
**Action**: Split suggestion in current line and next lines in most cases
**Preserve**: Autocomplete logic

---

## Phase 6: Speech-to-Text Features (Priority 3)

### 6.1 Speech-To-Text Experiment (#4388)
**Files**:
- `src/services/stt/` directory (multiple files with kilocode_change markers)
- `src/core/webview/sttHandlers.ts` (1 kilocode_change marker)
- `src/shared/sttContract.ts` (1 kilocode_change marker)
**Action**: Add STT experiment for chat input powered by ffmpeg and OpenAI Whisper API
**Preserve**: All `kilocode_change` markers (found in multiple STT files)

### 6.2 STT Tooltip (#4424)
**Files**: UI files
**Action**: Add tooltip explaining why speech-to-text may be unavailable
**Preserve**: UI customizations

### 6.3 Remove ffmpeg Check (#4394)
**Files**: STT files
**Action**: Remove check for ffmpeg if STT experiment is disabled
**Preserve**: STT logic

---

## Phase 7: AI Contribution Tracking (Priority 3)

### 7.1 AI Contribution Tracking (#4561)
**Files**:
- `src/services/contribution-tracking/ContributionTrackingService.ts` (1 kilocode_change marker)
- `src/services/contribution-tracking/contribution-tracking-types.ts` (1 kilocode_change marker)
- `src/core/tools/WriteToFileTool.ts` (kilocode_change markers already present)
- `src/core/tools/MultiApplyDiffTool.ts` (kilocode_change markers already present)
**Action**: Verify contribution tracking is properly integrated
**Preserve**: All `kilocode_change` markers (already present in tools)

---

## Phase 8: CLI Improvements (Priority 3)

### 8.1 Fix Windows cmd.exe Spawn (#4475)
**Files**: CLI files
**Action**: Fix issue where kilo code would spawn many cmd.exe windows on Windows
**Preserve**: CLI customizations

### 8.2 Fix AbortSignal Memory Leak (#4416)
**Files**: CLI files
**Action**: Fix MaxListenersExceededWarning in CLI
**Preserve**: CLI logic

### 8.3 Share Authentication (#4472)
**Files**: CLI and extension files
**Action**: Share kilocode extension authentication directly with agent manager
**Preserve**: Authentication logic

### 8.4 Session Title Generated Event (#4590)
**Files**: CLI files
**Action**: Add session_title_generated event emission to CLI
**Preserve**: CLI event system

### 8.5 Check Token Before Syncing (#4310)
**Files**: CLI files
**Action**: Check token before syncing session
**Preserve**: Session sync logic

---

## Phase 9: Code Indexing Improvements (Priority 4)

### 9.1 Improved Managed Indexer (#4512)
**Files**: Code indexing files
**Action**: Improve error handling & backoff
**Preserve**: Indexing logic

### 9.2 Batch Size and Retries (#3571)
**Files**:
- `src/services/code-index/config-manager.ts`
- `src/services/code-index/service-factory.ts`
**Action**: Verify batch size and number of retries in indexing options
**Preserve**: Indexing configuration (you have `embeddingBatchSize` and `scannerMaxBatchRetries`)

---

## Phase 10: UI/UX Improvements (Priority 4)

### 10.1 Auto-approve Timer Visibility (#4509)
**Files**: UI files
**Action**: Improve auto-approve timer visibility in follow-up suggestions
**Preserve**: UI customizations

### 10.2 Error Details Modal (#4509)
**Files**: UI files
**Action**: Add error details modal with on-demand display
**Preserve**: UI structure

### 10.3 Streaming Tool Stats (#4509)
**Files**: UI files
**Action**: Add streaming tool stats and token usage throttling
**Preserve**: UI customizations

### 10.4 Fix Bottom Controls Overlap (#4415, #4412)
**Files**: UI files
**Action**: Fix bottom controls no longer overlap with create mode button
**Preserve**: UI layout

### 10.5 Fix TODO List Display Order (#4509)
**Files**: UI files
**Action**: Correct TODO list display order in chat view
**Preserve**: UI structure

### 10.6 Context Management Icons (#4509)
**Files**: UI files
**Action**: Use foreground color for context-management icons
**Preserve**: UI styling

---

## Phase 11: Provider-Specific Fixes (Priority 4)

### 11.1 Fix Empty Gemini Responses (#4509)
**Files**: Gemini provider files
**Action**: Handle empty Gemini responses and reasoning loops
**Preserve**: Provider logic

### 11.2 Fix Reasoning Effort Support (#4509)
**Files**: Multiple provider files
**Action**: Respect explicit supportsReasoningEffort array values
**Preserve**: Provider-specific logic

### 11.3 Fix API Error Messages (#4509)
**Files**: Provider files
**Action**: Display actual error message instead of generic text on retry
**Preserve**: Error handling

### 11.4 Fix Rate Limit Errors (#4509)
**Files**: Telemetry files
**Action**: Filter out 429 rate limit errors from API error telemetry
**Preserve**: Telemetry logic

### 11.5 Fix Finish Reason Processing (#4509)
**Files**: Provider files
**Action**: Process finish_reason to emit tool_call_end events properly
**Preserve**: Event system

### 11.6 Fix Tool Result ID Validation (#4509)
**Files**: Provider files
**Action**: Validate and fix tool_result IDs before API requests
**Preserve**: Provider logic

### 11.7 Fix API Timeout (#4509)
**Files**: Provider files
**Action**: Return undefined instead of 0 for disabled timeout
**Preserve**: Timeout logic

### 11.8 Fix Removed/Invalid Providers (#4509)
**Files**: Provider management files
**Action**: Sanitize removed/invalid API providers to prevent infinite loop
**Preserve**: Provider management

---

## Phase 12: Architecture Improvements (Priority 5)

### 12.1 Unified Context Management (#4509)
**Files**: Context management files
**Action**: Unified context-management architecture with improved UX
**Preserve**: Context management logic

### 12.2 Decouple Tools from System Prompt (#4509)
**Files**: Tool system files
**Action**: Decouple tools from system prompt for cleaner architecture
**Preserve**: Tool system

### 12.3 Versioned Settings Support (#4509)
**Files**: Settings files
**Action**: Add versioned settings support with minPluginVersion gating for Roo provider
**Preserve**: Settings structure

### 12.4 Architect Mode Improvements (#4509)
**Files**: Architect mode files
**Action**: Make Architect mode save plans to /plans directory and gitignore it
**Preserve**: Architect mode logic

### 12.5 MCP Server and Tool Name Sanitization (#4509)
**Files**: MCP files
**Action**: Sanitize MCP server and tool names for API compatibility
**Preserve**: MCP logic

---

## Implementation Order

1. **Phase 1** (Critical Bug Fixes) - Do first
2. **Phase 2** (Model Updates) - High priority
3. **Phase 3** (Tool System) - High priority
4. **Phase 4** (Agent Manager) - Medium priority
5. **Phase 5** (Autocomplete) - Medium priority
6. **Phase 6** (STT) - Medium priority
7. **Phase 7** (Contribution Tracking) - Verify existing
8. **Phase 8** (CLI) - Medium priority
9. **Phase 9** (Code Indexing) - Lower priority
10. **Phase 10** (UI/UX) - Lower priority
11. **Phase 11** (Provider Fixes) - Lower priority
12. **Phase 12** (Architecture) - Lower priority

---

## Files with kilocode_change Markers to Preserve

Found 65 matches across 25 files. Key files:
- `src/core/assistant-message/presentAssistantMessage.ts` (21 markers)
- `src/core/tools/MultiApplyDiffTool.ts` (multiple markers)
- `src/core/tools/WriteToFileTool.ts` (markers)
- `src/core/task/build-tools.ts` (5 markers)
- `src/services/stt/` directory (multiple files)
- `src/services/contribution-tracking/` files
- `src/api/providers/utils/image-generation.ts` (4 markers)
- And more...

**CRITICAL**: Always preserve these markers when integrating changes.

---

## Testing Strategy

After each phase:
1. Test affected functionality
2. Verify no regressions
3. Check that `kilocode_change` markers are preserved
4. Run relevant tests if available
5. Check for compilation errors

---

## Notes

- This is a comprehensive integration of ~100+ features/fixes
- Most features are additive (won't conflict with existing code)
- Focus on preserving `kilocode_change` markers
- When in doubt, merge both changes
- Test incrementally after each phase
