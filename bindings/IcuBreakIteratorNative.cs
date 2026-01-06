using System;
using System.Runtime.InteropServices;

namespace IcuBreakIterator.Native
{
    public static class NativeMethods
    {
        // Library name without extension - .NET adds .dll/.so/.dylib automatically
        private const string LibraryName = "icu.breakiterator.native";
        
        // Optional: Use this to control loading manually
        // static NativeMethods()
        // {
        //     NativeLibrary.SetDllImportResolver(typeof(NativeMethods).Assembly, DllImportResolver);
        // }

        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr icu_breakiterator_create_line(
            [MarshalAs(UnmanagedType.LPUTF8Str)] string locale,
            out int status);

        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        public static extern void icu_breakiterator_set_text(
            IntPtr handle,
            [MarshalAs(UnmanagedType.LPUTF8Str)] string text,
            int textLength,
            out int status);

        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        public static extern int icu_breakiterator_next(IntPtr handle);

        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        public static extern int icu_breakiterator_previous(IntPtr handle);

        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        public static extern int icu_breakiterator_first(IntPtr handle);

        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        public static extern void icu_breakiterator_destroy(IntPtr handle);

        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        public static extern void icu_get_version(
            [MarshalAs(UnmanagedType.LPArray, SizeConst = 4)] byte[] versionArray);
    }

    public sealed class IcuBreakIterator : IDisposable
    {
        private IntPtr _handle;
        private bool _disposed;

        public const int UBRK_DONE = -1;

        public IcuBreakIterator(string locale = "en_US")
        {
            _handle = NativeMethods.icu_breakiterator_create_line(locale, out int status);
            if (status != 0 || _handle == IntPtr.Zero)
            {
                throw new InvalidOperationException($"Failed to create break iterator. Status: {status}");
            }
        }

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

        public int Next()
        {
            if (_disposed)
                throw new ObjectDisposedException(nameof(IcuBreakIterator));

            return NativeMethods.icu_breakiterator_next(_handle);
        }

        public int Previous()
        {
            if (_disposed)
                throw new ObjectDisposedException(nameof(IcuBreakIterator));

            return NativeMethods.icu_breakiterator_previous(_handle);
        }

        public int First()
        {
            if (_disposed)
                throw new ObjectDisposedException(nameof(IcuBreakIterator));

            return NativeMethods.icu_breakiterator_first(_handle);
        }

        public static string GetVersion()
        {
            byte[] version = new byte[4];
            NativeMethods.icu_get_version(version);
            return $"{version[0]}.{version[1]}.{version[2]}.{version[3]}";
        }

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
}
