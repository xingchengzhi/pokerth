#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Universal Android Build – erzeugt ein Fat-APK für arm64-v8a + armeabi-v7a
# =============================================================================
# Erwartet als Umgebungsvariablen:
#   ANDROID_SDK_ROOT, ANDROID_NDK_ROOT, JAVA_HOME, VCPKG_ROOT,
#   QT_ANDROID_DIR_ARM64, QT_ANDROID_DIR_ARMV7, QT_HOST_PATH
#
# Verwendung:
#   bash build_android_universal.sh [--build-type Release] [--api-level 35]
# =============================================================================

ABIS=("arm64-v8a" "armeabi-v7a")
BUILD_TYPE=Release
API_LEVEL=${ANDROID_API_LEVEL:-35}
TARGET=${TARGET:-pokerth_client}

usage() {
  cat <<EOF
Usage: $0 [--build-type Debug|Release] [--api-level 28] [--target pokerth_client|pokerth_qml-client]

Baut PokerTH für arm64-v8a UND armeabi-v7a und erzeugt ein universelles APK.
Benötigt Dockerfile.universal als Container-Basis.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-type) BUILD_TYPE="$2"; shift 2;;
    --api-level) API_LEVEL="$2"; shift 2;;
    --target) TARGET="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

echo "=== PokerTH Universal Android Build ==="
echo "ABIs: ${ABIS[*]}"
echo "build=$BUILD_TYPE  api-level=$API_LEVEL  target=$TARGET"
echo ""

# ─── Umgebung prüfen ────────────────────────────────────────────────────────
: "${ANDROID_SDK_ROOT:?Bitte ANDROID_SDK_ROOT setzen}"
: "${ANDROID_NDK_ROOT:?Bitte ANDROID_NDK_ROOT setzen}"
: "${JAVA_HOME:?Bitte JAVA_HOME setzen}"
: "${QT_ANDROID_DIR_ARM64:?Bitte QT_ANDROID_DIR_ARM64 setzen}"
: "${QT_ANDROID_DIR_ARMV7:?Bitte QT_ANDROID_DIR_ARMV7 setzen}"
: "${QT_HOST_PATH:?Bitte QT_HOST_PATH setzen}"

# NDK r28 hat 32-bit-Support (armeabi-v7a) entfernt → NDK r27 für armv7 nötig
# ANDROID_NDK_ROOT_ARMV7 muss gesetzt sein (wird im Dockerfile.universal definiert)
if [[ -z "${ANDROID_NDK_ROOT_ARMV7:-}" ]]; then
  echo "WARNING: ANDROID_NDK_ROOT_ARMV7 nicht gesetzt – verwende ANDROID_NDK_ROOT für alle ABIs"
  echo "         armeabi-v7a wird fehlschlagen wenn NDK >= r28 verwendet wird!"
  ANDROID_NDK_ROOT_ARMV7="$ANDROID_NDK_ROOT"
fi

command -v cmake >/dev/null || { echo "cmake nicht gefunden"; exit 2; }

# Toolchain-Validierung wird pro ABI in der Build-Schleife gemacht

# Build-Tools-Version ermitteln
if [[ -d "${ANDROID_SDK_ROOT}/build-tools" ]]; then
  BUILD_TOOLS_VERSION=$(ls -1 "${ANDROID_SDK_ROOT}/build-tools" | sort -V | tail -n1)
  [[ -n "$BUILD_TOOLS_VERSION" ]] || { echo "ERROR: Keine build-tools gefunden"; exit 5; }
  export ANDROID_SDK_BUILD_TOOLS_REVISION="$BUILD_TOOLS_VERSION"
  echo "Build Tools Version: $BUILD_TOOLS_VERSION"
else
  echo "ERROR: ${ANDROID_SDK_ROOT}/build-tools nicht gefunden"; exit 5
fi

# Android-Quellverzeichnis bestimmen
if [[ $TARGET == "pokerth_qml-client" ]]; then
  ANDROID_SOURCE_DIR="${PWD}/src/gui/qt6-qml/android"
  BUILD_SUBDIR="src/gui/qt6-qml"
else
  ANDROID_SOURCE_DIR="${PWD}/src/gui/qt/android"
  BUILD_SUBDIR="src/gui/qt"
fi

