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
echo "Configuring CMake..."
cmake ../.. \
    -DCMAKE_BUILD_TYPE=$CONFIGURATION \
    $ARCH_FLAGS \
    -DBUILD_SHARED_LIBS=OFF \
    -DICU_BUILD_TOOLS=OFF \
    -DICU_BUILD_TESTS=OFF \
    -DICU_BUILD_SAMPLES=OFF

# Build
echo "Building..."
cmake --build . --config $CONFIGURATION --parallel $(sysctl -n hw.ncpu)

echo "Build completed successfully!"
echo "Output: $BUILD_DIR/lib/"
