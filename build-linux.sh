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
echo "Configuring CMake (static linking)..."
cmake ../.. \
    -DCMAKE_BUILD_TYPE=$CONFIGURATION \
    -DBUILD_SHARED_LIBS=OFF \
    -DICU_BUILD_TOOLS=OFF \
    -DICU_BUILD_TESTS=OFF \
    -DICU_BUILD_SAMPLES=OFF \
    -DCMAKE_CXX_FLAGS="-fvisibility=hidden" \
    -DCMAKE_C_FLAGS="-fvisibility=hidden"

# Build
echo "Building..."
cmake --build . --config $CONFIGURATION --parallel $(nproc)

echo "Build completed successfully!"
echo "Output: $BUILD_DIR/lib/"

# Verify no external dependencies
SO_PATH="$BUILD_DIR/lib/libicu.breakiterator.native.so"
if [ -f "$SO_PATH" ]; then
    echo ""
    echo "Verifying dependencies..."
    bash "$(dirname "$0")/verify-dependencies.sh" "$SO_PATH" || true
fi
