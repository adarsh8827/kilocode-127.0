# Simple Clean Install Script for Kilocode Extension
Write-Host "Starting Clean Install..." -ForegroundColor Cyan
Write-Host ""

# 1. Close VS Code
Write-Host "Step 1: Closing VS Code..." -ForegroundColor Yellow
Get-Process code -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Write-Host "[OK] VS Code closed" -ForegroundColor Green
Write-Host ""

# 2. Uninstall old extension
Write-Host "Step 2: Uninstalling old extension..." -ForegroundColor Yellow
code --uninstall-extension kilocode.kilo-code
Write-Host "[OK] Extension uninstalled" -ForegroundColor Green
Write-Host ""

# 3. Clear caches
Write-Host "Step 3: Clearing caches..." -ForegroundColor Yellow
Remove-Item -Recurse -Force "$env:USERPROFILE\.vscode\extensions\kilocode.kilo-code-*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.vscode\extensions\.obsolete" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:APPDATA\Code\Cache\*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:APPDATA\Code\CachedData\*" -ErrorAction SilentlyContinue
Write-Host "[OK] Caches cleared" -ForegroundColor Green
Write-Host ""

# 4. Install new VSIX
Write-Host "Step 4: Installing new VSIX..." -ForegroundColor Yellow
$vsixPath = "C:\KiloNe\kilocode-4.116.1\bin\kilo-code-4.116.1.vsix"
code --install-extension $vsixPath --force
Start-Sleep -Seconds 2
Write-Host "[OK] Extension installed" -ForegroundColor Green
Write-Host ""

# 5. Verify
Write-Host "Step 5: Verifying installation..." -ForegroundColor Yellow
$installed = code --list-extensions | Select-String "kilocode"
if ($installed) {
    Write-Host "[OK] Extension verified: $installed" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Extension not found in list" -ForegroundColor Yellow
}
Write-Host ""

# Done
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CLEAN INSTALL COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Start VS Code (fresh instance)" -ForegroundColor White
Write-Host "2. Press Ctrl+Shift+I to open Developer Console" -ForegroundColor White
Write-Host "3. Go to Console tab" -ForegroundColor White
Write-Host "4. Open your workspace" -ForegroundColor White
Write-Host "5. Configure Kilocode with LanceDB" -ForegroundColor White
Write-Host "6. Look for: [LanceDB] Successfully loaded LanceDB module" -ForegroundColor White
Write-Host ""
Write-Host "If you see errors, share ALL lines starting with [LanceDB]" -ForegroundColor Yellow
Write-Host ""