# vcpkg-Argumente vorbereiten (ohne Triplet – wird pro ABI gesetzt)
VCPKG_CMAKE_FILE=""
if [[ -n "${VCPKG_ROOT:-}" ]]; then
  VCPKG_CMAKE_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
  [[ -f "$VCPKG_CMAKE_FILE" ]] || { echo "VCPKG_ROOT gesetzt, aber $VCPKG_CMAKE_FILE fehlt"; exit 4; }
fi

# ─── Hilfsfunktionen ────────────────────────────────────────────────────────

# Liefert den Qt-Android-Pfad für eine gegebene ABI
qt_dir_for_abi() {
  case "$1" in
    arm64-v8a)  echo "$QT_ANDROID_DIR_ARM64";;
    armeabi-v7a) echo "$QT_ANDROID_DIR_ARMV7";;
  esac
}

# Liefert das vcpkg-Triplet für eine gegebene ABI
vcpkg_triplet_for_abi() {
  case "$1" in
    arm64-v8a)  echo "arm64-android";;
    armeabi-v7a) echo "arm-android";;
  esac
}

# Liefert den NDK-Root-Pfad für eine gegebene ABI
ndk_root_for_abi() {
  case "$1" in
    arm64-v8a)  echo "$ANDROID_NDK_ROOT";;
    armeabi-v7a) echo "$ANDROID_NDK_ROOT_ARMV7";;
  esac
}

# ─── Phase 1: Beide Architekturen bauen ─────────────────────────────────────

for ABI in "${ABIS[@]}"; do
  echo ""
  echo "================================================================"
  echo "  Baue für ABI: $ABI"
  echo "================================================================"
  echo ""

  QT_ANDROID_DIR=$(qt_dir_for_abi "$ABI")
  VCPKG_TRIPLET=$(vcpkg_triplet_for_abi "$ABI")
  NDK_ROOT=$(ndk_root_for_abi "$ABI")
  TOOLCHAIN_FILE="$NDK_ROOT/build/cmake/android.toolchain.cmake"
  BUILD_DIR="build-android-${ABI}"

  [[ -f "$TOOLCHAIN_FILE" ]] || { echo "Android toolchain nicht gefunden: $TOOLCHAIN_FILE"; exit 3; }
  echo "NDK: $NDK_ROOT"

  mkdir -p "$BUILD_DIR"

  # CMake Initial Cache
  cat > "$BUILD_DIR/InitialCache.cmake" <<EOF
set(ANDROID_SDK_BUILD_TOOLS_REVISION "$BUILD_TOOLS_VERSION" CACHE STRING "")
set(QT_ANDROID_SDK_BUILD_TOOLS_REVISION "$BUILD_TOOLS_VERSION" CACHE STRING "")
EOF

  VCPKG_CMAKE_ARGS=()
  if [[ -n "$VCPKG_CMAKE_FILE" ]]; then
    VCPKG_CMAKE_ARGS+=(
      -DCMAKE_TOOLCHAIN_FILE="$VCPKG_CMAKE_FILE"
      -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE="$TOOLCHAIN_FILE"
      -DVCPKG_TARGET_TRIPLET="$VCPKG_TRIPLET"
    )
  fi

  echo "Konfiguriere CMake für $ABI ..."
  qt-cmake -S . -B "$BUILD_DIR" -G Ninja \
    -C "$BUILD_DIR/InitialCache.cmake" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    "${VCPKG_CMAKE_ARGS[@]}" \
    -DANDROID_ABI="$ABI" \
    -DANDROID_NATIVE_API_LEVEL="$API_LEVEL" \
    -DCMAKE_PREFIX_PATH="${QT_ANDROID_DIR}/lib/cmake" \
    -DCMAKE_FIND_ROOT_PATH="${QT_ANDROID_DIR}" \
    -DQt6_DIR="${QT_ANDROID_DIR}/lib/cmake/Qt6" \
    ${QT_HOST_PATH:+-DQT_HOST_PATH="$QT_HOST_PATH"} \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/$BUILD_DIR/install" \
    -DProtobuf_USE_STATIC_LIBS=ON

  echo "Baue Target '${TARGET}' für $ABI ..."
  cmake --build "$BUILD_DIR" --target "${TARGET}" -j "$(nproc || echo 1)"

  echo "Build für $ABI abgeschlossen."
done

# ─── Phase 2: Universal-APK zusammenstellen ─────────────────────────────────

