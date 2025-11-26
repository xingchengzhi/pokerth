#!/bin/bash

# Set environment variables from Dockerfile
ROOT=${ROOT:-/opt/pokerth-windows}
QT_VERSION=${QT_VERSION:-6.9.3}

# Set Qt paths
export QT_WINDOWS_DIR=${ROOT}/Qt/${QT_VERSION}/mingw_64
export QT_HOST_PATH=${ROOT}/Qt/${QT_VERSION}/gcc_64
export CMAKE_PREFIX_PATH=${QT_WINDOWS_DIR}
export Qt6_DIR=${QT_WINDOWS_DIR}/lib/cmake/Qt6

# Set vcpkg paths
export VCPKG_ROOT=${ROOT}/vcpkg
export CMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake
export VCPKG_TARGET_TRIPLET=x64-mingw-static
# Set MinGW path
export MINGW_DIR=/usr/x86_64-w64-mingw32

# Add qt-cmake to PATH
export PATH=${QT_HOST_PATH}/bin:${PATH}

cd ${ROOT}/pokerth

# Set the build directory
BUILD_DIR="./build"
DEPLOY_DIR="${BUILD_DIR}/deploy"

# Remove old build directory to start fresh
# rm -rf $BUILD_DIR

# Create the build directory
mkdir -p $BUILD_DIR

echo "Building with:"
echo "  Qt Windows: ${QT_WINDOWS_DIR}"
echo "  Qt Host: ${QT_HOST_PATH}"
echo "  Qt6_DIR: ${Qt6_DIR}"
echo "  vcpkg: ${VCPKG_ROOT}"
echo "  Toolchain: ${CMAKE_TOOLCHAIN_FILE}"



# Run CMake to configure the project for Windows cross-compilation
qt-cmake -S . -B $BUILD_DIR \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} \
    -DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET} \
    -DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH} \
    -DQt6_DIR=${Qt6_DIR} \
    -DQT_HOST_PATH=${QT_HOST_PATH} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_CXX_FLAGS="-fpermissive -Wno-error" \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_FIND_ROOT_PATH=${VCPKG_ROOT}/installed/${VCPKG_TARGET_TRIPLET} \
    -DQT_NO_DEPLOY=ON \
    -DQT_DEPLOY_SUPPORT=OFF

# Build the project
cmake --build $BUILD_DIR  --target ${TARGET} --parallel $(nproc) 2>&1

if [ $? -ne 0 ]; then
    echo "Build failed! Check build.log for details."
    exit 1
fi

echo "Build successful! Collecting DLLs and data files..."

# Create deployment directory
mkdir -p $DEPLOY_DIR

# Collect all required DLLs for deployment
echo "Copying executable..."
if [ -d "$BUILD_DIR/bin" ]; then
    cp $BUILD_DIR/bin/*.exe $DEPLOY_DIR/ 2>/dev/null || echo "  Warning: No executables found in bin/"
fi

echo "Copying Qt DLLs..."
cp ${QT_WINDOWS_DIR}/bin/Qt6Core.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6Gui.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6Widgets.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6Network.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6Sql.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6Xml.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6WebSockets.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6Multimedia.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6MultimediaWidgets.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6Qml.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6Quick.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6QuickControls2.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${QT_WINDOWS_DIR}/bin/Qt6Svg.dll $DEPLOY_DIR/ 2>/dev/null || true

echo "Copying Qt plugins..."
mkdir -p $DEPLOY_DIR/plugins/platforms
mkdir -p $DEPLOY_DIR/plugins/styles
mkdir -p $DEPLOY_DIR/plugins/imageformats
mkdir -p $DEPLOY_DIR/plugins/sqldrivers

cp -r ${QT_WINDOWS_DIR}/plugins/platforms/*.dll $DEPLOY_DIR/plugins/platforms/ 2>/dev/null || true
cp -r ${QT_WINDOWS_DIR}/plugins/styles/*.dll $DEPLOY_DIR/plugins/styles/ 2>/dev/null || true
cp -r ${QT_WINDOWS_DIR}/plugins/imageformats/*.dll $DEPLOY_DIR/plugins/imageformats/ 2>/dev/null || true
cp -r ${QT_WINDOWS_DIR}/plugins/sqldrivers/*.dll $DEPLOY_DIR/plugins/sqldrivers/ 2>/dev/null || true


# echo "Copying vcpkg DLLs..."
# cp ${VCPKG_ROOT}/installed/${VCPKG_TARGET_TRIPLET}/bin/*.dll $DEPLOY_DIR/ 2>/dev/null || true

echo "Copying MinGW runtime DLLs..."
cp ${MINGW_DIR}/bin/libgcc_s_seh-1.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${MINGW_DIR}/bin/libstdc++-6.dll $DEPLOY_DIR/ 2>/dev/null || true
cp ${MINGW_DIR}/bin/libwinpthread-1.dll $DEPLOY_DIR/ 2>/dev/null || true

# Copy data directory
echo "Copying data directory..."
if [ -d "data" ]; then
    cp -r data $DEPLOY_DIR/
    echo "  Data directory copied successfully"
else
    echo "  Warning: data directory not found in ${ROOT}/pokerth"
fi

# Create qt.conf to help Qt find plugins
echo "Creating qt.conf..."
cat > $DEPLOY_DIR/qt.conf << EOF
[Paths]
Plugins = plugins
EOF

echo ""
echo "======================================"
echo "Build process completed successfully!"
echo "======================================"
echo ""
echo "Deployment package created in: ${DEPLOY_DIR}"
echo ""
echo "Files included:"
ls -lh $DEPLOY_DIR/*.exe 2>/dev/null || echo "  No executables found!"
echo ""
echo "Data files:"
if [ -d "$DEPLOY_DIR/data" ]; then
    echo "  data/ directory included with $(find $DEPLOY_DIR/data -type f | wc -l) files"
else
    echo "  No data directory"
fi
echo ""
echo "To test with Wine on Linux:"
echo "  cd ${DEPLOY_DIR}"
echo "  wine ${TARGET}.exe"
echo ""
echo "To create installer (requires NSIS):"
echo "  makensis installer.nsi"
echo ""