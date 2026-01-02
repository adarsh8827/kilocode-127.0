# Build script for IntelliJ Plugin ZIP
# This script builds the complete IntelliJ plugin with all changes

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Building IntelliJ Plugin ZIP" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$rootDir = $PSScriptRoot

# Step 1: Build VS Code Extension
Write-Host "`n[1/6] Building VS Code Extension..." -ForegroundColor Yellow
Set-Location "$rootDir\src"
pnpm vsix
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build VS Code extension" -ForegroundColor Red
    exit 1
}

# Step 2: Extract VSIX
Write-Host "`n[2/6] Extracting VSIX..." -ForegroundColor Yellow
Set-Location $rootDir
if (Test-Path "bin-unpacked") {
    Remove-Item -Recurse -Force "bin-unpacked"
}
New-Item -ItemType Directory -Path "bin-unpacked" -Force | Out-Null

# VSIX files are ZIP files, so rename and extract
$vsixFile = Get-ChildItem "bin\kilo-code-*.vsix" | Select-Object -First 1
if (-not $vsixFile) {
    Write-Host "ERROR: VSIX file not found in bin directory" -ForegroundColor Red
    exit 1
}

Copy-Item $vsixFile.FullName "$($vsixFile.FullName).zip"
Expand-Archive -Path "$($vsixFile.FullName).zip" -DestinationPath "bin-unpacked" -Force
Remove-Item "$($vsixFile.FullName).zip"
Write-Host "VSIX extracted to bin-unpacked" -ForegroundColor Green

# Step 3: Copy VS Code extension to plugins directory
Write-Host "`n[3/6] Copying VS Code extension to plugins directory..." -ForegroundColor Yellow
$pluginsDir = "jetbrains\plugin\plugins\kilocode"
if (Test-Path $pluginsDir) {
    Remove-Item -Recurse -Force $pluginsDir
}
New-Item -ItemType Directory -Path "$pluginsDir\extension" -Force | Out-Null
Copy-Item -Path "bin-unpacked\extension\*" -Destination "$pluginsDir\extension" -Recurse -Force
Write-Host "VS Code extension copied" -ForegroundColor Green

# Step 4: Build IntelliJ Host (if dependencies are available)
Write-Host "`n[4/6] Building IntelliJ Host..." -ForegroundColor Yellow
Set-Location "$rootDir\jetbrains\host"
try {
    pnpm build 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "IntelliJ Host built successfully" -ForegroundColor Green
    } else {
        Write-Host "WARNING: IntelliJ Host build failed (may need VS Code dependencies)" -ForegroundColor Yellow
        Write-Host "Continuing with plugin build..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: IntelliJ Host build failed (may need VS Code dependencies)" -ForegroundColor Yellow
    Write-Host "Continuing with plugin build..." -ForegroundColor Yellow
}

# Step 5: Generate required files for plugin build
Write-Host "`n[5/7] Generating required plugin files..." -ForegroundColor Yellow
Set-Location "$rootDir\jetbrains\plugin"

# Sync version to generate gradle.properties
if (-not (Test-Path "gradle.properties")) {
    Write-Host "Generating gradle.properties..." -ForegroundColor Cyan
    pnpm sync:version
}

# Generate prodDep.txt if possible (requires host build)
if (-not (Test-Path "prodDep.txt")) {
    Write-Host "Attempting to generate prodDep.txt..." -ForegroundColor Cyan
    try {
        Set-Location "$rootDir\jetbrains\host"
        # Try to install dependencies and generate prodDep
        Set-Location "$rootDir\jetbrains\plugin"
        pnpm propDep 2>&1 | Out-Null
        if (Test-Path "prodDep.txt") {
            Write-Host "prodDep.txt generated successfully" -ForegroundColor Green
        } else {
            Write-Host "WARNING: prodDep.txt generation failed. Creating minimal file..." -ForegroundColor Yellow
            # Create minimal prodDep.txt to allow build to proceed
            @"
@lancedb/lancedb
@lancedb/lancedb-win32-x64-msvc
apache-arrow
reflect-metadata
"@ | Set-Content "prodDep.txt"
            Write-Host "Created minimal prodDep.txt" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "WARNING: Could not generate prodDep.txt. Creating minimal file..." -ForegroundColor Yellow
        @"
@lancedb/lancedb
@lancedb/lancedb-win32-x64-msvc
apache-arrow
reflect-metadata
"@ | Set-Content "prodDep.txt"
    }
}

# Step 6: Build IntelliJ Plugin
Write-Host "`n[6/7] Building IntelliJ Plugin..." -ForegroundColor Yellow
Set-Location "$rootDir\jetbrains\plugin"

# Check Java version
try {
    $javaOutput = java -version 2>&1
    $javaVersion = $javaOutput | Select-String "version" | Select-Object -First 1
    Write-Host "Java version: $javaVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Java check failed, continuing..." -ForegroundColor Yellow
}

# Check if JAVA_HOME is set correctly (needs Java 21)
if ($env:JAVA_HOME) {
    Write-Host "JAVA_HOME is set to: $env:JAVA_HOME" -ForegroundColor Cyan
    $javaHomeVersion = & "$env:JAVA_HOME\bin\java.exe" -version 2>&1 | Select-String "version" | Select-Object -First 1
    Write-Host "JAVA_HOME Java version: $javaHomeVersion" -ForegroundColor Cyan
}

# Build plugin in release mode
Write-Host "Running Gradle buildPlugin with release mode..." -ForegroundColor Cyan
.\gradlew.bat buildPlugin -PdebugMode=release

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build IntelliJ plugin" -ForegroundColor Red
    exit 1
}

# Step 7: Find and report the built ZIP
Write-Host "`n[7/7] Locating built plugin ZIP..." -ForegroundColor Yellow
$pluginZip = Get-ChildItem "build\distributions\*.zip" | Select-Object -First 1
if ($pluginZip) {
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "SUCCESS: IntelliJ Plugin built!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "Plugin ZIP location: $($pluginZip.FullName)" -ForegroundColor Cyan
    Write-Host "File size: $([math]::Round($pluginZip.Length / 1MB, 2)) MB" -ForegroundColor Cyan
    
    # Copy to root for easy access
    $rootZip = "$rootDir\kilo-code-intellij-plugin.zip"
    Copy-Item $pluginZip.FullName $rootZip -Force
    Write-Host "`nAlso copied to: $rootZip" -ForegroundColor Green
} else {
    Write-Host "WARNING: Plugin ZIP not found in build\distributions\" -ForegroundColor Yellow
    Write-Host "Please check the build output for the actual location" -ForegroundColor Yellow
}

Set-Location $rootDir
Write-Host "`nBuild process completed!" -ForegroundColor Green