echo ""
echo "================================================================"
echo "  Erstelle Universal-APK"
echo "================================================================"
echo ""

UNIVERSAL_DIR="build-android-universal"
ANDROID_BUILD_DIR="$UNIVERSAL_DIR/android-build"
mkdir -p "$ANDROID_BUILD_DIR"

# Verzeichnisstruktur für alle ABIs
for ABI in "${ABIS[@]}"; do
  mkdir -p "$ANDROID_BUILD_DIR/libs/$ABI"
done

# Kopiere Android-Manifest und Ressourcen
if [[ -d "$ANDROID_SOURCE_DIR" ]]; then
  echo "Kopiere Android-Quelldateien aus: $ANDROID_SOURCE_DIR"
  cp -rv "$ANDROID_SOURCE_DIR"/* "$ANDROID_BUILD_DIR/" || true
fi

mkdir -p "$ANDROID_BUILD_DIR/res/drawable"
mkdir -p "$ANDROID_BUILD_DIR/res/values"

# Dynamisches AndroidManifest.xml
cat > "$ANDROID_BUILD_DIR/AndroidManifest.xml" <<MANIFEST
<?xml version="1.0"?>
<manifest package="org.pokerth.widget"
          xmlns:android="http://schemas.android.com/apk/res/android"
          android:versionName="2.0"
          android:versionCode="20"
          android:installLocation="auto">

    <uses-sdk
        android:minSdkVersion="28"
        android:targetSdkVersion="$API_LEVEL"/>

    <supports-screens
        android:largeScreens="true"
        android:normalScreens="true"
        android:anyDensity="true"
        android:smallScreens="true"/>

    <application
        android:hardwareAccelerated="true"
        android:name="org.qtproject.qt.android.bindings.QtApplication"
        android:label="PokerTH"
        android:icon="@drawable/ic_launcher"
        android:extractNativeLibs="true"
        android:usesCleartextTraffic="true"
        android:theme="@android:style/Theme.NoTitleBar.Fullscreen">

        <activity
            android:name="org.qtproject.qt.android.bindings.QtActivity"
            android:label="PokerTH"
            android:screenOrientation="landscape"
            android:launchMode="singleTop"
            android:windowSoftInputMode="adjustResize"
            android:exported="true"
            android:configChanges="orientation|uiMode|screenLayout|screenSize|smallestScreenSize|layoutDirection|locale|fontScale|keyboard|keyboardHidden|navigation|mcc|mnc|density">

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <meta-data
                android:name="android.app.lib_name"
                android:value="$TARGET"/>

            <meta-data
                android:name="android.app.extract_android_style"
                android:value="minimal"/>

        </activity>
    </application>

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

</manifest>
MANIFEST

echo "AndroidManifest.xml erstellt mit lib_name=$TARGET"

# ─── Native Libraries und OpenSSL für jede ABI kopieren ─────────────────────

OPENSSL_BASE_URL="https://github.com/KDAB/android_openssl/raw/master/ssl_3"

for ABI in "${ABIS[@]}"; do
  echo ""
  echo "--- Sammle Libraries für $ABI ---"

  SRC_BUILD_DIR="build-android-${ABI}"

  # .so-Datei finden
  SO_FILE=$(find "$SRC_BUILD_DIR" -type f \( -name "lib${TARGET}.so" -o -name "lib${TARGET}_*.so" \) | head -n1)
  if [[ -z "$SO_FILE" ]]; then
    echo "ERROR: lib${TARGET}*.so nicht gefunden in $SRC_BUILD_DIR"
    find "$SRC_BUILD_DIR" -type f -name "*.so" | head -20
    exit 6
  fi

  EXPECTED_SO_NAME="lib${TARGET}_${ABI}.so"
  echo "Kopiere $SO_FILE → libs/$ABI/$EXPECTED_SO_NAME"
  cp -v "$SO_FILE" "$ANDROID_BUILD_DIR/libs/$ABI/$EXPECTED_SO_NAME"
  ln -sf "$EXPECTED_SO_NAME" "$ANDROID_BUILD_DIR/libs/$ABI/lib${TARGET}.so"

  # OpenSSL herunterladen
  echo "Lade OpenSSL für $ABI herunter ..."
  wget -q -O "$ANDROID_BUILD_DIR/libs/$ABI/libssl_3.so" "$OPENSSL_BASE_URL/$ABI/libssl_3.so" \
    || echo "WARNING: libssl_3.so Download fehlgeschlagen für $ABI"
  wget -q -O "$ANDROID_BUILD_DIR/libs/$ABI/libcrypto_3.so" "$OPENSSL_BASE_URL/$ABI/libcrypto_3.so" \
    || echo "WARNING: libcrypto_3.so Download fehlgeschlagen für $ABI"
done

# ─── androiddeployqt mit der primären ABI (arm64-v8a) ausführen ─────────────

# Wir verwenden die arm64-v8a deployment-settings als Basis
PRIMARY_ABI="arm64-v8a"
PRIMARY_BUILD_DIR="build-android-${PRIMARY_ABI}"
QT_ANDROID_DIR_PRIMARY=$(qt_dir_for_abi "$PRIMARY_ABI")

DEPLOY_JSON=$(find "$PRIMARY_BUILD_DIR/$BUILD_SUBDIR" -type f -name "*deployment-settings.json" 2>/dev/null | head -n1 || true)
if [[ -z "$DEPLOY_JSON" ]]; then
  echo "Suche deployment-settings.json im gesamten Build-Verzeichnis..."
  DEPLOY_JSON=$(find "$PRIMARY_BUILD_DIR" -type f -name "*deployment-settings.json" 2>/dev/null | head -n1 || true)
fi
if [[ -z "$DEPLOY_JSON" ]]; then
  echo "ERROR: Keine deployment-settings.json gefunden."
  exit 10
fi

echo "Gefundene deployment settings: $DEPLOY_JSON"

# Kopiere deployment-settings ins universal-Verzeichnis und patche sie
UNIVERSAL_DEPLOY_JSON="$UNIVERSAL_DIR/deployment-settings.json"
cp "$DEPLOY_JSON" "$UNIVERSAL_DEPLOY_JSON"

if command -v jq >/dev/null 2>&1; then
  echo "Patche deployment settings ..."
  TMP_JSON=$(mktemp)
  jq --arg bt "$BUILD_TOOLS_VERSION" \
     --arg al "$API_LEVEL" \
     --arg target "$TARGET" \
     --arg android_src "$ANDROID_SOURCE_DIR" \
     --arg arch "$PRIMARY_ABI" \
    '.["android-build-tools-revision"] = $bt |
     .["android-sdk-build-tools-revision"] = $bt |
     .["android-target-sdk-version"] = $al |
     .["android-min-sdk-version"] = "28" |
     .["target-architecture"] = $arch |
     .["application-binary"] = $target |
     .["android-package-source-directory"] = $android_src' \
    "$UNIVERSAL_DEPLOY_JSON" > "$TMP_JSON"
  mv "$TMP_JSON" "$UNIVERSAL_DEPLOY_JSON"
fi

ANDROIDDEPLOYQT="${QT_HOST_PATH}/bin/androiddeployqt"
if [[ ! -x "$ANDROIDDEPLOYQT" ]]; then
  echo "ERROR: androiddeployqt nicht gefunden: $ANDROIDDEPLOYQT"
  exit 7
fi

echo ""
echo "Starte androiddeployqt ..."
set +e
"$ANDROIDDEPLOYQT" \
  --input "$UNIVERSAL_DEPLOY_JSON" \
  --output "$ANDROID_BUILD_DIR" \
  --android-platform "android-${API_LEVEL}" \
  --jdk "$JAVA_HOME" \
  --verbose
DEPLOYQT_EXIT=$?
set -e

echo "androiddeployqt Exit-Code: $DEPLOYQT_EXIT"

# ─── Sicherstellen, dass BEIDE ABIs im finalen APK landen ──────────────────

# androiddeployqt kopiert u.U. nur Libs für die primäre ABI.
# Wir stellen sicher, dass die sekundären ABIs ebenfalls vorhanden sind.
for ABI in "${ABIS[@]}"; do
  JNILIBS_DIR="$ANDROID_BUILD_DIR/libs/$ABI"
  if [[ ! -d "$JNILIBS_DIR" ]] || [[ -z "$(ls -A "$JNILIBS_DIR" 2>/dev/null)" ]]; then
    echo "Stelle sicher, dass libs/$ABI befüllt ist ..."
    mkdir -p "$JNILIBS_DIR"

    SRC_BUILD_DIR="build-android-${ABI}"
    SO_FILE=$(find "$SRC_BUILD_DIR" -type f \( -name "lib${TARGET}.so" -o -name "lib${TARGET}_*.so" \) | head -n1)
    [[ -n "$SO_FILE" ]] && cp -v "$SO_FILE" "$JNILIBS_DIR/lib${TARGET}_${ABI}.so"
    ln -sf "lib${TARGET}_${ABI}.so" "$JNILIBS_DIR/lib${TARGET}.so"

    wget -q -O "$JNILIBS_DIR/libssl_3.so" "$OPENSSL_BASE_URL/$ABI/libssl_3.so" || true
    wget -q -O "$JNILIBS_DIR/libcrypto_3.so" "$OPENSSL_BASE_URL/$ABI/libcrypto_3.so" || true
  fi
done

# ─── Icon kopieren (nach androiddeployqt, da es Verzeichnisse neu anlegt) ──

echo ""
echo "Kopiere PokerTH Icon ..."
mkdir -p "$ANDROID_BUILD_DIR/res/drawable"
cp -v "${ROOT}/pokerth/data/gfx/gui/misc/windowicon_transparent.png" \
      "$ANDROID_BUILD_DIR/res/drawable/ic_launcher.png" || echo "WARNING: Icon-Kopie fehlgeschlagen"

# ─── Gradle Build ───────────────────────────────────────────────────────────

if [[ -f "$ANDROID_BUILD_DIR/gradle.properties" ]]; then
  echo ""
  echo "Patche gradle.properties ..."

  if grep -q "^androidBuildToolsVersion=" "$ANDROID_BUILD_DIR/gradle.properties"; then
    sed -i "s/^androidBuildToolsVersion=.*/androidBuildToolsVersion=$BUILD_TOOLS_VERSION/" "$ANDROID_BUILD_DIR/gradle.properties"
  else
    echo "androidBuildToolsVersion=$BUILD_TOOLS_VERSION" >> "$ANDROID_BUILD_DIR/gradle.properties"
  fi

  if ! grep -q "^androidCompileSdkVersion=" "$ANDROID_BUILD_DIR/gradle.properties"; then
    echo "androidCompileSdkVersion=$API_LEVEL" >> "$ANDROID_BUILD_DIR/gradle.properties"
  fi

  echo ""
  cat "$ANDROID_BUILD_DIR/gradle.properties"

  echo ""
  echo "Starte Gradle assembleRelease ..."
  cd "$ANDROID_BUILD_DIR"

  if [[ ! -f "gradlew" ]]; then
    echo "ERROR: gradlew nicht gefunden in $ANDROID_BUILD_DIR"
    exit 8
  fi

  chmod +x gradlew
  ./gradlew assembleRelease --stacktrace

  cd -
