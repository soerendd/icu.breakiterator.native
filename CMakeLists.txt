cmake_minimum_required(VERSION 3.20)
project(icu.breakiterator.native VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Include ExternalProject module
include(ExternalProject)

# Output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Platform detection
if(WIN32)
    set(PLATFORM_NAME "win")
elseif(APPLE)
    set(PLATFORM_NAME "osx")
elseif(UNIX)
    set(PLATFORM_NAME "linux")
endif()

# Architecture detection
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(ARCH_NAME "x64")
else()
    set(ARCH_NAME "x86")
endif()

# Handle ARM on Linux/macOS
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)")
    set(ARCH_NAME "arm64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^arm")
    set(ARCH_NAME "arm")
endif()

message(STATUS "Building for: ${PLATFORM_NAME}-${ARCH_NAME}")

# ICU source and build directories
set(ICU_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/icu/icu4c/source)
set(ICU_BUILD_DIR ${CMAKE_BINARY_DIR}/icu-build)
set(ICU_INSTALL_DIR ${CMAKE_BINARY_DIR}/icu-install)

# Build ICU using its native build system
if(WIN32)
    # Determine platform for MSBuild
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(MSBUILD_PLATFORM "x64")
        set(ICU_OUTPUT_PLATFORM "x64")
        set(ICU_LIB_DIR "lib64")
    else()
        set(MSBUILD_PLATFORM "Win32")
        set(ICU_OUTPUT_PLATFORM "x86")  # ICU uses x86 for Win32 output
        set(ICU_LIB_DIR "lib")
    endif()
    
    # Windows: Use MSBuild with Visual Studio solution (static libraries)
    set(ICU_LIBRARIES
        ${ICU_INSTALL_DIR}/lib/sicuuc.lib
        ${ICU_INSTALL_DIR}/lib/sicuin.lib
        ${ICU_INSTALL_DIR}/lib/sicudt.lib
    )
    
    ExternalProject_Add(icu_external
        SOURCE_DIR ${ICU_SOURCE_DIR}
        BINARY_DIR ${ICU_BUILD_DIR}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND msbuild ${ICU_SOURCE_DIR}/allinone/allinone.sln
            /p:Configuration=Release
            /p:Platform=${MSBUILD_PLATFORM}
            /p:SkipUWP=true
            /p:ICUBuildStatic=true
            /p:RuntimeLibrary=MT_StaticRelease
            /t:common /t:i18n /t:stubdata
            /m
        INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory ${ICU_INSTALL_DIR}/lib
        COMMAND ${CMAKE_COMMAND} -E make_directory ${ICU_INSTALL_DIR}/include/unicode
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${ICU_SOURCE_DIR}/common/${ICU_OUTPUT_PLATFORM}/Release/sicuuc.lib
            ${ICU_INSTALL_DIR}/lib/sicuuc.lib
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${ICU_SOURCE_DIR}/i18n/${ICU_OUTPUT_PLATFORM}/Release/sicuin.lib
            ${ICU_INSTALL_DIR}/lib/sicuin.lib
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${ICU_SOURCE_DIR}/stubdata/${ICU_OUTPUT_PLATFORM}/Release/sicudt.lib
            ${ICU_INSTALL_DIR}/lib/sicudt.lib
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${ICU_SOURCE_DIR}/common/unicode ${ICU_INSTALL_DIR}/include/unicode
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${ICU_SOURCE_DIR}/i18n/unicode ${ICU_INSTALL_DIR}/include/unicode
        BUILD_BYPRODUCTS ${ICU_LIBRARIES}
    )
    
