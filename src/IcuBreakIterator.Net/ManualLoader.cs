using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;

namespace IcuBreakIterator.Native;
    /// <summary>
    /// Manual native library loader for scenarios where automatic loading doesn't work.
    /// </summary>
    public static class ManualLoader
    {
        private static IntPtr _libraryHandle;

        /// <summary>
        /// Manually loads the native library from a specific path or uses platform-specific search.
        /// Call this BEFORE using any P/Invoke methods.
        /// </summary>
        /// <param name="explicitPath">Optional explicit path to the DLL. If null, uses platform conventions.</param>
        public static void LoadLibrary(string? explicitPath = null)
        {
            if (_libraryHandle != IntPtr.Zero)
                return; // Already loaded

            string libraryPath = explicitPath ?? GetDefaultLibraryPath();

            if (!File.Exists(libraryPath))
            {
                throw new FileNotFoundException(
                    $"Native library not found at: {libraryPath}", libraryPath);
            }

            _libraryHandle = NativeLibrary.Load(libraryPath);
            
            if (_libraryHandle == IntPtr.Zero)
            {
                throw new InvalidOperationException(
                    $"Failed to load native library from: {libraryPath}");
            }
        }

        private static string GetDefaultLibraryPath()
        {
            // Get directory where the managed assembly is located
            string? assemblyDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            if (assemblyDir == null)
                throw new InvalidOperationException("Cannot determine assembly location");
            
            string libraryName;
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                libraryName = "icu.breakiterator.native.dll";
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                libraryName = "libicu.breakiterator.native.so";
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            {
                libraryName = "libicu.breakiterator.native.dylib";
            }
            else
            {
                throw new PlatformNotSupportedException("Unsupported platform");
            }

            // Check common locations
            string[] searchPaths = new[]
            {
                Path.Combine(assemblyDir, libraryName),
                Path.Combine(assemblyDir, "runtimes", GetRuntimeIdentifier(), "native", libraryName),
                Path.Combine(AppContext.BaseDirectory, libraryName),
            };

            foreach (string path in searchPaths)
            {
                if (File.Exists(path))
                    return path;
            }

            return Path.Combine(assemblyDir, libraryName); // Default fallback
        }

        private static string GetRuntimeIdentifier()
        {
            string os;
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                os = "win";
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
                os = "linux";
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
                os = "osx";
            else
                throw new PlatformNotSupportedException();

            string arch = RuntimeInformation.ProcessArchitecture switch
            {
                Architecture.X64 => "x64",
                Architecture.X86 => "x86",
                Architecture.Arm64 => "arm64",
                Architecture.Arm => "arm",
                _ => throw new PlatformNotSupportedException($"Unsupported architecture: {RuntimeInformation.ProcessArchitecture}")
            };

            return $"{os}-{arch}";
        }

        /// <summary>
        /// Sets up a custom DLL import resolver. Call this in your application startup.
        /// </summary>
        public static void SetupDllImportResolver()
        {
            NativeLibrary.SetDllImportResolver(typeof(NativeMethods).Assembly, DllImportResolver);
        }

        private static IntPtr DllImportResolver(string libraryName, Assembly assembly, DllImportSearchPath? searchPath)
        {
            // Only handle our library
            if (libraryName != "icu.breakiterator.native")
                return IntPtr.Zero;

            // Try to load with default logic
            if (_libraryHandle == IntPtr.Zero)
            {
                try
                {
                    LoadLibrary();
                }
                catch
                {
                    return IntPtr.Zero;
                }
            }

            return _libraryHandle;
        }
    }
