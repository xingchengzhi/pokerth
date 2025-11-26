#!/bin/bash

# Set the build directory
BUILD_DIR="./build"

# Create the build directory if it doesn't exist
mkdir -p $BUILD_DIR

# Run CMake to configure the project
cmake -S . -B $BUILD_DIR

# Build the project
cmake --build $BUILD_DIR

# Optionally, run tests if applicable
# cmake --build $BUILD_DIR --target test

echo "Build process completed."