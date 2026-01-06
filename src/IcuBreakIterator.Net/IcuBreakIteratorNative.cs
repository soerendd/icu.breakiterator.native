using System;
using System.Runtime.InteropServices;

namespace IcuBreakIterator.Native;

/// <summary>
/// Native P/Invoke methods for ICU BreakIterator.
/// </summary>
public static class NativeMethods
{
        // Library name without extension - .NET adds .dll/.so/.dylib automatically
        private const string LibraryName = "icu.breakiterator.native";
        
        // Optional: Use this to control loading manually
        // static NativeMethods()
        // {
        //     NativeLibrary.SetDllImportResolver(typeof(NativeMethods).Assembly, DllImportResolver);
        // }

    /// <summary>
    /// Creates a line break iterator for the specified locale.
    /// </summary>
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr icu_breakiterator_create_line(
            [MarshalAs(UnmanagedType.LPUTF8Str)] string locale,
            out int status);

    /// <summary>
    /// Sets the text to analyze.
    /// </summary>
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void icu_breakiterator_set_text(
            IntPtr handle,
            [MarshalAs(UnmanagedType.LPUTF8Str)] string text,
            int textLength,
            out int status);

    /// <summary>
    /// Returns the next break position.
    /// </summary>
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int icu_breakiterator_next(IntPtr handle);

    /// <summary>
    /// Returns the previous break position.
    /// </summary>
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int icu_breakiterator_previous(IntPtr handle);

    /// <summary>
    /// Returns the first break position.
    /// </summary>
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int icu_breakiterator_first(IntPtr handle);

    /// <summary>
    /// Destroys the break iterator and frees resources.
    /// </summary>
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void icu_breakiterator_destroy(IntPtr handle);

    /// <summary>
    /// Gets the ICU version.
    /// </summary>
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void icu_get_version(
            [MarshalAs(UnmanagedType.LPArray, SizeConst = 4)] byte[] versionArray);
}

/// <summary>
/// Managed wrapper for ICU BreakIterator providing Unicode-aware text segmentation.
/// </summary>
public sealed class IcuBreakIterator : IDisposable
{
        private IntPtr _handle;
        private bool _disposed;

    /// <summary>
    /// Constant indicating no more breaks are available.
    /// </summary>
    public const int UBRK_DONE = -1;

    /// <summary>
    /// Creates a new line break iterator.
    /// </summary>
    /// <param name="locale">Locale identifier (e.g., "en_US").</param>
    public IcuBreakIterator(string locale = "en_US")
        {
            _handle = NativeMethods.icu_breakiterator_create_line(locale, out int status);
            if (status != 0 || _handle == IntPtr.Zero)
            {
                throw new InvalidOperationException($"Failed to create break iterator. Status: {status}");
            }
        }

    /// <summary>
    /// Sets the text to analyze for line breaks.
    /// </summary>
    /// <param name="text">UTF-8 encoded text.</param>
    public void SetText(string text)
        {
            if (_disposed)
                throw new ObjectDisposedException(nameof(IcuBreakIterator));

            NativeMethods.icu_breakiterator_set_text(_handle, text, text.Length, out int status);
            if (status != 0)
            {
                throw new InvalidOperationException($"Failed to set text. Status: {status}");
            }
        }

    /// <summary>
    /// Advances to the next break position.
    /// </summary>
    /// <returns>The next break position or <see cref="UBRK_DONE"/> if no more breaks.</returns>
    public int Next()
        {
            if (_disposed)
                throw new ObjectDisposedException(nameof(IcuBreakIterator));

            return NativeMethods.icu_breakiterator_next(_handle);
        }

    /// <summary>
    /// Moves to the previous break position.
    /// </summary>
    /// <returns>The previous break position or <see cref="UBRK_DONE"/> if at the beginning.</returns>
    public int Previous()
        {
            if (_disposed)
                throw new ObjectDisposedException(nameof(IcuBreakIterator));

            return NativeMethods.icu_breakiterator_previous(_handle);
        }

    /// <summary>
    /// Resets to the first break position.
    /// </summary>
    /// <returns>The first break position.</returns>
    public int First()
        {
            if (_disposed)
                throw new ObjectDisposedException(nameof(IcuBreakIterator));

            return NativeMethods.icu_breakiterator_first(_handle);
        }

    /// <summary>
    /// Gets the ICU library version.
    /// </summary>
    /// <returns>Version string (e.g., "78.1.0.0").</returns>
    public static string GetVersion()
        {
            byte[] version = new byte[4];
            NativeMethods.icu_get_version(version);
            return $"{version[0]}.{version[1]}.{version[2]}.{version[3]}";
        }

    /// <summary>
    /// Releases native resources.
    /// </summary>
    public void Dispose()
        {
            if (!_disposed)
            {
                if (_handle != IntPtr.Zero)
                {
                    NativeMethods.icu_breakiterator_destroy(_handle);
                    _handle = IntPtr.Zero;
                }
                _disposed = true;
            }
        }
    }
