param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

Write-Host "Building and packing IcuBreakIterator.Net NuGet package..." -ForegroundColor Cyan

# Ensure native library is built
$nativeDll = "build\windows-x64\bin\Release\icu.breakiterator.native.dll"
if (-not (Test-Path $nativeDll)) {
    Write-Host "Native library not found. Building Windows x64..." -ForegroundColor Yellow
    .\build-windows.ps1 -Architecture x64
}

# Build the managed project
Write-Host "Building managed project..." -ForegroundColor Cyan
dotnet build "src\IcuBreakIterator.Net\IcuBreakIterator.Net.csproj" -c $Configuration

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

# Pack the NuGet package
Write-Host "Creating NuGet package..." -ForegroundColor Cyan
dotnet pack "src\IcuBreakIterator.Net\IcuBreakIterator.Net.csproj" -c $Configuration --no-build -o "packages"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Pack failed"
    exit 1
}

Write-Host "NuGet package created successfully!" -ForegroundColor Green
Write-Host "Output: packages\" -ForegroundColor Yellow
Get-ChildItem "packages\*.nupkg" | Select-Object Name, Length, LastWriteTime
