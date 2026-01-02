# Dev Branch v140 - New Features, Bug Fixes, and Improvements

## Version 4.140.2 (Latest)

### New Features:
- **GLM-4.7 model support** added to Z.ai provider
- **Model selection support** below prompt for Z.ai
- **MiniMax-M2.1 model** added for MiniMax provider

---

## Version 4.140.1

### New Features:
- **Agent Manager terminal switching** - Existing session terminals are revealed when changing sessions
- **AI contribution tracking** - Users can better understand agentic coding impact

### Bug Fixes:
- **Fixed Agent Manager failing to start on macOS** when launched from Finder/Spotlight
- **Reduced read_file errors** when using Claude models
- **Fixed duplicate tool use** in Anthropic provider
- **Fixed duplicate tool call processing** in Chutes, DeepInfra, LiteLLM and xAI providers
- **Fixed Agent Manager error handling** - Now shows error when CLI is misconfigured with options to run `kilocode auth` or `kilocode config`
- **Fixed image generation handler** not using Kilo Gateway properly
- **Fixed text.startsWith crash** - Resolved "text.startsWith is not a function" error
- **Fixed duplicate tool processing** in OpenAI-compatible provider
- **Fixed Ollama model not found error** and context window display

### Improvements:
- **Updated Gemini CLI models** - Added gemini-3-flash-preview, updated maxThinkingTokens for gemini-3-pro-preview to 32,768
- **Session title generation event** emission added to CLI
- **Chat autocomplete telemetry** added
- **Jetbrains autocomplete telemetry** added
- **Removed redundant buttons** from agent manager session detail header ("New Agent" and "Refresh messages")

---

## Version 4.140.0

### New Features:
- **gemini-3-flash-preview model** added
- **GLM-4.6V model support** for z.ai provider
- **Tool alias support** for model-specific tool customization
- **MCP server and tool name sanitization** for API compatibility
- **Auto-approve timer visibility** improvements in follow-up suggestions
- **WorkspaceTaskVisibility type** for organization cloud settings
- **GPT-5.2 model** added to openai-native provider
- **Error details modal** with on-demand display for improved error visibility
- **New search_replace native tool** for single-replacement operations with improved editing precision
- **Streaming tool stats and token usage throttling** for better real-time feedback
- **Versioned settings support** with minPluginVersion gating for Roo provider
- **Architect mode improvements** - Plans now save to `/plans` directory and gitignore it
- **Screenshot saving** from browser tool
- **DeepSeek V3-2 support** for Baseten provider
- **xhigh reasoning effort support** for gpt-5.1-codex-max
- **Kimi, MiniMax, and Qwen model configurations** for Bedrock
- **Tool preferences** for xAI models
- **Timeout configuration** to OpenAI Compatible Provider Client

### Bug Fixes:
- **Fixed auto-approval timeout** - Now cancels when user starts typing, preventing accidental auto-approvals
- **Fixed OpenRouter metadata** - Extract raw error message for clearer error reporting
- **Fixed tool protocol dropdown** - Now shows for LiteLLM provider
- **Fixed empty Gemini responses** and reasoning loops to prevent infinite retries
- **Fixed missing tool_result blocks** to prevent API errors
- **Fixed orphaned tool_results** filtering when more results than tool_uses
- **Fixed general API endpoints** for Z.ai provider
- **Fixed premature rawChunkTracker clearing** for MCP tools, improving reliability
- **Fixed TODO list display order** in chat view to show items in proper sequence
- **Fixed apply_diff exclusion** from native tools when diffEnabled is false
- **Fixed tool protocol selector** - Always shows for openai-compatible provider
- **Fixed reasoning effort support** - Respects explicit supportsReasoningEffort array values
- **Fixed API error messages** - Display actual error message instead of generic text on retry
- **Fixed removed/invalid API providers** to prevent infinite loop
- **Fixed context-management icons** - Use foreground color
- **Fixed 'ask promise was ignored' error** suppression in handleError
- **Fixed finish_reason processing** to emit tool_call_end events properly
- **Fixed finish_reason processing** in xai.ts provider
- **Fixed tool_result IDs** validation before API requests
- **Fixed API timeout** - Returns undefined instead of 0 for disabled timeout
- **Fixed rate limit errors** - Filtered out 429 errors from API error telemetry

