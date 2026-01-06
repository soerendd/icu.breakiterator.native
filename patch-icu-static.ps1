param()

$ErrorActionPreference = "Stop"

Write-Host "Patching ICU project files for static library build..." -ForegroundColor Cyan

$projectFiles = @(
    "icu\icu4c\source\common\common.vcxproj",
    "icu\icu4c\source\i18n\i18n.vcxproj",
    "icu\icu4c\source\stubdata\stubdata.vcxproj"
)

foreach ($project in $projectFiles) {
    if (Test-Path $project) {
        Write-Host "Patching $project..." -ForegroundColor Yellow
        
        $content = Get-Content $project -Raw
        
        # Change DynamicLibrary to StaticLibrary
        $content = $content -replace '<ConfigurationType>DynamicLibrary</ConfigurationType>', '<ConfigurationType>StaticLibrary</ConfigurationType>'
        
        # Change output names to include 's' prefix for static
        $content = $content -replace '<TargetName>icuuc</TargetName>', '<TargetName>sicuuc</TargetName>'
        $content = $content -replace '<TargetName>icuin</TargetName>', '<TargetName>sicuin</TargetName>'
        $content = $content -replace '<TargetName>icudt</TargetName>', '<TargetName>sicudt</TargetName>'
        
        # Add U_STATIC_IMPLEMENTATION define
        $content = $content -replace '(<PreprocessorDefinitions>)', '$1U_STATIC_IMPLEMENTATION;'
        
        # Change runtime library from /MD to /MT (static CRT)
        $content = $content -replace '<RuntimeLibrary>MultiThreadedDLL</RuntimeLibrary>', '<RuntimeLibrary>MultiThreaded</RuntimeLibrary>'
        $content = $content -replace '<RuntimeLibrary>MultiThreadedDebugDLL</RuntimeLibrary>', '<RuntimeLibrary>MultiThreadedDebug</RuntimeLibrary>'
        
        Set-Content -Path $project -Value $content
        
        Write-Host "  Patched successfully" -ForegroundColor Green
    }
}

Write-Host "ICU projects patched for static build" -ForegroundColor Green
