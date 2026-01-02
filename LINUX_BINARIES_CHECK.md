# Checking for Linux Binaries in VS Code Extension

## Where to Check for LanceDB Linux Binaries

After installing the extension on Linux, you can verify that the Linux binaries are present by checking the following locations:

### 1. Extension Installation Directory

The extension is typically installed at:
```
~/.vscode/extensions/neuroncode.neuron-code-4.116.1/
```

Or for VS Code OSS:
```
~/.vscode-oss/extensions/neuroncode.neuron-code-4.116.1/
```

### 2. Binary Locations to Check

Check for the following directories:

#### Main LanceDB Package
```bash
~/.vscode/extensions/neuroncode.neuron-code-4.116.1/dist/node_modules/@lancedb/lancedb/
```

#### Linux Platform Binaries (should be present)
```bash
# For x64 GNU Linux (most common)
~/.vscode/extensions/neuroncode.neuron-code-4.116.1/dist/node_modules/@lancedb/lancedb-linux-x64-gnu/

# For ARM64 GNU Linux
~/.vscode/extensions/neuroncode.neuron-code-4.116.1/dist/node_modules/@lancedb/lancedb-linux-arm64-gnu/

# For x64 musl Linux (Alpine)
~/.vscode/extensions/neuroncode.neuron-code-4.116.1/dist/node_modules/@lancedb/lancedb-linux-x64-musl/

# For ARM64 musl Linux (Alpine ARM)
~/.vscode/extensions/neuroncode.neuron-code-4.116.1/dist/node_modules/@lancedb/lancedb-linux-arm64-musl/
```

### 3. Quick Check Commands

Run these commands in your Linux terminal to verify:

```bash
# Check if main LanceDB package exists
ls -la ~/.vscode/extensions/neuroncode.neuron-code-4.116.1/dist/node_modules/@lancedb/lancedb/

# Check for Linux x64 GNU binary (most common)
ls -la ~/.vscode/extensions/neuroncode.neuron-code-4.116.1/dist/node_modules/@lancedb/lancedb-linux-x64-gnu/

# Check all LanceDB packages
ls -la ~/.vscode/extensions/neuroncode.neuron-code-4.116.1/dist/node_modules/@lancedb/

# Check if native binaries exist (look for .node files)
find ~/.vscode/extensions/neuroncode.neuron-code-4.116.1/dist/node_modules/@lancedb -name "*.node" -type f
```

### 4. Expected Structure

The directory structure should look like:
```
dist/
└── node_modules/
    └── @lancedb/
        ├── lancedb/                    # Main package
        ├── lancedb-linux-x64-gnu/      # Linux x64 GNU binary
        ├── lancedb-linux-arm64-gnu/    # Linux ARM64 GNU binary
        ├── lancedb-linux-x64-musl/     # Linux x64 musl binary
        └── lancedb-linux-arm64-musl/   # Linux ARM64 musl binary
```

### 5. If Binaries Are Missing

If the Linux binaries are not present:

1. **Check the build process**: Ensure the extension was built with cross-platform support
2. **Rebuild the extension**: Run `pnpm bundle` from the `src` directory
3. **Check esbuild.mjs**: Verify that the `copyLanceDB` plugin is copying all platform binaries
4. **Check VSIX contents**: Unpack the VSIX and verify binaries are included:
   ```bash
   unzip -l neuron-code-*.vsix | grep lancedb-linux
   ```

### 6. Path Resolution

The extension will work on Linux whether a custom path is provided or not:

- **With extensionPath**: Uses `extensionPath/dist/node_modules/@lancedb/lancedb`
- **Without extensionPath**: Automatically resolves from:
  1. `import.meta.url` (if available in bundle)
  2. `__filename` (if available in CommonJS context)
  3. `process.cwd()` (fallback)

The code now handles all these cases automatically.
