#!/bin/bash
set -e

# AppImage Deploy Script für den PokerTH QtQuick/QML-Client (pokerth_qml-client).
#
# KONVENTIONELLER Ansatz (kein gebündeltes glibc / kein custom ld-linux):
#   Bundelt Qt-Libs, Qt-Plugins, QML-Module und app-eigene Deps.
#   Kern-System-Libs (glibc, libstdc++, GPU/Display-Stack, Windowing, GLib …)
#   kommen vom Host — genau wie beim Start des nackten Binaries.
#
# Unterschiede zum Widgets-Skript (create_appimage_deploy.sh):
#   * Binary: pokerth_qml-client (statt pokerth_client)
#   * Qt-QML-Module (QtQuick, QtQml, QtCore) werden gebündelt
#   * qt.conf enthält Imports / Qml2Imports
#   * AppRun setzt QML_IMPORT_PATH / QML2_IMPORT_PATH
#   * Kein glibc-Bundle, kein ld-linux-Trick (verursacht GL-Context-Fehler)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
ARCH="$(uname -m)"
APPDIR="${SCRIPT_DIR}/PokerTH-QML.AppDir"
APPIMAGE_NAME="PokerTH-QML-${ARCH}-$(date +%Y%m%d).AppImage"

echo "=== PokerTH QML-Client AppImage Erstellung ==="
echo "Project Root: $PROJECT_ROOT"
echo "Build Dir:    $BUILD_DIR"
echo "AppDir:       $APPDIR"
echo "Output:       $APPIMAGE_NAME"
echo ""

# --- Voraussetzungen prüfen ---

if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: Build-Verzeichnis nicht gefunden: $BUILD_DIR"
    echo "Bitte führen Sie zuerst den Build-Prozess durch."
    exit 1
fi

if [ ! -f "$BUILD_DIR/bin/pokerth_qml-client" ]; then
    echo "ERROR: pokerth_qml-client Binary nicht gefunden!"
    echo "Bitte zuerst bauen: cmake --build build --target pokerth_qml-client"
    exit 1
fi

# appimagetool herunterladen falls nicht vorhanden
APPIMAGETOOL_VERSION="continuous"
APPIMAGETOOL="${SCRIPT_DIR}/appimagetool-${ARCH}.AppImage"
if [ ! -f "$APPIMAGETOOL" ]; then
    echo "=== Lade appimagetool herunter (${APPIMAGETOOL_VERSION}) ==="
    wget -q --show-progress -O "$APPIMAGETOOL" \
        "https://github.com/AppImage/appimagetool/releases/download/${APPIMAGETOOL_VERSION}/appimagetool-${ARCH}.AppImage" \
        || { echo "ERROR: appimagetool Download fehlgeschlagen"; exit 1; }
    chmod +x "$APPIMAGETOOL"
fi

# --- AppDir Struktur aufbauen ---

echo "=== Erstelle AppDir-Struktur ==="
rm -rf "$APPDIR"
mkdir -p "$APPDIR"/usr/{bin,lib,share/pokerth,plugins,qml}

# --- Binaries kopieren ---

echo "=== Kopiere Binaries ==="
cp -v "$BUILD_DIR/bin/pokerth_qml-client" "$APPDIR/usr/bin/"

# Botfiles kopieren (für lokale Spiele gegen Computergegner)
if [ -d "$BUILD_DIR/bin/botfiles" ]; then
    cp -rv "$BUILD_DIR/bin/botfiles" "$APPDIR/usr/bin/"
fi

# --- Abhängigkeiten sammeln (ohne System-/Kern-Libs) ---

echo ""
echo "=== Sammle Qt- und App-Abhängigkeiten ==="

