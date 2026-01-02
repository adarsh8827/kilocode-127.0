# ============================================
# Complete Clean Install of Kilocode Extension
# ============================================

Write-Host "🧹 Starting Complete Clean Install..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Close all VS Code instances
Write-Host "Step 1: Closing all VS Code instances..." -ForegroundColor Yellow
Get-Process code -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  - Killing VS Code process: $($_.Id)" -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force
}
Start-Sleep -Seconds 2
Write-Host "  [OK] All VS Code instances closed" -ForegroundColor Green
Write-Host ""

# Step 2: Uninstall old extension
Write-Host "Step 2: Uninstalling old Kilocode extension..." -ForegroundColor Yellow
$result = & code --uninstall-extension kilocode.kilo-code 2>&1
Write-Host "  - $result" -ForegroundColor Gray
Write-Host "  ✅ Extension uninstalled" -ForegroundColor Green
Write-Host ""

# Step 3: Clear extension cache directories
Write-Host "Step 3: Clearing VS Code extension caches..." -ForegroundColor Yellow

$cachePaths = @(
    "$env:USERPROFILE\.vscode\extensions\kilocode.kilo-code-*",
    "$env:USERPROFILE\.vscode\extensions\.obsolete",
    "$env:USERPROFILE\.vscode-insiders\extensions\kilocode.kilo-code-*",
    "$env:APPDATA\Code\Cache\*",
    "$env:APPDATA\Code\CachedData\*",
    "$env:APPDATA\Code\CachedExtensions\*",
    "$env:APPDATA\Code\CachedExtensionVSIXs\*"
)

foreach ($cachePath in $cachePaths) {
    if (Test-Path $cachePath) {
        Write-Host "  - Removing: $cachePath" -ForegroundColor Gray
        Remove-Item -Recurse -Force $cachePath -ErrorAction SilentlyContinue
        Write-Host "    ✓ Removed" -ForegroundColor DarkGreen
    } else {
        Write-Host "  - Skipping (not found): $cachePath" -ForegroundColor DarkGray
    }
}
Write-Host "  Cache cleared" -ForegroundColor Green
Write-Host ""

# Step 4: Verify VSIX exists
Write-Host "Step 4: Verifying VSIX file..." -ForegroundColor Yellow
$vsixPath = "C:\KiloNe\kilocode-4.116.1\bin\kilo-code-4.116.1.vsix"

if (-Not (Test-Path $vsixPath)) {
    Write-Host "  ERROR: VSIX not found at: $vsixPath" -ForegroundColor Red
    Write-Host "  Please run pnpm vsix to build the extension first!" -ForegroundColor Red
    exit 1
}

$vsixSize = (Get-Item $vsixPath).Length / 1MB
Write-Host "  - Found VSIX: $vsixPath" -ForegroundColor Gray
Write-Host "  - Size: $([math]::Round($vsixSize, 2)) MB" -ForegroundColor Gray
Write-Host "  ✅ VSIX verified" -ForegroundColor Green
Write-Host ""

# Step 5: Verify LanceDB is in VSIX
Write-Host "Step 5: Verifying LanceDB in VSIX..." -ForegroundColor Yellow
$tempExtractPath = "$env:TEMP\kilocode-vsix-verify"
if (Test-Path $tempExtractPath) {
    Remove-Item -Recurse -Force $tempExtractPath
}

Write-Host "  - Extracting VSIX to verify contents..." -ForegroundColor Gray
Expand-Archive -Path $vsixPath -DestinationPath $tempExtractPath -Force

$lancedbPath = "$tempExtractPath\extension\dist\node_modules\@lancedb\lancedb"
if (Test-Path $lancedbPath) {
    Write-Host "  LanceDB found in VSIX!" -ForegroundColor Green
    
    # Check for native modules
    $nodeFiles = Get-ChildItem -Path $lancedbPath -Filter "*.node" -Recurse
    Write-Host "  - Found $($nodeFiles.Count) native module(s):" -ForegroundColor Gray
    foreach ($file in $nodeFiles) {
        Write-Host "    • $($file.Name)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  ❌ WARNING: LanceDB NOT found in VSIX at expected location!" -ForegroundColor Red
    Write-Host "  Expected: $lancedbPath" -ForegroundColor Red
}

# Cleanup temp extraction
Remove-Item -Recurse -Force $tempExtractPath
Write-Host ""

# Step 6: Install new VSIX
Write-Host "Step 6: Installing new Kilocode extension..." -ForegroundColor Yellow
Write-Host "  Installing from: $vsixPath" -ForegroundColor Gray
$installResult = & code --install-extension $vsixPath --force 2>&1
Write-Host "  $installResult" -ForegroundColor Gray
Start-Sleep -Seconds 2
Write-Host "  Extension installed" -ForegroundColor Green
Write-Host ""

# Step 7: Verify installation
Write-Host "Step 7: Verifying installation..." -ForegroundColor Yellow
$installedExtensions = & code --list-extensions 2>&1 | Select-String "kilocode"
if ($installedExtensions) {
    Write-Host "  ✅ Extension verified: $installedExtensions" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  WARNING: Extension not found in list!" -ForegroundColor Yellow
}
Write-Host ""

# Final instructions
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ CLEAN INSTALL COMPLETE!" -ForegroundColor Green
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Start VS Code (fresh instance)" -ForegroundColor White
Write-Host "2. Open Developer Console: Ctrl+Shift+I" -ForegroundColor White
Write-Host "3. Go to Console tab" -ForegroundColor White
Write-Host "4. Open your workspace" -ForegroundColor White
Write-Host "5. Configure Kilocode with LanceDB" -ForegroundColor White
Write-Host "6. Look for: [LanceDB] ✅ Successfully loaded LanceDB module" -ForegroundColor White
Write-Host ""
Write-Host "If you still see errors, check console for:" -ForegroundColor Yellow
Write-Host "  • [LanceDB] Error details" -ForegroundColor Gray
Write-Host "  • [LanceDB] Current __dirname" -ForegroundColor Gray
Write-Host "  • [LanceDB] Platform information" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