else
  echo "WARNING: gradle.properties nicht gefunden in $ANDROID_BUILD_DIR"
  if [[ $DEPLOYQT_EXIT -ne 0 ]]; then
    echo "ERROR: androiddeployqt fehlgeschlagen und keine gradle.properties zum Patchen"
    exit $DEPLOYQT_EXIT
  fi
fi

# ─── Ergebnis ───────────────────────────────────────────────────────────────

echo ""
echo "Suche generiertes APK ..."
APK_FILE=$(find "$ANDROID_BUILD_DIR" -type f -name "*.apk" | grep -E "(release|debug)" | grep -v "unaligned" | head -n1)

if [[ -n "$APK_FILE" ]]; then
  echo ""
  echo "======================================"
  echo "  Universal-APK erfolgreich erstellt!"
  echo "  ABIs: ${ABIS[*]}"
  echo "  Pfad: $APK_FILE"

  if command -v aapt >/dev/null 2>&1; then
    echo ""
    echo "APK Info:"
    aapt dump badging "$APK_FILE" | grep -E "package|sdkVersion|targetSdkVersion|native-code"
  fi

  # Prüfe, ob beide ABIs im APK enthalten sind
  if command -v unzip >/dev/null 2>&1; then
    echo ""
    echo "Enthaltene native Libraries:"
    unzip -l "$APK_FILE" | grep "lib/.*\.so" || echo "(keine .so-Dateien gefunden)"
  fi

  echo "======================================"
else
  echo "WARNING: Kein generiertes APK gefunden"
  find "$ANDROID_BUILD_DIR" -type f -name "*.apk" || echo "Keine APK-Dateien"
fi

echo ""
echo "Fertig."
