# .NET Bindings for icu.breakiterator.native

## Files

- **IcuBreakIteratorNative.cs** - P/Invoke definitions and managed wrapper class
- **Example.cs** - Usage example

## Usage

### Basic Example

```csharp
using IcuBreakIterator.Native;

// Create break iterator for line breaking
using var bi = new IcuBreakIterator("en_US");

string text = "Hello world. This is a test.";
bi.SetText(text);

// Iterate through break positions
int position = bi.First();
while ((position = bi.Next()) != IcuBreakIterator.UBRK_DONE)
{
    Console.WriteLine($"Break at position: {position}");
}
```

### Get ICU Version

```csharp
string version = IcuBreakIterator.GetVersion();
Console.WriteLine($"ICU Version: {version}");  // e.g., "78.1.0.0"
```

## API Reference

### IcuBreakIterator Class

**Constructor:**
- `IcuBreakIterator(string locale = "en_US")` - Creates a line break iterator

**Methods:**
- `void SetText(string text)` - Sets the text to analyze
- `int Next()` - Returns next break position or `UBRK_DONE` (-1)
- `int Previous()` - Returns previous break position or `UBRK_DONE` (-1)
- `int First()` - Returns first break position
- `static string GetVersion()` - Returns ICU version string

**Constants:**
- `UBRK_DONE = -1` - Indicates no more breaks

## Native Library Loading

### Option 1: Automatic Loading (Recommended for NuGet)

**.NET automatically loads platform-specific natives** when packaged correctly:

**NuGet Package Structure:**
```
runtimes/
  win-x64/native/icu.breakiterator.native.dll
  win-x86/native/icu.breakiterator.native.dll
  linux-x64/native/libicu.breakiterator.native.so
  linux-arm64/native/libicu.breakiterator.native.so
  osx-x64/native/libicu.breakiterator.native.dylib
  osx-arm64/native/libicu.breakiterator.native.dylib
```

The library will be automatically copied to the output directory and loaded by .NET's runtime.

**No code needed** - just use the API:
```csharp
using var bi = new IcuBreakIterator("en_US"); // .NET finds the DLL automatically
```

### Option 2: Manual Loading

If automatic loading doesn't work (e.g., non-standard deployment), use `ManualLoader`:

```csharp
// Option A: Load from default locations
ManualLoader.LoadLibrary();

// Option B: Load from explicit path
ManualLoader.LoadLibrary(@"C:\path\to\icu.breakiterator.native.dll");

// Option C: Set up resolver (call once at app startup)
ManualLoader.SetupDllImportResolver();

// Now use the API
using var bi = new IcuBreakIterator("en_US");
```

### When to Use Manual Loading

- **Self-contained/single-file apps** - May need explicit path
- **Custom deployment** - Library in non-standard location
- **Unit tests** - Control library location
- **Debugging** - Verify which DLL is loaded