### Improvements:
- **Unified context-management architecture** with improved UX
- **Decoupled tools from system prompt** for cleaner architecture
- **Updated DeepSeek models** to V3.2 with new pricing
- **Added minimal and medium reasoning effort levels** for Gemini models
- **Updated xAI models catalog** with latest model options
- **Default to native tools** when supported on OpenRouter
- **Improved OpenAI error messages** for better debugging
- **Better error logs** for parseToolCall exceptions
- **Improved cloud job error logging** for RCC provider errors
- **API error telemetry** added to OpenRouter provider
- **Performance optimization** - Stop making unnecessary count_tokens requests
- **Consolidated ThinkingBudget components** and fixed disable handling
- **Forbid time estimates** in architect mode for more focused planning

---

## Version 4.139.0

### New Features:
- **Improved command output rendering** in Agent Manager with new CommandExecutionBlock component
  - Displays terminal output with status indicators
  - Collapsible output sections
  - Proper escape sequence handling
- **Branch picker** added to Agent Manager for selecting base branch in worktree mode
- **Improved managed indexer** error handling & backoff

### Bug Fixes:
- **Fixed bottom controls overlap** with create mode button
- **Fixed image generation handler** not using Kilo Gateway properly
- **Fixed duplicate tool processing** in OpenAI-compatible provider
- **Normalized line endings** in search and replace tool

### Improvements:
- **Tooltip added** explaining why speech-to-text may be unavailable
- **Snooze for autocomplete** added in settings
- **Prevent autocomplete** from showing suggestions duplicating previous or next line

---

## Version 4.138.0

### New Features:
- **Interactive agent manager worktree sessions** - Now start without auto-execution, allowing manual "Finish to Branch" click
- **Parent session id** added when creating a session

### Bug Fixes:
- **Fixed Windows issue** where kilo code would spawn many cmd.exe windows
- **Fixed deleted tasks** handling

### Improvements:
- **Share kilocode extension authentication** directly with agent manager
- **Tips added** for when an LLM gets stuck in a loop
- **Removed check for ffmpeg** if the STT experiment is disabled

---

## Version 4.137.0

### New Features:
- **Speech-To-Text experiment** for chat input powered by ffmpeg and OpenAI Whisper API
- **Organization ID and last mode** sent with session data

### Bug Fixes:
- **Fixed AbortSignal memory leak** in CLI (MaxListenersExceededWarning)
- **Fixed API request errors** with MCP functions incompatible with OpenAI strict mode
- **Fixed bottom controls overlap** with create mode button

### Improvements:
- **Added support for xhigh reasoning effort**
- **Split autocomplete suggestion** in current line and next lines in most cases
- **Handle different CLI authentication errors** when using agent manager

---

## Version 4.136.0

### New Features:
- **Multi-version feature to Agent Manager** - Launch 1-4 parallel agents in parallel on git worktrees
- **GPT-5.2 support** added

---

## Major Architectural Changes

### Removed Features (Cleanup):
- Removed deprecated `list_code_definition_names` tool
- Removed `insert-content` tool and related test files
- Removed many obsolete test files and approval test cases
- Cleaned up unused translation files
- Removed old autocomplete experiment files

### Code Quality Improvements:
- Removed singleton pattern from GhostServiceManager
- Better error handling throughout
- Improved telemetry tracking
- Enhanced logging and debugging capabilities

---

## Summary Statistics

### New Features Added: ~30+
### Bug Fixes: ~40+
### Performance Improvements: Multiple
### Code Cleanup: Significant (removed ~1000+ test files and obsolete code)

### Key Focus Areas:
1. **Agent Manager** - Major improvements to terminal handling, error messages, and multi-version support
2. **Tool System** - Better tool processing, error handling, and native tool support
3. **Provider Support** - New models and providers (GLM-4.7, MiniMax-M2.1, GPT-5.2, etc.)
4. **Error Handling** - Improved error messages, telemetry, and debugging
5. **Performance** - Optimizations in token counting, tool processing, and API calls
6. **User Experience** - Better UI feedback, tooltips, and workflow improvements

---

## Migration Notes

When upgrading from v116 to v140:
- Some deprecated tools have been removed (insert-content, list_code_definition_names)
- New native tools available (search_replace)
- Agent Manager has significant improvements
- Better error handling and user feedback
- New models available across multiple providers
