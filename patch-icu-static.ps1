param()

$ErrorActionPreference = "Stop"

Write-Host "Patching ICU project files for static library build..." -ForegroundColor Cyan

$projectFiles = @(
    @{Path="icu\icu4c\source\common\common.vcxproj"; OldName="icuuc"; NewName="sicuuc"},
    @{Path="icu\icu4c\source\i18n\i18n.vcxproj"; OldName="icuin"; NewName="sicuin"},
    @{Path="icu\icu4c\source\stubdata\stubdata.vcxproj"; OldName="icudt"; NewName="sicudt"}
)

foreach ($project in $projectFiles) {
    $projectPath = $project.Path
    
    if (Test-Path $projectPath) {
        Write-Host "Patching $projectPath..." -ForegroundColor Yellow
        
        $content = Get-Content $projectPath -Raw
        $originalContent = $content
        
        # Change DynamicLibrary to StaticLibrary
        $content = $content -replace '<ConfigurationType>DynamicLibrary</ConfigurationType>', '<ConfigurationType>StaticLibrary</ConfigurationType>'
        
        # Change output name - handle both with and without TargetName tags
        $content = $content -replace "<TargetName>$($project.OldName)</TargetName>", "<TargetName>$($project.NewName)</TargetName>"
        
        # If no TargetName exists, add it to each PropertyGroup with a platform condition
        if ($content -notmatch '<TargetName>') {
            Write-Host "  No TargetName found, adding explicit target names..." -ForegroundColor Yellow
            # Add TargetName to the main PropertyGroup
            $content = $content -replace '(<PropertyGroup>(?!.*<TargetName>).*?</PropertyGroup>)', "`$1`n  <PropertyGroup>`n    <TargetName>$($project.NewName)</TargetName>`n  </PropertyGroup>"
        }
        
        # Add U_STATIC_IMPLEMENTATION define to all configurations
        $content = $content -replace '(<PreprocessorDefinitions>(?!.*U_STATIC_IMPLEMENTATION))', '$1U_STATIC_IMPLEMENTATION;'
        
        # Change runtime library from /MD to /MT (static CRT)
        $content = $content -replace '<RuntimeLibrary>MultiThreadedDLL</RuntimeLibrary>', '<RuntimeLibrary>MultiThreaded</RuntimeLibrary>'
        $content = $content -replace '<RuntimeLibrary>MultiThreadedDebugDLL</RuntimeLibrary>', '<RuntimeLibrary>MultiThreadedDebug</RuntimeLibrary>'
        
        # Verify changes were made
        if ($content -eq $originalContent) {
            Write-Host "  WARNING: No changes detected in $projectPath" -ForegroundColor Red
        }
        
        Set-Content -Path $projectPath -Value $content -Encoding UTF8
        
        Write-Host "  Patched successfully (ConfigType: Static, TargetName: $($project.NewName))" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: Project file not found: $projectPath" -ForegroundColor Red
    }
}

Write-Host "ICU projects patched for static build" -ForegroundColor Green
