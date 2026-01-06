$ErrorActionPreference = "Stop"

Write-Host "Generating .NET P/Invoke bindings..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path "bindings" | Out-Null

ClangSharpPInvokeGenerator `
    --file include/icu_breakiterator_wrapper.h `
    --namespace IcuBreakIterator.Native `
    --output bindings/IcuBreakIteratorNative.cs `
    --libraryPath icu.breakiterator.native `
    --methodClassName NativeMethods `
    --include-directory include `
    --include-directory build/windows-x64/icu-install/include `
    --exclude U_.* `
    --exclude UBRK_.* `
    --remap UErrorCode=int

if ($LASTEXITCODE -eq 0) {
    Write-Host "Bindings generated successfully!" -ForegroundColor Green
    Write-Host "Output: bindings/IcuBreakIteratorNative.cs" -ForegroundColor Yellow
} else {
    Write-Host "Failed to generate bindings" -ForegroundColor Red
    exit 1
}
