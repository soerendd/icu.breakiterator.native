param(
    [string]$Architecture = "x64",
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

Write-Host "Building icu.breakiterator.native for Windows $Architecture..." -ForegroundColor Green

# Set CMake generator architecture
$cmakeArch = if ($Architecture -eq "x86") { "Win32" } else { "x64" }

# Create build directory
$buildDir = "build/windows-$Architecture"
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# Configure
Push-Location $buildDir
try {
    Write-Host "Configuring CMake (static linking)..." -ForegroundColor Cyan
    
    cmake ../.. -A $cmakeArch `
        -DCMAKE_BUILD_TYPE=$Configuration
    
    if ($LASTEXITCODE -ne 0) {
        throw "CMake configuration failed"
    }
    
    Write-Host "Building..." -ForegroundColor Cyan
    cmake --build . --config $Configuration --parallel
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "Output: $buildDir/bin/$Configuration/" -ForegroundColor Yellow
    
    # Verify no external dependencies
    $dllPath = "$buildDir/bin/$Configuration/icu.breakiterator.native.dll"
    if (Test-Path $dllPath) {
        Write-Host "`nVerifying dependencies..." -ForegroundColor Cyan
        & "$PSScriptRoot\verify-dependencies.ps1" -DllPath $dllPath
    }
} finally {
    Pop-Location
}
