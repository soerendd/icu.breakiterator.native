#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <library-path>"
    exit 1
fi

LIBRARY_PATH=$1

if [ ! -f "$LIBRARY_PATH" ]; then
    echo "Error: File not found: $LIBRARY_PATH"
    exit 1
fi

echo "Verifying dependencies for: $LIBRARY_PATH"
echo ""

# Detect platform
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Checking Linux shared library dependencies..."
    echo ""
    
    # Check dependencies
    DEPS=$(ldd "$LIBRARY_PATH" 2>&1)
    echo "$DEPS"
    echo ""
    
    # Check for ICU dependencies (should not exist)
    if echo "$DEPS" | grep -i "libicu" > /dev/null; then
        echo "ERROR: Found external ICU dependencies!"
        exit 1
    fi
    
    # Check for libstdc++ (should be statically linked)
    if echo "$DEPS" | grep "libstdc++" > /dev/null; then
        echo "WARNING: libstdc++ is dynamically linked (expected static)"
    fi
    
    # Check for libgcc (should be statically linked)
    if echo "$DEPS" | grep "libgcc_s" > /dev/null; then
        echo "WARNING: libgcc is dynamically linked (expected static)"
    fi
    
    echo "✓ No external ICU dependencies detected!"
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Checking macOS dylib dependencies..."
    echo ""
    
    # Check dependencies
    DEPS=$(otool -L "$LIBRARY_PATH" 2>&1)
    echo "$DEPS"
    echo ""
    
    # Check for ICU dependencies (should not exist)
    if echo "$DEPS" | grep -i "libicu" > /dev/null; then
        echo "ERROR: Found external ICU dependencies!"
        exit 1
    fi
    
    echo "✓ No external ICU dependencies detected!"
else
    echo "Unknown platform: $OSTYPE"
    exit 1
fi

echo ""
echo "Dependency check completed successfully."
