# Architecture: Self-Contained Static Linking

## Design Goal

Create a **single native library** with **zero external dependencies** except OS APIs.

## Challenge

ICU is a large library (~30MB) with multiple components:
- `libicuuc` - Common/Utility
- `libicui18n` - Internationalization (contains BreakIterator)
- `libicudata` - Unicode data tables

By default, these are distributed as **separate shared libraries** that must be deployed together.

## Solution: Static Embedding

We statically link all ICU components into a single shared library.

### Build Strategy

```
┌─────────────────────────────────────────────────────┐
│  icu.breakiterator.native.dll/.so/.dylib            │
│  (Shared Library - Our Public API)                  │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │  breakiterator_wrapper.c (Our C API)       │    │
│  │  ┌──────────────────────────────────────┐  │    │
│  │  │  libicui18n.a (Static Library)       │  │    │
│  │  │  ┌────────────────────────────────┐  │  │    │
│  │  │  │  libicuuc.a (Static Library)   │  │  │    │
│  │  │  │  ┌──────────────────────────┐  │  │  │    │
│  │  │  │  │  libicudata.a (Static)   │  │  │  │    │
│  │  │  │  └──────────────────────────┘  │  │  │    │
│  │  │  └────────────────────────────────┘  │  │    │
│  │  └──────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
        ↓ Only OS APIs
   [Windows: kernel32.dll, etc.]
   [Linux: libc.so, libm.so, etc.]
   [macOS: System frameworks]
```

### CMake Configuration

```cmake
# Build ICU as static libraries
set(BUILD_SHARED_LIBS OFF)
set(ICU_BUILD_TOOLS OFF)
set(ICU_BUILD_TESTS OFF)

# Our library is shared, but links ICU statically
add_library(icu.breakiterator.native SHARED
    src/breakiterator_wrapper.c
)

# Static linking
target_link_libraries(icu.breakiterator.native PRIVATE
    icuuc    # Static .lib/.a
    icui18n  # Static .lib/.a
    icudata  # Static .lib/.a
)
```

## Symbol Visibility Control

### Problem

If ICU symbols are visible, they can:
1. Conflict with other ICU versions loaded in the same process
2. Expose internal implementation details
3. Increase library size

### Solution: Hide All ICU Symbols

#### Windows (`.def` file)
```def
LIBRARY icu.breakiterator.native
EXPORTS
    icu_breakiterator_create_line
    icu_breakiterator_set_text
    ; ... only our functions
```

#### Linux (linker flags)
```cmake
-Wl,--exclude-libs,ALL      # Hide all symbols from static libraries
-fvisibility=hidden         # Default hidden visibility
```

#### macOS (exported symbols list)
```
_icu_breakiterator_create_line
_icu_breakiterator_set_text
; ... only our functions
```

## Static Runtime Linking

### Windows

Use `/MT` (MultiThreaded static runtime) instead of `/MD` (dynamic runtime):

```cmake
set_property(TARGET icu.breakiterator.native 
    PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
```

This eliminates dependencies on `msvcp140.dll`, `vcruntime140.dll`, etc.

### Linux

Statically link libgcc and libstdc++:

```cmake
target_link_options(icu.breakiterator.native PRIVATE
    -static-libgcc
    -static-libstdc++
)
```

This eliminates dependencies on `libstdc++.so.6`, `libgcc_s.so.1`, etc.

### macOS

macOS libc++ is system-provided and always available, so dynamic linking is acceptable.

## Verification

### Automated Checks

Build scripts automatically verify dependencies:

**Windows (dumpbin):**
```powershell
dumpbin /DEPENDENTS icu.breakiterator.native.dll
```

Expected output:
- kernel32.dll
- user32.dll
- (System DLLs only)

**Linux (ldd):**
```bash
ldd libicu.breakiterator.native.so
```

Expected output:
- linux-vdso.so.1
- libc.so.6
- libm.so.6
- libpthread.so.0
- libdl.so.2
- (System libraries only)

**macOS (otool):**
```bash
otool -L libicu.breakiterator.native.dylib
```

Expected output:
- /usr/lib/libSystem.B.dylib
- (System frameworks only)

## Size Comparison

| Configuration | Size | Dependencies |
|--------------|------|--------------|
| **ICU Shared (Default)** | libicuuc.so (2MB) + libicui18n.so (3MB) + libicudata.so (28MB) = **33MB** | 3 files |
| **Our Static Build** | libicu.breakiterator.native.so = **~8MB** | 1 file, OS only |

The size reduction comes from:
1. **Data filtering**: Only line-breaking data included
2. **Dead code elimination**: Linker removes unused ICU code
3. **Single binary**: No duplication across shared libraries

## Benefits

✅ **Zero Deployment Complexity**: Single file, no version conflicts  
✅ **No ICU Version Conflicts**: All symbols hidden, won't clash with other ICU instances  
✅ **Smaller Size**: Only break iterator code + minimal data  
✅ **Better Performance**: No dynamic linking overhead  
✅ **Portable**: No external dependencies to manage  

## Trade-offs

⚠️ **Larger Single Binary**: ~8MB vs ~2MB if using shared ICU (but saves 31MB of other components)  
⚠️ **Build Complexity**: Requires careful CMake configuration  
⚠️ **Update Strategy**: Must rebuild to update ICU version (acceptable for most use cases)  

## Implementation Details

### Build Process

1. **Configure ICU**: `BUILD_SHARED_LIBS=OFF` forces static libraries
2. **Compile ICU**: Creates `.lib`/`.a` files (icuuc, icui18n, icudata)
3. **Link Our Wrapper**: Statically embeds ICU code into our shared library
4. **Control Symbols**: Export only our C API functions
5. **Verify**: Check no external ICU dependencies

### Testing

```bash
# Run verification script
./verify-dependencies.sh build/linux-x64/lib/libicu.breakiterator.native.so

# Check exported symbols
nm -D libicu.breakiterator.native.so | grep " T "
# Should only show icu_breakiterator_* functions
```

### Continuous Integration

GitHub Actions builds all 6 platforms and verifies dependencies automatically.

## References

- [CMake RPATH handling](https://gitlab.kitware.com/cmake/community/-/wikis/doc/cmake/RPATH-handling)
- [GCC visibility documentation](https://gcc.gnu.org/wiki/Visibility)
- [ICU build configuration](https://unicode-org.github.io/icu/userguide/icu4c/build.html)