# Bibliotheken, die NICHT gebündelt werden dürfen:
#
# 1. GPU/Grafiktreiber: eng an Host-Kernel & GPU-Treiber gebunden.
#    Gebündelt scheitert die OpenGL/EGL-Initialisierung ("EGL not available").
#
# 2. glibc + C++ Runtime: auf aktuellen Distros identisch zum Build-System.
#    Gebündelt + eigener ld-linux → Mixed-Environment-Absturz (SIGABRT aus
#    QSGRenderLoop::handleContextCreationFailure, weil Host-mesa unser glibc
#    nicht verträgt).
#
# 3. Windowing (X11/Wayland/XCB/XKB) + GLib/DBus: tief ins Host-Desktop-
#    Environment integriert; gemischte Versionen führen zu Crashes oder
#    IPC-Fehlern (z. B. D-Bus-Socket-Protokoll-Mismatch).
#
# 4. Fontconfig/Freetype: nutzen die Host-Font-Datenbank; gebündelt werden
#    Systemschriften nicht gefunden.
is_excluded_lib() {
    case "$1" in
        # --- GPU / Grafiktreiber ---
        libEGL.so*|libEGL_*.so*)           return 0 ;;
        libGLdispatch.so*|libGLX.so*|libGLX_*.so*) return 0 ;;
        libGL.so*|libGLES*.so*|libOpenGL.so*|libGLU.so*) return 0 ;;
        libgallium*.so*|libglapi.so*|libgbm.so*) return 0 ;;
        libdrm.so*|libdrm_*.so*)           return 0 ;;
        libvulkan.so*|libvulkan_*.so*)     return 0 ;;
        libva.so*|libva-*.so*)             return 0 ;;
        libnvidia*.so*|libcuda*.so*|libnvcuvid*.so*) return 0 ;;

        # --- glibc + C++ Runtime + Loader ---
        libc.so*|libm.so*|libdl.so*|libpthread.so*) return 0 ;;
        librt.so*|libresolv.so*|libmvec.so*|libnsl.so*) return 0 ;;
        libutil.so*|libanl.so*|libcrypt.so*) return 0 ;;
        ld-linux*.so*|ld-*.so*)            return 0 ;;
        libstdc++.so*|libgcc_s.so*)        return 0 ;;

        # --- Windowing: Wayland ---
        libwayland-client.so*|libwayland-server.so*) return 0 ;;
        libwayland-cursor.so*|libwayland-egl.so*)    return 0 ;;

        # --- Windowing: X11 / XCB / XKB ---
        libX11.so*|libX11-xcb.so*|libXext.so*|libXrender.so*) return 0 ;;
        libXi.so*|libXss.so*|libXcursor.so*|libXrandr.so*)    return 0 ;;
        libXinerama.so*|libXfixes.so*|libXcomposite.so*)       return 0 ;;
        libXdamage.so*|libXtst.so*|libXau.so*|libXdmcp.so*)   return 0 ;;
        libxcb.so*|libxcb-util.so*|libxcb-icccm.so*)          return 0 ;;
        libxcb-image.so*|libxcb-keysyms.so*|libxcb-randr.so*) return 0 ;;
        libxcb-render*.so*|libxcb-shape.so*|libxcb-shm.so*)   return 0 ;;
        libxcb-sync.so*|libxcb-xfixes.so*|libxcb-xinerama.so*) return 0 ;;
        libxcb-xkb.so*|libxcb-cursor.so*|libxcb-dri*.so*)     return 0 ;;
        libxkbcommon.so*|libxkbcommon-x11.so*)                 return 0 ;;

        # --- GLib / GObject / GIO / DBus ---
        libglib-2.0.so*|libgobject-2.0.so*|libgio-2.0.so*)    return 0 ;;
        libgmodule-2.0.so*|libgthread-2.0.so*)                 return 0 ;;
        libdbus-1.so*|libdbus-glib*.so*)                       return 0 ;;

        # --- Fonts / System-Infrastruktur ---
        libfontconfig.so*|libfreetype.so*) return 0 ;;
        libexpat.so*|libp11-kit.so*)       return 0 ;;
        libudev.so*|libsystemd.so*)        return 0 ;;
        libmount.so*|libblkid.so*)         return 0 ;;

        *) return 1 ;;
    esac
}

