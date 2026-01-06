# icu.breakiterator.native

A minimal cross-platform native library providing ICU break iterator functionality for text segmentation and line breaking in .NET applications.

## Features

- **Self-Contained**: All ICU components statically linked - no external dependencies except OS APIs
- **Minimal ICU Build**: Only includes break iterator components (~5-8MB vs ~30MB full ICU)
- **Cross-Platform**: Supports Windows (x64/x86), Linux (x64/ARM64), macOS (x64/ARM64)
- **NuGet Distribution**: Native libraries automatically copied to output directory
- **Simple C API**: Easy-to-use wrapper around ICU's break iterator
- **No Runtime Dependencies**: Static linking of C/C++ runtimes (Windows) and libstdc++/libgcc (Linux)

## Supported Platforms

| Platform | Architecture | Runtime Identifier |
|----------|--------------|-------------------|
| Windows  | x64          | win-x64           |
| Windows  | x86          | win-x86           |
| Linux    | x64          | linux-x64         |
| Linux    | ARM64        | linux-arm64       |
| macOS    | x64          | osx-x64           |
| macOS    | ARM64        | osx-arm64         |

## Installation

Add the NuGet package to your .NET project:

```bash
dotnet add package icu.breakiterator.native
```

Or via Package Manager Console:

```powershell
Install-Package icu.breakiterator.native
```

The native libraries will be automatically copied to your output directory based on your runtime identifier.

## Usage from .NET

### Basic Example

```csharp
using System;
using System.Runtime.InteropServices;

[DllImport("icu.breakiterator.native", CallingConvention = CallingConvention.Cdecl)]
private static extern IntPtr icu_breakiterator_create_line(string locale, out int status);

[DllImport("icu.breakiterator.native", CallingConvention = CallingConvention.Cdecl)]
private static extern void icu_breakiterator_set_text(IntPtr handle, [MarshalAs(UnmanagedType.LPWStr)] string text, int length, out int status);

[DllImport("icu.breakiterator.native", CallingConvention = CallingConvention.Cdecl)]
private static extern int icu_breakiterator_next(IntPtr handle);

[DllImport("icu.breakiterator.native", CallingConvention = CallingConvention.Cdecl)]
private static extern void icu_breakiterator_destroy(IntPtr handle);

// Usage
var handle = icu_breakiterator_create_line("en-US", out var status);
try {
    string text = "Hello world. This is a test.";
    icu_breakiterator_set_text(handle, text, text.Length, out status);
    
    int pos;
    while ((pos = icu_breakiterator_next(handle)) != -1) {
        Console.WriteLine($"Break at position: {pos}");
    }
} finally {
    icu_breakiterator_destroy(handle);
}
```

## Building from Source

### Prerequisites

- **CMake** 3.20 or higher
- **C/C++ Compiler**:
  - Windows: Visual Studio 2019+ with C++ tools
  - Linux: GCC 7+ or Clang 5+
  - macOS: Xcode Command Line Tools

### Clone Repository

```bash
git clone --recurse-submodules https://github.com/yourusername/icu.breakiterator.native.git
cd icu.breakiterator.native
```

### Build Instructions

#### Windows

```powershell
# Build for x64
.\build-windows.ps1 -Architecture x64

# Build for x86
.\build-windows.ps1 -Architecture x86
```

#### Linux

```bash
# Build for x64
chmod +x build-linux.sh
./build-linux.sh x64

# Build for ARM64 (requires cross-compilation tools)
sudo apt-get install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
./build-linux.sh arm64
```

#### macOS

```bash
# Build for x64 (Intel)
chmod +x build-macos.sh
./build-macos.sh x64

# Build for ARM64 (Apple Silicon)
./build-macos.sh arm64
```

### Verify Dependencies

After building, the scripts automatically verify no external dependencies:

```powershell
# Windows
.\verify-dependencies.ps1 -DllPath "build/windows-x64/bin/Release/icu.breakiterator.native.dll"

# Linux/macOS
./verify-dependencies.sh "build/linux-x64/lib/libicu.breakiterator.native.so"
```

The library should only depend on:
- **Windows**: kernel32.dll, user32.dll (OS APIs only)
- **Linux**: libc.so, libm.so, libpthread.so, libdl.so (OS APIs only)
- **macOS**: System frameworks only

