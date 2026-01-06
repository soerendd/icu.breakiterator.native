param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

Write-Host "Creating NuGet package version $Version..." -ForegroundColor Green

# Update version in nuspec
$nuspecPath = "icu.breakiterator.native.nuspec"
$nuspecContent = Get-Content $nuspecPath -Raw
$nuspecContent = $nuspecContent -replace '<version>.*?</version>', "<version>$Version</version>"
Set-Content -Path $nuspecPath -Value $nuspecContent

# Create NuGet package
Write-Host "Packing..." -ForegroundColor Cyan
nuget pack $nuspecPath

if ($LASTEXITCODE -ne 0) {
    throw "NuGet pack failed"
}

Write-Host "Package created: icu.breakiterator.native.$Version.nupkg" -ForegroundColor Green