collect_all_dependencies() {
    local binary="$1"
    local lib_dir="$2"
    local processed="$lib_dir/.processed_libs"

    [ -f "$processed" ] || touch "$processed"

    echo "Analysiere: $(basename "$binary")"

    _process() {
        local bin="$1"
        local libs=()
        while IFS= read -r line; do
            local lib
            lib=$(echo "$line" | grep "=>" | awk '{print $3}')
            [ -n "$lib" ] && [ -f "$lib" ] && libs+=("$lib")
        done < <(ldd "$bin" 2>/dev/null || true)

        for lib in "${libs[@]}"; do
            [ -f "$lib" ] || continue
            local libname
            libname="$(basename "$lib")"

            if is_excluded_lib "$libname"; then
                if ! grep -qxF "$lib" "$processed" 2>/dev/null; then
                    echo "$lib" >> "$processed"
                    echo "  - $libname (System/Host, nicht gebündelt)"
                fi
                continue
            fi

            grep -qxF "$lib" "$processed" 2>/dev/null && continue
            echo "$lib" >> "$processed"

            if [ ! -f "$lib_dir/$libname" ]; then
                cp -L "$lib" "$lib_dir/" 2>/dev/null && chmod +x "$lib_dir/$libname" \
                    && echo "  + $libname" || true
            fi
            _process "$lib"
        done
    }

    _process "$binary"
}

collect_all_dependencies "$APPDIR/usr/bin/pokerth_qml-client" "$APPDIR/usr/lib"
rm -f "$APPDIR/usr/lib/.processed_libs"

# --- Qt-Plugins ---

echo ""
echo "=== Sammle Qt-Plugins ==="
QT6_PLUGINS=$(find /usr/lib* -type d -name "qt6" -path "*/plugins" 2>/dev/null | head -1)
[ -z "$QT6_PLUGINS" ] && QT6_PLUGINS="/usr/lib/${ARCH}-linux-gnu/qt6/plugins"

