# Main Branch Changes Summary
## Changes in main that are NOT in dev branch

### Commits in main (not in dev):
1. `d771ea0ddd` - 116
2. `a6ac9f5d16` - 1.116
3. `5d7262d2ad` - Merge changes

### Statistics:
- **Total files changed**: 3,963 files
- **Files added/modified in main**: Many documentation and configuration files
- **Files removed in dev**: Many test files, documentation files, and some source code files

### Key Categories of Changes:

#### 1. Documentation Files Added in Main:
- `ALL_OPTIMIZATIONS_SUMMARY.md` (3,545 lines)
- `BUILD_INSTRUCTIONS.md` (172 lines)
- `CONNECTION_STATUS_IMPLEMENTATION.md` (2,093 lines)
- `EMBEDDINGS_AND_RAG_TECHNICAL_GUIDE.md` (3,220 lines)
- `EMBEDDINGS_RAG_README.md` (384 lines)
- `ERROR_FIXES_SUMMARY.md` (1,950 lines)
- `EXTENSION_SIZE_OPTIMIZATION_COMPLETE.md` (3,336 lines)
- `EXTENSION_SIZE_REDUCTION.md` (806 lines)
- `FINAL_BUILD_READY.md` (2,291 lines)
- `FINAL_CHANGES_SUMMARY.md` (3,369 lines)
- `FINAL_CONNECTION_STATUS_SUMMARY.md` (2,984 lines)
- `FINAL_OPTIMIZATION_RESULTS.md` (1,939 lines)
- `FINAL_SETUP_GUIDE.md` (243 lines)
- `FINAL_WORKING_BUILD.md` (2,764 lines)
- `LANCEDB_FILE_WATCHER_FIX.md` (241 lines)
- `LANCEDB_FLOW_EXPLANATION.md` (439 lines)
- `LANCEDB_VS_QDRANT_COMPARISON.md` (497 lines)
- `LINUX_BINARIES_CHECK.md` (97 lines)
- `MANUAL_CLEAN_INSTALL.md` (249 lines)
- `CODEBASE_SEARCH_EXPLANATION.md` (99 lines)
- `CLEAN_INSTALL.ps1` (134 lines)

#### 2. Configuration Files:
- `.kilocode/mcp.json` (added in main)
- `.kilocode/rules-translate/` directory files (added in main)
- `.kilocode/rules/rules.md` (moved from AGENTS.md)
- `.kilocode/workflows/add-missing-translations.md` (added in main)
- `.vite-port` (added in main)
- `.vscodeignore` (significant changes - 222 lines modified)
- `.gitignore` (330 lines modified)
- `.gitattributes` (11 lines modified)

#### 3. GitHub Workflows and CI/CD:
- `.github/workflows/index-to-quadrant.yml` (59 lines added in main, removed in dev)
- Multiple workflow files that exist in main but were removed/updated in dev:
  - `build-cli.yml`
  - `changeset-release.yml`
  - `cli-publish.yml`
  - `code-qa.yml`
  - `docusaurus-build.yml`
  - `evals.yml`
  - `marketplace-publish.yml`
  - `storybook-playwright-snapshot.yml`
  - `update-contributors.yml`

#### 4. Documentation in apps/kilocode-docs:
- Many documentation files in `apps/kilocode-docs/docs/` that were updated in main
- Provider documentation files (cerebras, inception, minimax, moonshot, sap-ai-core) that exist in main but were removed in dev
- Advanced usage docs (agent-manager, appbuilder, cloud-agent, code-reviews, deploy, integrations, managed-indexing, sessions, slackbot) that exist in main but were removed in dev
- Contributing specs and images that exist in main but were removed in dev

#### 5. Media Files:
- Multiple image and video files in `apps/kilocode-docs/static/` that were restored in main (were removed/reduced in dev)
- Binary files for auto-approving actions, boomerang tasks, code actions, etc.

#### 6. Source Code Changes:
- Various TypeScript/JavaScript files in the codebase that differ between branches
- Test files that were removed in dev but exist in main

### Files List:
See `changed-files-main-only.txt` for the complete list of 3,963 changed files.

### Notes:
- Main branch appears to have extensive documentation and build-related files
- Dev branch has removed many test files, some documentation, and cleaned up the codebase
- Main branch version: 116
- Dev branch version: 140 (newer)
