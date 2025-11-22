#!/usr/bin/env bash
set -euo pipefail

# Minimaler Android-Build-Helper für pokerth_client (Template)
# Erwartet als Umgebungsvariablen:
#  ANDROID_SDK_ROOT, ANDROID_NDK_ROOT, JAVA_HOME, QT_ANDROID_DIR
# Beispiel-Aufruf:
#  QT_ANDROID_DIR=/opt/Qt/6.7.0/android_arm64_v8a \ 
#    ANDROID_SDK_ROOT=~/Android/Sdk ANDROID_NDK_ROOT=~/Android/Sdk/ndk/25.2.9519653 \
#    ./scripts/build_android.sh --arch arm64-v8a --build-type Release

usage(){
  cat <<EOF
Usage: $0 [--arch arm64-v8a|armeabi-v7a|x86|x86_64] [--build-type Debug|Release] [--api-level 21]

Wichtig: Installiere Android SDK/NDK und eine Qt-for-Android-Build-Installation.
Setze mindestens ANDROID_SDK_ROOT, ANDROID_NDK_ROOT, JAVA_HOME und QT_ANDROID_DIR.
EOF
}

ARCH=arm64-v8a
BUILD_TYPE=Release
API_LEVEL=21

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch) ARCH="$2"; shift 2;;
    --build-type) BUILD_TYPE="$2"; shift 2;;
    --api-level) API_LEVEL="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

echo "=== PokerTH Android build helper ==="
echo "arch=$ARCH build=$BUILD_TYPE api-level=$API_LEVEL"

# Validiere erlaubte ABIs (inkl. x86/x86_64)
case "$ARCH" in
  arm64-v8a|armeabi-v7a|x86|x86_64) ;;
  *)
    echo "Unsupported arch: $ARCH"
    echo "Supported: arm64-v8a, armeabi-v7a, x86, x86_64"
    exit 1
    ;;
esac

: ${ANDROID_SDK_ROOT:?Please set ANDROID_SDK_ROOT}
: ${ANDROID_NDK_ROOT:?Please set ANDROID_NDK_ROOT}
: ${JAVA_HOME:?Please set JAVA_HOME}
: ${QT_ANDROID_DIR:?Please set QT_ANDROID_DIR (Qt installation for Android)}

command -v cmake >/dev/null || { echo "cmake not found in PATH"; exit 2; }
command -v ninja >/dev/null || { echo "ninja not found in PATH (recommended)"; }

TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake"
if [[ ! -f "$TOOLCHAIN_FILE" ]]; then
  echo "Cannot find Android toolchain file: $TOOLCHAIN_FILE"; exit 3
fi

BUILD_DIR=build-android-${ARCH}
mkdir -p "$BUILD_DIR"

echo "Configuring CMake..."
cmake -S . -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
  -DANDROID_ABI="$ARCH" \
  -DANDROID_NATIVE_API_LEVEL=$API_LEVEL \
  -DCMAKE_PREFIX_PATH="${QT_ANDROID_DIR}/lib/cmake" \
  -DCMAKE_INSTALL_PREFIX="$(pwd)/$BUILD_DIR/install"

echo "Building target 'pokerth_client' (this can take a while)..."
cmake --build "$BUILD_DIR" --target pokerth_client -j $(nproc || echo 1)

echo
echo "Build finished. Built artefacts live in: $BUILD_DIR"

# Suche nach möglichen Qt Android deployment settings json
DEPLOY_JSON=$(find "$BUILD_DIR" -maxdepth 2 -type f -name "*-deployment-settings.json" | head -n1 || true)
if [[ -n "$DEPLOY_JSON" && -x "${QT_ANDROID_DIR}/bin/androiddeployqt" ]]; then
  echo "Found deployment settings: $DEPLOY_JSON"
  echo "Running androiddeployqt to create APK (requires gradle, sdk & jdk)..."
  "${QT_ANDROID_DIR}/bin/androiddeployqt" --input "$DEPLOY_JSON" --output "$BUILD_DIR/android-build" --jdk "$JAVA_HOME" --sdk "$ANDROID_SDK_ROOT" --ndk "$ANDROID_NDK_ROOT" --gradle
  echo "androiddeployqt finished. Check $BUILD_DIR/android-build for the generated APK/Gradle project."
else
  echo "Note: androiddeployqt not run automatically."
  echo "If you have Qt's androiddeployqt and a *-deployment-settings.json file in your build dir, rerun the script with those variables set."
  echo "Alternatively, package the built native libs into an APK using Qt Creator or androiddeployqt."
fi

echo "Done."