else()
    # Unix: Use configure and make
    set(ICU_LIBRARIES
        ${ICU_INSTALL_DIR}/lib/libicuuc.a
        ${ICU_INSTALL_DIR}/lib/libicui18n.a
        ${ICU_INSTALL_DIR}/lib/libicudata.a
    )
    
    # Check if we're cross-compiling (e.g., building ARM64 on x86_64)
    if(CMAKE_CROSSCOMPILING OR 
       (APPLE AND CMAKE_OSX_ARCHITECTURES STREQUAL "arm64" AND CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64") OR
       (CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)" AND CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64"))
        set(ICU_HOST_BUILD_DIR ${CMAKE_BINARY_DIR}/icu-host)
        
        # First, build ICU for the host architecture to get tools
        ExternalProject_Add(icu_host
            SOURCE_DIR ${ICU_SOURCE_DIR}
            BINARY_DIR ${ICU_HOST_BUILD_DIR}
            CONFIGURE_COMMAND ${ICU_SOURCE_DIR}/configure
                --prefix=${ICU_HOST_BUILD_DIR}/install
                --enable-static
                --disable-shared
                "CFLAGS=-fPIC"
                "CXXFLAGS=-fPIC"
            BUILD_COMMAND make -j${NPROC}
            INSTALL_COMMAND make install
        )
        
        # Then build ICU for the target architecture using host tools
        # Set cross-compilation environment variables if needed
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)")
            set(ICU_CROSS_CONFIGURE
                ${ICU_SOURCE_DIR}/configure
                --prefix=${ICU_INSTALL_DIR}
                --host=aarch64-linux-gnu
                --with-cross-build=${ICU_HOST_BUILD_DIR}
                --enable-static
                --disable-shared
                --disable-tests
                --disable-samples
                --with-data-packaging=static
                "CC=aarch64-linux-gnu-gcc"
                "CXX=aarch64-linux-gnu-g++"
                "CFLAGS=-fPIC"
                "CXXFLAGS=-fPIC"
            )
        else()
            set(ICU_CROSS_CONFIGURE
                ${ICU_SOURCE_DIR}/configure
                --prefix=${ICU_INSTALL_DIR}
                --enable-static
                --disable-shared
                --disable-tests
                --disable-samples
                --with-data-packaging=static
                --with-cross-build=${ICU_HOST_BUILD_DIR}
                "CFLAGS=-fPIC"
                "CXXFLAGS=-fPIC"
            )
        endif()
        
        ExternalProject_Add(icu_external
            DEPENDS icu_host
            SOURCE_DIR ${ICU_SOURCE_DIR}
            BINARY_DIR ${ICU_BUILD_DIR}
            CONFIGURE_COMMAND ${ICU_CROSS_CONFIGURE}
            BUILD_COMMAND make -j${NPROC}
            INSTALL_COMMAND make install
            BUILD_BYPRODUCTS ${ICU_LIBRARIES}
        )
    else()
        # Native build - no cross-compilation needed
        ExternalProject_Add(icu_external
            SOURCE_DIR ${ICU_SOURCE_DIR}
            BINARY_DIR ${ICU_BUILD_DIR}
            CONFIGURE_COMMAND ${ICU_SOURCE_DIR}/configure
                --prefix=${ICU_INSTALL_DIR}
                --enable-static
                --disable-shared
                --disable-tests
                --disable-samples
                --with-data-packaging=static
                "CFLAGS=-fPIC"
                "CXXFLAGS=-fPIC"
            BUILD_COMMAND make -j${NPROC}
            INSTALL_COMMAND make install
            BUILD_BYPRODUCTS ${ICU_LIBRARIES}
        )
    endif()
endif()

# Define our wrapper library as SHARED (but with ICU statically linked inside)
if(WIN32)
    add_library(icu.breakiterator.native SHARED
        src/breakiterator_wrapper.c
        exports.def
    )
else()
    add_library(icu.breakiterator.native SHARED
        src/breakiterator_wrapper.c
    )
endif()

# Depend on ICU being built first
add_dependencies(icu.breakiterator.native icu_external)

# Statically link ICU libraries into our shared library
target_link_libraries(icu.breakiterator.native
    PRIVATE
    ${ICU_LIBRARIES}
)

target_include_directories(icu.breakiterator.native
    PRIVATE
    ${ICU_INSTALL_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Set output name and hide ICU symbols
set_target_properties(icu.breakiterator.native PROPERTIES
    OUTPUT_NAME "icu.breakiterator.native"
    PREFIX ""
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

# On macOS, ensure the library is built for the correct architecture
if(APPLE AND CMAKE_OSX_ARCHITECTURES)
    set_target_properties(icu.breakiterator.native PROPERTIES
        OSX_ARCHITECTURES "${CMAKE_OSX_ARCHITECTURES}"
    )
endif()

# Install header for consumers
install(FILES include/icu_breakiterator_wrapper.h DESTINATION include)

# Platform-specific linking for self-contained library
if(WIN32)
    # Windows: Static runtime and hide ICU symbols
    target_compile_definitions(icu.breakiterator.native PRIVATE 
        _CRT_SECURE_NO_WARNINGS
        U_STATIC_IMPLEMENTATION
        ICU_BREAKITERATOR_EXPORTS
    )
    set_property(TARGET icu.breakiterator.native PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    
    # Link options to resolve CRT conflicts with static ICU
    target_link_options(icu.breakiterator.native PRIVATE
        /NODEFAULTLIB:MSVCRT
        /LTCG
    )
    
    # Link required Windows system libraries
    target_link_libraries(icu.breakiterator.native PRIVATE advapi32)
    
elseif(UNIX AND NOT APPLE)
    # Linux: Hide all symbols except exported ones, static libstdc++
    target_link_options(icu.breakiterator.native PRIVATE 
        -Wl,--exclude-libs,ALL
        -static-libgcc
        -static-libstdc++
    )
    
elseif(APPLE)
    # macOS: Hide symbols and use static libc++
    target_compile_definitions(icu.breakiterator.native PRIVATE
        U_STATIC_IMPLEMENTATION
    )
    
    target_link_options(icu.breakiterator.native PRIVATE
        -Wl,-dead_strip
        -Wl,-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/exports.txt
    )
    
    # Link C++ standard library statically if possible
    target_link_libraries(icu.breakiterator.native PRIVATE
        -lc++
    )
endif()

# Installation
install(TARGETS icu.breakiterator.native
    RUNTIME DESTINATION runtimes/${PLATFORM_NAME}-${ARCH_NAME}/native
    LIBRARY DESTINATION runtimes/${PLATFORM_NAME}-${ARCH_NAME}/native
)
