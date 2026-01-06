#!/bin/bash
set -e

ARCHITECTURE=${1:-x64}
CONFIGURATION=${2:-Release}

echo "Building icu.breakiterator.native for macOS $ARCHITECTURE..."

# Set CMake architecture flags
if [ "$ARCHITECTURE" = "arm64" ]; then
    ARCH_FLAGS="-DCMAKE_OSX_ARCHITECTURES=arm64"
else
    ARCH_FLAGS="-DCMAKE_OSX_ARCHITECTURES=x86_64"
fi

# Create build directory
BUILD_DIR="build/macos-$ARCHITECTURE"
mkdir -p "$BUILD_DIR"

cd "$BUILD_DIR"

# Configure
echo "Configuring CMake (static linking)..."
cmake ../.. \
    -DCMAKE_BUILD_TYPE=$CONFIGURATION \
    $ARCH_FLAGS \
    -DBUILD_SHARED_LIBS=OFF \
    -DICU_BUILD_TOOLS=OFF \
    -DICU_BUILD_TESTS=OFF \
    -DICU_BUILD_SAMPLES=OFF \
    -DCMAKE_CXX_FLAGS="-fvisibility=hidden" \
    -DCMAKE_C_FLAGS="-fvisibility=hidden"

# Build
echo "Building..."
cmake --build . --config $CONFIGURATION --parallel $(sysctl -n hw.ncpu)

echo "Build completed successfully!"
echo "Output: $BUILD_DIR/lib/"

# Verify no external dependencies
DYLIB_PATH="$BUILD_DIR/lib/libicu.breakiterator.native.dylib"
if [ -f "$DYLIB_PATH" ]; then
    echo ""
    echo "Verifying dependencies..."
    bash "$(dirname "$0")/verify-dependencies.sh" "$DYLIB_PATH" || true
fi
