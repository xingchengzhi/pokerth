#!/bin/bash
# PokerTH QML-Client Headless-Demo: Screenshots + Video
# Portrait-Modus (390×844)
# Flow: Startseite → Einstellungen → Internet-Login → Lobby (als Gast)
#
# Fenster bei 600×1000 Xvfb zentriert auf (105, 78) per QML-Formel:
#   x = screenWidth/2 - 390/2 = 300 - 195 = 105
#   y = screenHeight/2 - 844/2 = 500 - 422 = 78
#
# Relative Click-Offsets (vom Client-Topleft):
#   "Internetspiel": x+195, y+349  (StartPage-Button)
#   "Continue as Guest": x+195, y+507 (ServerConnectionDialog)
#
# Tastenkürzel (in pokerth.qml implementiert):
#   Alt+S  → Einstellungen öffnen (wenn auf Startseite)
#   Escape → Zurück / SideMenu schließen
#   Alt+←  → Zurück (StandardKey.Back)
#
# HINWEIS: TopBar-Klicks (y+0..y+38) reagieren nicht auf XTEST (Qt6/XCB-Bug).
#          Navigation erfolgt daher über Tastenkürzel.
#
# Benötigte apt-Pakete (einmalig installieren):
#   sudo apt install xvfb openbox ffmpeg scrot xdotool

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DISPLAY_NUM=98
DISPLAY_RES="600x1000"
BINARY="/opt/pokerth_env/repos/pokerth-test/build/bin/pokerth_qml-client"
OUTPUT_DIR="${SCRIPT_DIR}/screenshots_qml"
VIDEO_FILE="${SCRIPT_DIR}/pokerth_qml_demo.mp4"
export DISPLAY=":${DISPLAY_NUM}"

mkdir -p "$OUTPUT_DIR"
rm -f "${OUTPUT_DIR}"/0*.png

# ── Hilfsfunktion: Vollbild-Screenshot ─────────────────────────────────────────
shot() {
    local label="$1"
    local out="${OUTPUT_DIR}/${label}"
    sleep 0.8
    DISPLAY=":${DISPLAY_NUM}" scrot "$out"
    echo "      Screenshot → $out"
}

# ── Hilfsfunktion: Klick mit Verzögerung ───────────────────────────────────────
click_at() {
    local x="$1"
    local y="$2"
    local desc="${3:-}"
    echo "      Klick bei (${x}, ${y}) ${desc}"
    DISPLAY=":${DISPLAY_NUM}" xdotool mousemove "$x" "$y"
    sleep 0.1
    DISPLAY=":${DISPLAY_NUM}" xdotool click 1
}

# ── Cleanup ─────────────────────────────────────────────────────────────────────
cleanup() {
    echo "[cleanup] Beende alle Prozesse ..."
    kill "${POKERTH_PID:-}" 2>/dev/null || true
    sleep 1
    if [ -n "${FFMPEG_PID:-}" ]; then
        kill -INT "$FFMPEG_PID" 2>/dev/null || true
        wait "$FFMPEG_PID" 2>/dev/null || true
    fi
    kill "${WM_PID:-}" 2>/dev/null || true
    kill "${XVFB_PID:-}" 2>/dev/null || true
}
trap cleanup EXIT

# ── Xvfb ───────────────────────────────────────────────────────────────────────
echo "[1/8] Starte Xvfb :${DISPLAY_NUM} (${DISPLAY_RES}x24) ..."
Xvfb ":${DISPLAY_NUM}" -screen 0 "${DISPLAY_RES}x24" -ac &
XVFB_PID=$!
sleep 1

# ── Window-Manager ─────────────────────────────────────────────────────────────
echo "[2/8] Starte openbox ..."
DISPLAY=":${DISPLAY_NUM}" openbox &
WM_PID=$!
sleep 1

# ── ffmpeg-Aufnahme ─────────────────────────────────────────────────────────────
echo "[3/8] Starte ffmpeg-Aufnahme → ${VIDEO_FILE} ..."
ffmpeg -f x11grab \
    -video_size "${DISPLAY_RES}" \
    -framerate 15 \
    -i ":${DISPLAY_NUM}" \
    -c:v libx264 -preset fast -crf 23 \
    -y "${VIDEO_FILE}" \
    > "${SCRIPT_DIR}/ffmpeg_qml.log" 2>&1 &
FFMPEG_PID=$!
sleep 1

# ── QML-Client starten ─────────────────────────────────────────────────────────
echo "[4/8] Starte QML-Client ..."
# Config-LoginMode für konsistente Tab-Navigation zurücksetzen (irrelevant für
# QML-Client, aber schadet nicht)
if [ -f ~/.pokerth/config.xml ]; then
    sed -i 's|<InternetLoginMode value="[0-9]*"/>|<InternetLoginMode value="0"/>|' ~/.pokerth/config.xml