### Create NuGet Package

After building for all platforms:

```powershell
.\pack-nuget.ps1 -Version 1.0.0
```

## C API Reference

### Functions

#### `icu_breakiterator_create_line`
Creates a line break iterator for a specific locale.

```c
BreakIteratorHandle* icu_breakiterator_create_line(const char* locale, UErrorCode* status);
```

**Parameters:**
- `locale`: Locale identifier (e.g., "en-US", "ja-JP")
- `status`: Output parameter for error code

**Returns:** Handle to the break iterator or NULL on error

#### `icu_breakiterator_set_text`
Sets the text to be segmented.

```c
void icu_breakiterator_set_text(BreakIteratorHandle* handle, const UChar* text, int32_t length, UErrorCode* status);
```

**Parameters:**
- `handle`: Break iterator handle
- `text`: UTF-16 text buffer
- `length`: Number of UChar units
- `status`: Output parameter for error code

#### `icu_breakiterator_next`
Advances to the next break position.

```c
int32_t icu_breakiterator_next(BreakIteratorHandle* handle);
```

**Returns:** Position of next break, or `UBRK_DONE` (-1) if no more breaks

#### `icu_breakiterator_previous`
Moves to the previous break position.

```c
int32_t icu_breakiterator_previous(BreakIteratorHandle* handle);
```

#### `icu_breakiterator_first`
Resets to the first break position.

```c
void icu_breakiterator_first(BreakIteratorHandle* handle);
```

#### `icu_breakiterator_destroy`
Releases all resources associated with the break iterator.

```c
void icu_breakiterator_destroy(BreakIteratorHandle* handle);
```

#### `icu_get_version`
Returns the ICU version string.

```c
const char* icu_get_version(void);
```

## CI/CD

The project uses GitHub Actions to automatically build for all platforms on push and pull requests. When you create a git tag with version format `v1.0.0`, it will:

1. Build for all 6 platforms
2. Create NuGet package
3. Publish to NuGet.org
4. Create GitHub release with artifacts

### Setup GitHub Secrets

Add the following secret to your GitHub repository:
- `NUGET_API_KEY`: Your NuGet.org API key

### Creating a Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Project Structure

```
icu.breakiterator.native/
├── .github/workflows/     # GitHub Actions CI/CD
├── cmake/                 # CMake toolchain files
├── icu/                   # ICU submodule
├── src/                   # Source code
│   └── breakiterator_wrapper.c
├── build-windows.ps1      # Windows build script
├── build-linux.sh         # Linux build script
├── build-macos.sh         # macOS build script
├── pack-nuget.ps1         # NuGet packaging script
├── CMakeLists.txt         # CMake configuration
├── icu.breakiterator.native.nuspec
└── README.md
```

## License

This project contains ICU as a submodule. ICU is released under the Unicode License. See the [ICU LICENSE](icu/LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Architecture

The library uses a **self-contained static linking** approach:

1. **ICU is built as static libraries** (`.lib`/`.a` files)
2. **All ICU code is linked into the shared library** (`icu.breakiterator.native.dll`/`.so`/`.dylib`)
3. **Symbol visibility is controlled** to hide ICU internals and only export wrapper functions
4. **C/C++ runtimes are statically linked** (where possible) to eliminate runtime dependencies

This ensures the library has **zero external dependencies** except OS APIs.

### Build Configuration

- **Windows**: `/MT` flag for static MSVC runtime, `.def` file to control exports
- **Linux**: `-static-libgcc -static-libstdc++`, `-Wl,--exclude-libs,ALL` to hide ICU symbols
- **macOS**: Exported symbols list to control visibility, `-dead_strip` for smaller binary

## Troubleshooting

### Build fails with "ICU not found"
Ensure you've cloned with `--recurse-submodules` or run:
```bash
git submodule update --init --recursive
```

### External ICU dependencies detected
This means static linking failed. Check:
- CMake output for linking errors
- Run verification script manually
- Ensure `BUILD_SHARED_LIBS=OFF` is set

### Native library not found at runtime
Ensure the NuGet package is properly restored and the runtime identifier matches your platform.

### Cross-compilation issues on Linux
Install the appropriate cross-compilation toolchain:
```bash
# For ARM64
sudo apt-get install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
```
