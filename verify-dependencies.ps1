param(
    [Parameter(Mandatory=$true)]
    [string]$DllPath
)

$ErrorActionPreference = "Stop"

Write-Host "Verifying dependencies for: $DllPath" -ForegroundColor Cyan

if (-not (Test-Path $DllPath)) {
    Write-Error "File not found: $DllPath"
    exit 1
}

# Use dumpbin to check dependencies (requires Visual Studio tools)
Write-Host "`nChecking DLL dependencies..." -ForegroundColor Yellow

try {
    $dumpbinOutput = & dumpbin /DEPENDENTS $DllPath 2>&1
    
    Write-Host $dumpbinOutput
    
    # Check for unwanted dependencies
    $badDeps = @()
    foreach ($line in $dumpbinOutput) {
        if ($line -match "^\s+(icu\w+\.dll)" -or $line -match "^\s+(libicu\w+\.dll)") {
            $badDeps += $matches[1]
        }
        if ($line -match "^\s+(msvcp\d+\.dll)" -or $line -match "^\s+(vcruntime\d+\.dll)") {
            Write-Warning "Found C++ runtime dependency: $($matches[1])"
        }
    }
    
    if ($badDeps.Count -gt 0) {
        Write-Error "ERROR: Found external ICU dependencies: $($badDeps -join ', ')"
        exit 1
    }
    
    Write-Host ""
    Write-Host "No external ICU dependencies detected!" -ForegroundColor Green
    
} catch {
    Write-Warning "dumpbin not found. Install Visual Studio or run from Developer Command Prompt."
    Write-Host "Checking exports instead..."
    
    # Fallback: check exports
    $exportsOutput = & dumpbin /EXPORTS $DllPath 2>&1
    Write-Host $exportsOutput
}

Write-Host ""
Write-Host "Dependency check completed." -ForegroundColor Green
