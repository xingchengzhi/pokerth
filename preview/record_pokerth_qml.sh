#!/bin/bash
# PokerTH QML-Client Headless-Demo: Screenshots + Video
# Portrait-Modus (390×844)
# Flow: Startseite → Einstellungen (alle 9 Pages) → Zurück → Internet-Login → Lobby (als Gast)
#
# Fensterlayout (compact=true, da windowWidth=390 < 600):
#   TopBar:              y+0  .. y+37  (38px)  – kein XTEST (Qt6/XCB-Bug)
#   compactCategoryStrip y+38 .. y+85  (48px)  – 9 Settings-Icons
#   Settings-Inhalt:     y+86 .. y+843
#
#   9 Icons à 390/9≈43px; Mitte von Icon i = x + 43*i + 21
#
# Benötigte apt-Pakete:
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
rm -f "${OUTPUT_DIR}"/*.png

# ── Reste vom letzten Lauf bereinigen ─────────────────────────────────────────
echo "[0/6] Bereinige Reste vom letzten Lauf ..."
pkill -f "pokerth_qml-client" 2>/dev/null || true
pkill -f "Xvfb :${DISPLAY_NUM}"  2>/dev/null || true
pkill -f "openbox"               2>/dev/null || true
sleep 1

# ── Hilfsfunktionen ────────────────────────────────────────────────────────────
shot() {
    local file="${OUTPUT_DIR}/$1"
    sleep 0.8
    DISPLAY=":${DISPLAY_NUM}" scrot "$file"
    echo "      Screenshot → $file"
}

click_at() {
    local x="$1" y="$2" desc="${3:-}"
    echo "      Klick (${x}, ${y}) ${desc}"
    DISPLAY=":${DISPLAY_NUM}" xdotool mousemove "$x" "$y"
    sleep 0.15
    DISPLAY=":${DISPLAY_NUM}" xdotool click 1
}

# ── Cleanup ────────────────────────────────────────────────────────────────────
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

# ── Xvfb ──────────────────────────────────────────────────────────────────────
echo "[1/6] Starte Xvfb :${DISPLAY_NUM} (${DISPLAY_RES}x24) ..."
Xvfb ":${DISPLAY_NUM}" -screen 0 "${DISPLAY_RES}x24" -ac &
XVFB_PID=$!
sleep 1

# ── Window-Manager ─────────────────────────────────────────────────────────────
echo "[2/6] Starte openbox ..."
DISPLAY=":${DISPLAY_NUM}" openbox &
WM_PID=$!
sleep 1

# ── ffmpeg-Aufnahme ────────────────────────────────────────────────────────────
echo "[3/6] Starte ffmpeg-Aufnahme → ${VIDEO_FILE} ..."
ffmpeg -f x11grab \
    -video_size "${DISPLAY_RES}" \
    -framerate 15 \
    -i ":${DISPLAY_NUM}" \
    -c:v libx264 -preset fast -crf 23 \
    -pix_fmt yuv420p \
    -profile:v baseline -level 3.1 \
    -movflags +faststart \
    -y "${VIDEO_FILE}" \
    > "${SCRIPT_DIR}/ffmpeg_qml.log" 2>&1 &
FFMPEG_PID=$!
sleep 1

# ── QML-Client starten ─────────────────────────────────────────────────────────
echo "[4/6] Starte QML-Client ..."
if [ -f ~/.pokerth/config.xml ]; then
    sed -i 's|<InternetLoginMode value="[0-9]*"/>|<InternetLoginMode value="0"/>|' ~/.pokerth/config.xml
fi
DISPLAY=":${DISPLAY_NUM}" "${BINARY}" > "${SCRIPT_DIR}/pokerth_qml.log" 2>&1 &
POKERTH_PID=$!

# ── Auf Startfenster warten ────────────────────────────────────────────────────
echo "      Warte auf QML-Fenster ..."
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

GEOM=$(DISPLAY=":${DISPLAY_NUM}" xdotool getwindowgeometry "$WIN_ID" 2>/dev/null)
WX=$(echo "$GEOM" | grep "Position:" | grep -oP '\d+(?=,)')
WY=$(echo "$GEOM" | grep "Position:" | grep -oP '(?<=,)\d+')
echo "      Fenster ${WIN_ID}: Position=${WX},${WY}  – Warte 8s (PreLoader 5s) ..."
sleep 8

DISPLAY=":${DISPLAY_NUM}" xdotool windowfocus "$WIN_ID"
sleep 0.3

# ── Koordinaten ────────────────────────────────────────────────────────────────
APP_W=390
N_TABS=9
TAB_W=$(( APP_W / N_TABS ))        # 43 px je Icon
STRIP_CY=$(( WY + 38 + 24 ))       # Mitte compactCategoryStrip (WY+62)
INTERNET_X=$(( WX + 195 ))
INTERNET_Y=$(( WY + 349 ))
GUEST_X=$(( WX + 195 ))
GUEST_Y=$(( WY + 507 ))

# Settings-Labels (für Dateinamen, Index 0-8)
SETTINGS_NAMES=(
    "gui"
    "stil"
    "sound"
    "lokales-spiel"
    "netzwerkspiel"
    "internetspiel"
    "nicknamen-avatare"
    "log-nachrichten"
    "reset"
)

# ── Screenshot 01: Startseite ──────────────────────────────────────────────────
echo ""
echo "[5/6] Demo-Flow ..."
shot "01_startseite.png"

# ── Einstellungen öffnen (Alt+S) ───────────────────────────────────────────────
echo "      Einstellungen öffnen (Alt+S) ..."
DISPLAY=":${DISPLAY_NUM}" xdotool key --window "$WIN_ID" --clearmodifiers alt+s
sleep 1.5

# ── Alle 9 Settings-Pages durchklicken ────────────────────────────────────────
echo "      Durchklicke alle ${N_TABS} Settings-Pages ..."
for i in $(seq 0 $(( N_TABS - 1 ))); do
    ICON_X=$(( WX + TAB_W * i + TAB_W / 2 ))
    NAME="${SETTINGS_NAMES[$i]}"
    NUM=$(printf '%02d' $(( i + 2 )))
    click_at "$ICON_X" "$STRIP_CY" "[${i}] ${NAME}"
    sleep 1.5
    shot "${NUM}_settings_${NAME}.png"
done

# ── Zurück zur Startseite ──────────────────────────────────────────────────────
echo "      Zurück via Escape ..."
DISPLAY=":${DISPLAY_NUM}" xdotool key --window "$WIN_ID" --clearmodifiers Escape
sleep 1.5

# ── Internetspiel → Login ──────────────────────────────────────────────────────
echo ""
echo "[6/6] Internetspiel → Lobby als Gast ..."
click_at "$INTERNET_X" "$INTERNET_Y" "(Internetspiel)"
sleep 2
shot "11_login.png"

click_at "$GUEST_X" "$GUEST_Y" "(Continue as Guest)"
echo "      Warte auf Lobby (10s) ..."
sleep 10
shot "12_lobby.png"
sleep 3

# ── Aufnahme beenden ───────────────────────────────────────────────────────────
echo ""
echo "      Beende ffmpeg ..."
kill -INT "$FFMPEG_PID" 2>/dev/null || true
wait "$FFMPEG_PID" 2>/dev/null || true
unset FFMPEG_PID

# ── Zusammenfassung ────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "║    PokerTH QML-Demo – Fertig         ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Screenshots:"
ls -lh "${OUTPUT_DIR}"/*.png 2>/dev/null || echo "  (keine)"
echo ""
if [ -f "${VIDEO_FILE}" ]; then
    VIDEO_SIZE=$(du -sh "${VIDEO_FILE}" | cut -f1)
    VIDEO_DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "${VIDEO_FILE}" 2>/dev/null \
        | awk '{printf "%.1fs", $1}' || echo "?")
    echo "Video: ${VIDEO_FILE}"
    echo "  Größe: ${VIDEO_SIZE}  Dauer: ${VIDEO_DUR}"
else
    echo "Video: nicht erstellt (Log: ${SCRIPT_DIR}/ffmpeg_qml.log)"
fi
