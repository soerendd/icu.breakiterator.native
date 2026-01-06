# Quick Start Guide

## 1. Initial Setup (One-time)

This repository is ready to use. The ICU submodule has already been added.

### Verify Submodule

```bash
git submodule status
```

If the ICU submodule isn't initialized:
```bash
git submodule update --init --recursive
```

## 2. Local Development Build

### Windows (Current Platform)

```powershell
# Build for x64 (with automatic dependency verification)
.\build-windows.ps1 -Architecture x64

# Build for x86
.\build-windows.ps1 -Architecture x86

# Output location: build/windows-x64/bin/Release/icu.breakiterator.native.dll
```

The build script automatically verifies that the DLL has no external ICU dependencies - only OS imports.

### Linux (via WSL or Linux machine)

```bash
./build-linux.sh x64
# Output: build/linux-x64/lib/libicu.breakiterator.native.so
```

### macOS (on Mac)

```bash
./build-macos.sh arm64  # For Apple Silicon
./build-macos.sh x64    # For Intel Macs
```

## 3. Testing the Library

Create a test .NET console app:

```bash
mkdir test-app
cd test-app
dotnet new console
```

Add P/Invoke code to test (see README.md for full example).

## 4. Creating NuGet Package

After building for all target platforms:

```powershell
.\pack-nuget.ps1 -Version 1.0.0
```

This creates `icu.breakiterator.native.1.0.0.nupkg`.

## 5. Publishing to NuGet

### Manual Publish

```bash
nuget push icu.breakiterator.native.1.0.0.nupkg -ApiKey YOUR_API_KEY -Source https://api.nuget.org/v3/index.json
```

### Automatic via GitHub Actions

1. Add `NUGET_API_KEY` secret to GitHub repository settings
2. Push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. GitHub Actions will build all platforms and publish automatically

## 6. Next Steps

- **Push to GitHub**: 
  ```bash
  git add .
  git commit -m "Initial commit: ICU break iterator native library"
  git push origin main
  ```

- **Update repository URL**: Edit `icu.breakiterator.native.nuspec` and `README.md` to replace `yourusername` with your actual GitHub username

- **Test CI/CD**: Push a commit and watch GitHub Actions build all platforms

- **Create first release**: When ready, tag `v1.0.0` and push to trigger automatic publishing

## Troubleshooting

### "CMake not found"
Install CMake from https://cmake.org/download/

### "ICU submodule empty"
```bash
git submodule update --init --recursive
```

### "Build fails on Linux"
Install build tools:
```bash
sudo apt-get install build-essential cmake
```

### Need Help?
See full documentation in README.md or open an issue on GitHub.
