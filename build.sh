#!/bin/bash

# EAE Firmware Build Script
# Author: Murray Kopit
# Date: July 31, 2025

set -e

echo "=== EAE Firmware Build Script ==="
echo

# Create build directory
if [ ! -d "build" ]; then
    mkdir build
fi

cd build

# Configure with CMake
echo "Configuring project..."
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build
echo "Building project..."
cmake --build . -j$(nproc)

echo
echo "Build complete!"
echo "Executables:"
echo "  - ./build/eae_firmware (main application)"
echo "  - ./build/eae_tests (unit tests)"
echo
echo "Run with: ./build/eae_firmware --help"