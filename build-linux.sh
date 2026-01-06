#!/bin/bash
set -e

ARCHITECTURE=${1:-x64}
CONFIGURATION=${2:-Release}

echo "Building icu.breakiterator.native for Linux $ARCHITECTURE..."

# Create build directory
BUILD_DIR="build/linux-$ARCHITECTURE"
mkdir -p "$BUILD_DIR"

cd "$BUILD_DIR"

# Configure
echo "Configuring CMake..."
cmake ../.. \
    -DCMAKE_BUILD_TYPE=$CONFIGURATION \
    -DBUILD_SHARED_LIBS=OFF \
    -DICU_BUILD_TOOLS=OFF \
    -DICU_BUILD_TESTS=OFF \
    -DICU_BUILD_SAMPLES=OFF

# Build
echo "Building..."
cmake --build . --config $CONFIGURATION --parallel $(nproc)

echo "Build completed successfully!"
echo "Output: $BUILD_DIR/lib/"