if [ -d "$QT6_PLUGINS" ]; then
    echo "Qt6 Plugins: $QT6_PLUGINS"
    for cat in platforms xcbglintegrations platforminputcontexts wayland-shell-integration wayland-decoration-client wayland-graphics-integration-client imageformats iconengines platformthemes multimedia sqldrivers tls; do
        if [ -d "$QT6_PLUGINS/$cat" ]; then
            echo "  Kopiere $cat..."
            mkdir -p "$APPDIR/usr/plugins/$cat"
            cp "$QT6_PLUGINS/$cat"/*.so "$APPDIR/usr/plugins/$cat/" 2>/dev/null || true
            chmod +x "$APPDIR/usr/plugins/$cat"/*.so 2>/dev/null || true
            for plugin in "$APPDIR/usr/plugins/$cat"/*.so; do
                [ -f "$plugin" ] && collect_all_dependencies "$plugin" "$APPDIR/usr/lib"
            done
        fi
    done
    rm -f "$APPDIR/usr/lib/.processed_libs"
else
    echo "WARNUNG: Qt6 Plugins nicht gefunden!"
fi

# --- Qt-QML-Module (für den QtQuick/QML-Client zwingend nötig) ---

echo ""
echo "=== Sammle Qt-QML-Module ==="
QT6_QML=$(find /usr/lib* -type d -name "qml" -path "*/qt6/*" 2>/dev/null | head -1)
[ -z "$QT6_QML" ] && QT6_QML="/usr/lib/${ARCH}-linux-gnu/qt6/qml"

if [ -d "$QT6_QML" ]; then
    echo "Qt6 QML: $QT6_QML"
    for mod in QtCore QtQml QtQuick; do
        if [ -d "$QT6_QML/$mod" ]; then
            echo "  Kopiere Modul $mod ..."
            cp -r "$QT6_QML/$mod" "$APPDIR/usr/qml/"
        else
            echo "  WARNUNG: QML-Modul $mod nicht gefunden!"
        fi
    done
    while IFS= read -r qmlplugin; do
        [ -f "$qmlplugin" ] && collect_all_dependencies "$qmlplugin" "$APPDIR/usr/lib"
    done < <(find "$APPDIR/usr/qml" -name '*.so' 2>/dev/null)
    rm -f "$APPDIR/usr/lib/.processed_libs"
    echo "  QML-Module: $(find "$APPDIR/usr/qml" -maxdepth 1 -mindepth 1 -type d | wc -l)"
else
    echo "WARNUNG: Qt6-QML-Module nicht gefunden! Der QML-Client wird NICHT starten."
fi

# --- Data-Verzeichnis ---

echo ""
echo "=== Kopiere Data ==="
# getDataPathStdString() (qthelper.cpp) matched "bin/?$":
#   applicationDirPath() = usr/bin  →  data = usr/bin/../share/pokerth/data/
#                                             = usr/share/pokerth/data/
mkdir -p "$APPDIR/usr/share/pokerth"
if [ -d "$PROJECT_ROOT/data" ]; then
    cp -r "$PROJECT_ROOT/data" "$APPDIR/usr/share/pokerth/"
fi

# Lua-Script
[ -f "$PROJECT_ROOT/pokerth.lua" ] && cp "$PROJECT_ROOT/pokerth.lua" "$APPDIR/usr/share/pokerth/"

# --- qt.conf ---

echo ""
echo "=== Erstelle qt.conf ==="
cat > "$APPDIR/usr/bin/qt.conf" << 'EOF'
[Paths]
Plugins = ../plugins
Imports = ../qml
Qml2Imports = ../qml
Libraries = ../lib
EOF

# --- Desktop-Datei + Icon (AppImage-Pflicht) ---

echo "=== Erstelle Desktop-Datei und Icon ==="
cat > "$APPDIR/pokerth-qml.desktop" << 'EOF'
[Desktop Entry]
Name=PokerTH
GenericName=Poker Card Game
GenericName[de]=Pokerspiel
Comment=Texas hold'em game (QML client)
Comment[de]=Texas Hold'em Spiel (QML-Client)
Exec=pokerth_qml-client
Icon=pokerth
Terminal=false
Type=Application
Categories=Qt;Game;CardGame;
EOF

# Icon kopieren
if [ -f "$PROJECT_ROOT/pokerth.png" ]; then
    cp "$PROJECT_ROOT/pokerth.png" "$APPDIR/pokerth.png"
    mkdir -p "$APPDIR/usr/share/icons/hicolor/128x128/apps"
    cp "$PROJECT_ROOT/pokerth.png" "$APPDIR/usr/share/icons/hicolor/128x128/apps/pokerth.png"
else
    echo "WARNUNG: pokerth.png nicht gefunden, erstelle Platzhalter"
    printf '\x89PNG\r\n\x1a\n' > "$APPDIR/pokerth.png"
fi

# --- Lizenz & Docs ---

[ -f "$PROJECT_ROOT/COPYING" ]   && cp "$PROJECT_ROOT/COPYING"   "$APPDIR/"
[ -f "$PROJECT_ROOT/ChangeLog" ] && cp "$PROJECT_ROOT/ChangeLog" "$APPDIR/"
[ -d "$PROJECT_ROOT/docs" ]      && { mkdir -p "$APPDIR/usr/share/doc/pokerth"; cp -r "$PROJECT_ROOT/docs"/* "$APPDIR/usr/share/doc/pokerth/"; }

# --- AppRun erstellen ---

echo ""
echo "=== Erstelle AppRun ==="

cat > "$APPDIR/AppRun" << 'RUNEOF'
#!/bin/bash
# AppRun: Startet den PokerTH QML-Client.
# Konventioneller Ansatz — kein gebündeltes glibc / kein custom ld-linux.
# Der System-Loader wird verwendet; Host-GPU-Libs werden per LD_LIBRARY_PATH
# als Fallback hinter den gebündelten Qt-Libs eingehängt.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- AppImageLauncher-Erkennung ---
if [ -n "${APPIMAGE_LAUNCHER_VERSION:-}" ] || \
   [ -f /usr/lib/x86_64-linux-gnu/libappimage_launcher.so ] || \
   dpkg -l appimagelauncher &>/dev/null 2>&1; then
    echo "" >&2
    echo "=== WARNUNG: AppImageLauncher erkannt! ===" >&2
    echo "AppImageLauncher kann FUSE-Fehler verursachen." >&2
    echo "Loesung: AppImageLauncher deinstallieren:" >&2
    echo "  sudo apt remove appimagelauncher" >&2
    echo "Oder PokerTH direkt starten mit:" >&2
    echo "  APPIMAGE_EXTRACT_AND_RUN=1 ${APPIMAGE:-$0}" >&2
    echo "=============================================" >&2
    echo "" >&2
fi

# PokerTH AppImage Marker — wird im C++ Code via AppImageUtils geprüft
export POKERTH_APPIMAGE=1

# Originale LD_LIBRARY_PATH sichern BEVOR wir sie modifizieren.
# AppImageUtils::cleanProcessEnvironment() stellt diesen Wert wieder her,
# damit externe Prozesse (xdg-open, paplay, etc.) die System-Libs nutzen.
export POKERTH_ORIG_LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"

# Gebündelte Qt-Libs zuerst, System-Libs als Fallback (für GPU-Treiber etc.)
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="${HERE}/usr/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="${HERE}/usr/plugins/platforms"
export QML_IMPORT_PATH="${HERE}/usr/qml"
export QML2_IMPORT_PATH="${HERE}/usr/qml"
export QT_MEDIA_BACKEND=ffmpeg
export XDG_DATA_DIRS="${HERE}/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

exec "${HERE}/usr/bin/pokerth_qml-client" "$@"
RUNEOF
chmod +x "$APPDIR/AppRun"

# --- AppImage erstellen ---

echo ""
echo "=== Erstelle AppImage ==="
cd "$SCRIPT_DIR"

export ARCH
"$APPIMAGETOOL" --appimage-extract-and-run "$APPDIR" "$APPIMAGE_NAME" \
    || { echo "Versuche appimagetool mit --no-appstream..."; \
         "$APPIMAGETOOL" --appimage-extract-and-run --no-appstream "$APPDIR" "$APPIMAGE_NAME"; }

echo ""
echo "=== Zusammenfassung ==="
echo "AppImage erstellt:    ${SCRIPT_DIR}/${APPIMAGE_NAME}"
ls -lh "${SCRIPT_DIR}/${APPIMAGE_NAME}" 2>/dev/null || true
echo ""
echo "Anzahl Bibliotheken:  $(find "$APPDIR/usr/lib" -name '*.so*' | wc -l)"
echo "QML-Module:           $(find "$APPDIR/usr/qml" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)"
echo "Gesamtgröße AppDir:   $(du -sh "$APPDIR" | cut -f1)"
echo ""

if [ -d "$APPDIR/usr/qml/QtQuick" ]; then
    echo "✓ Qt-QML-Module gebündelt (QtQuick vorhanden)."
else
    echo "⚠ Qt-QML-Module fehlen — der QML-Client wird nicht starten!"
fi

if [ -d "$APPDIR/usr/share/pokerth/data" ]; then
    echo "✓ Data-Verzeichnis vorhanden (usr/share/pokerth/data)."
else
    echo "⚠ Data-Verzeichnis fehlt!"
fi

echo ""
echo "=== Fertig! ==="
echo ""
echo "Test:"
echo "  chmod +x ${APPIMAGE_NAME}"
echo "  ./${APPIMAGE_NAME}"
echo ""
echo "Oder ohne FUSE (z.B. in Docker/WSL):"
echo "  ./${APPIMAGE_NAME} --appimage-extract-and-run"
echo ""
echo "=== Troubleshooting ==="
echo ""
echo "Problem: 'module \"QtQuick\" is not installed' o.ä.:"
echo "  → qt6-declarative (QML-Module) muss auf dem Build-System installiert sein."
echo ""
echo "Problem: 'fuse: memory allocation failed' / FUSE-Fehler:"
echo "  1. AppImageLauncher deinstallieren: sudo apt remove appimagelauncher"
echo "  2. libfuse2 installieren: sudo apt install libfuse2"
echo "  3. Alternativ: APPIMAGE_EXTRACT_AND_RUN=1 ./${APPIMAGE_NAME}"
echo ""
echo "Problem: 'EGL not available' / OpenGL-Fehler:"
echo "  → Mesa/GPU-Treiber auf dem Zielsystem prüfen:"
echo "     sudo apt install libgl1-mesa-dri libegl-mesa0"