fi
DISPLAY=":${DISPLAY_NUM}" "${BINARY}" > "${SCRIPT_DIR}/pokerth_qml.log" 2>&1 &
POKERTH_PID=$!

# ── Auf Startfenster warten ─────────────────────────────────────────────────────
echo "      Warte auf QML-Startfenster ..."
WIN_ID=""
for i in $(seq 1 40); do
    WIN_ID=$(DISPLAY=":${DISPLAY_NUM}" xdotool search --onlyvisible --name "PokerTH" 2>/dev/null | head -1 || true)
    [ -n "$WIN_ID" ] && break
    sleep 1
    echo "      ... $i/40"
done

if [ -z "$WIN_ID" ]; then
    echo "[FEHLER] QML-Fenster nicht gefunden!"
    DISPLAY=":${DISPLAY_NUM}" scrot "${OUTPUT_DIR}/debug_no_window.png" || true
    exit 1
fi

# Fensterposition dynamisch ermitteln
GEOM=$(DISPLAY=":${DISPLAY_NUM}" xdotool getwindowgeometry "$WIN_ID" 2>/dev/null)
WX=$(echo "$GEOM" | grep "Position:" | grep -oP '\d+(?=,)')
WY=$(echo "$GEOM" | grep "Position:" | grep -oP '(?<=,)\d+')
echo "      Fenster-ID: ${WIN_ID}  Position: ${WX},${WY}  – Warte 8s (PreLoader: 5s) ..."
sleep 8

# Fenster fokussieren (nötig für Tastenkürzel)
DISPLAY=":${DISPLAY_NUM}" xdotool windowfocus "$WIN_ID"
sleep 0.3

# Klick-Koordinaten berechnen (relativ zu Client-Topleft)
INTERNET_X=$(( WX + 195 )) # "Internetspiel"-Button
INTERNET_Y=$(( WY + 349 ))
GUEST_X=$(( WX + 195 ))    # "Continue as Guest"-Button
GUEST_Y=$(( WY + 507 ))

# ── Screenshot 1: Startseite ───────────────────────────────────────────────────
echo ""
echo "[5/8] Screenshot 1: Startseite (Portrait)"
shot "01_startseite.png"

# ── Einstellungen öffnen via Alt+S ───────────────────────────────────────────
echo ""
echo "      Öffne Einstellungen (Alt+S) ..."
DISPLAY=":${DISPLAY_NUM}" xdotool key --window "$WIN_ID" --clearmodifiers alt+s
sleep 2

# Screenshot 2: Einstellungen
echo "      Screenshot 2: Einstellungen-Seite"
shot "02_einstellungen.png"
sleep 1

# Zurück zur Startseite (Escape)
echo "      Zurück via Escape ..."
DISPLAY=":${DISPLAY_NUM}" xdotool key --window "$WIN_ID" --clearmodifiers Escape
sleep 1.5

# ── Internetspiel → ServerConnectionDialog ─────────────────────────────────────
echo ""
echo "[6/8] Klicke 'Internetspiel' bei (${INTERNET_X},${INTERNET_Y}) ..."
click_at "$INTERNET_X" "$INTERNET_Y" "(Internetspiel)"
sleep 2

# Screenshot 3: Server-Connection-Dialog
echo "      Screenshot 3: Internet-Login-Auswahl"
shot "03_login.png"

# ── Als Gast verbinden ─────────────────────────────────────────────────────────
echo ""
echo "[7/8] Klicke 'Continue as Guest' bei (${GUEST_X},${GUEST_Y}) ..."
click_at "$GUEST_X" "$GUEST_Y" "(Continue as Guest)"
echo "      Warte auf Lobby-Verbindung (10s) ..."
sleep 10

# Screenshot 4: Lobby
echo "[8/8] Screenshot 4: Lobby"
shot "04_lobby.png"
sleep 5  # Lobby im Video zeigen

# ── Aufnahme beenden ────────────────────────────────────────────────────────────
echo ""
echo "      Beende ffmpeg-Aufnahme ..."
kill -INT "$FFMPEG_PID" 2>/dev/null || true
wait "$FFMPEG_PID" 2>/dev/null || true
unset FFMPEG_PID

# ── Zusammenfassung ─────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "║    PokerTH QML-Demo – Fertig         ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Screenshots:"
ls -lh "${OUTPUT_DIR}"/0*.png 2>/dev/null || echo "  (keine)"
echo ""
if [ -f "${VIDEO_FILE}" ]; then
    VIDEO_SIZE=$(du -sh "${VIDEO_FILE}" | cut -f1)
    VIDEO_DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "${VIDEO_FILE}" 2>/dev/null | awk '{printf "%.1fs", $1}' || echo "?")
    echo "Video: ${VIDEO_FILE}"
    echo "  Größe: ${VIDEO_SIZE}  Dauer: ${VIDEO_DUR}"
else
    echo "Video: nicht erstellt (Log: ${SCRIPT_DIR}/ffmpeg_qml.log)"
fi
