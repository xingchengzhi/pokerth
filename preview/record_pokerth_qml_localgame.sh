#!/bin/bash
# PokerTH QML-Client – Lokales Spiel Preview
# Flow: Startseite → Lokales Spiel starten → 1 Hand spielen (CALL/RAISE) → zurück zur Startseite
#
# Benötigte apt-Pakete:
#   sudo apt install xvfb openbox ffmpeg scrot xdotool
#
# Alle Koordinaten kalibriert per Screenshot-Analyse auf Fenstergröße 390×844
# (WM-Deko: top=20px → xdotool WY = Client-Content-Top)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DISPLAY_NUM=99
DISPLAY_RES="600x1000"
BINARY="/opt/pokerth_env/repos/pokerth-test/build/bin/pokerth_qml-client"
OUTPUT_DIR="${SCRIPT_DIR}/screenshots_localgame"
VIDEO_FILE="${SCRIPT_DIR}/pokerth_qml_localgame_demo.mp4"
export DISPLAY=":${DISPLAY_NUM}"

mkdir -p "$OUTPUT_DIR"
rm -f "${OUTPUT_DIR}"/*.png

# ── Reste vom letzten Lauf bereinigen ─────────────────────────────────────────
echo "[0/5] Bereinige Reste vom letzten Lauf ..."
pkill -f "pokerth_qml-client" 2>/dev/null || true
pkill -f "Xvfb :${DISPLAY_NUM}"  2>/dev/null || true
pkill -f "openbox"               2>/dev/null || true
sleep 1

# ── Hilfsfunktionen ───────────────────────────────────────────────────────────
shot() {
    local file="${OUTPUT_DIR}/$1"
    sleep 0.8
    DISPLAY=":${DISPLAY_NUM}" scrot -p "$file"
    echo "      Screenshot → $file"
    DISPLAY=":${DISPLAY_NUM}" xdotool windowfocus "${WIN_ID:-}" 2>/dev/null || true
    sleep 0.1
}

click_at() {
    local x="$1" y="$2" desc="${3:-}"
    echo "      Klick (${x}, ${y}) ${desc}"
    DISPLAY=":${DISPLAY_NUM}" xdotool mousemove --sync "$x" "$y"
    sleep 0.2
    DISPLAY=":${DISPLAY_NUM}" xdotool click --clearmodifiers 1
}

# ── Cleanup ───────────────────────────────────────────────────────────────────
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
echo "[1/5] Starte Xvfb :${DISPLAY_NUM} (${DISPLAY_RES}x24) ..."
Xvfb ":${DISPLAY_NUM}" -screen 0 "${DISPLAY_RES}x24" -ac &
XVFB_PID=$!
sleep 1

# ── Window-Manager ────────────────────────────────────────────────────────────
echo "[2/5] Starte openbox ..."
DISPLAY=":${DISPLAY_NUM}" openbox &
WM_PID=$!
sleep 1

# ── ffmpeg-Aufnahme ───────────────────────────────────────────────────────────
echo "[3/5] Starte ffmpeg-Aufnahme → ${VIDEO_FILE} ..."
ffmpeg -f x11grab \
    -video_size "${DISPLAY_RES}" \
    -framerate 15 \
    -i ":${DISPLAY_NUM}" \
    -c:v libx264 -preset fast -crf 23 \
    -pix_fmt yuv420p \
    -profile:v baseline -level 3.1 \
    -movflags +faststart \
    -y "${VIDEO_FILE}" \
    > "${SCRIPT_DIR}/ffmpeg_localgame.log" 2>&1 &
FFMPEG_PID=$!
sleep 1

# ── QML-Client starten ────────────────────────────────────────────────────────
echo "[4/5] Starte QML-Client ..."
DISPLAY=":${DISPLAY_NUM}" "${BINARY}" > "${SCRIPT_DIR}/pokerth_localgame.log" 2>&1 &
POKERTH_PID=$!

# ── Auf Startfenster warten ───────────────────────────────────────────────────
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
echo "      Fenster ${WIN_ID}: Position=${WX},${WY} – Warte 8s (PreLoader) ..."
sleep 8

DISPLAY=":${DISPLAY_NUM}" xdotool windowfocus "$WIN_ID"
sleep 0.3

# ── Koordinaten (kalibriert per Screenshot-Analyse) ───────────────────────────
#   Fenster: 390×844 Client-Bereich (ohne WM-Deko)
#   WM-Deko: _NET_FRAME_EXTENTS = 1,1,20,5 → xdotool WY = Client-Content-Top
#
#   StartPage (compact=true, margin=12, spacing=8, buttonHeight=48):
#     TopBar: height=38 → Buttons ab WY+38
#     Button 1 (Internet):        WY+349  (ColumnLayout-Offset)
#     Button 2 (Lokales Spiel):   WY+405  (WY+349 + 8spacing + 48height → +405)
#
#   LocalGamePage:
#     "Spiel starten" (rechter RowLayout-Button, Mitte):  WX+288, WY+671
#
#   GamePage (compact=true):
#     ActionBar: Trennbalken bei WY+770, Buttons-Mitte WY+789
#     FOLD:  WX+68   (margin=8 + halbe Breite ~60px)
#     CALL:  WX+195  (Fenstermitte)
#     RAISE: WX+322  (Spiegelung von FOLD)
#
#   TopBar-Tür-Icon (zurück, nur wenn StackView.depth > 1):
#     WX+19, WY+19   (margin=6 + Icon-Zentrum in 38px-Bar)

LOKALGAME_X=$(( WX + 195 ))
LOKALGAME_Y=$(( WY + 405 ))

SPIELSTART_X=$(( WX + 288 ))
SPIELSTART_Y=$(( WY + 671 ))

DOOR_X=$(( WX + 19 ))
DOOR_Y=$(( WY + 19 ))

FOLD_X=$(( WX + 68 ))
CALL_X=$(( WX + 195 ))
RAISE_X=$(( WX + 322 ))
ACTION_Y=$(( WY + 789 ))    # Kalibriert: Buttons-Mitte ohne Raise-Controls

# 50%-Pot-Button (nur sichtbar wenn Spieler am Zug & Raise möglich)
# Wenn Raise-Controls sichtbar, verschiebt sich die ActionBar um 66px nach oben:
#   ActionBar-Top: WY+765→WY+699, Buttons-Mitte: WY+792
# raiseSection: topPad=5, Slider=26, spacing=4, Row=28 → "1/2"-Button-Mitte WY+748
HALF_POT_X=$(( WX + 151 ))   # leftPad(8) + textInput(78) + gap(4) + 1/3-btn(38) + gap(4) + halbe38=19
HALF_POT_Y=$(( WY + 748 ))   # raiseSection-Top(WY+699) + topPad(5) + Slider(26) + gap(4) + halbeRow(14)
RAISE_ACTIVE_Y=$(( WY + 792 )) # RAISE-Button-Mitte wenn raiseSection sichtbar

echo "      DEBUG: WX=${WX} WY=${WY}"
echo "             LokalesSpiel=(${LOKALGAME_X},${LOKALGAME_Y})"
echo "             SpielStarten=(${SPIELSTART_X},${SPIELSTART_Y})"
echo "             Door=(${DOOR_X},${DOOR_Y})"
echo "             FOLD=(${FOLD_X},${ACTION_Y})  CALL=(${CALL_X},${ACTION_Y})  RAISE=(${RAISE_X},${ACTION_Y})"
echo "             1/2-Pot=(${HALF_POT_X},${HALF_POT_Y})  RAISE-aktiv=(${RAISE_X},${RAISE_ACTIVE_Y})"

# ── Demo-Flow ─────────────────────────────────────────────────────────────────
echo ""
echo "[5/5] Demo-Flow ..."

# 1. Startseite screenshotten
shot "01_startseite.png"

# 2. Lokales Spiel starten → LocalGamePage
click_at "$LOKALGAME_X" "$LOKALGAME_Y" "(Lokales Spiel starten)"
sleep 2
shot "02_localgame_settings.png"

# 3. Spiel starten mit Standardeinstellungen (10 Spieler, 5000 Startkapital)
click_at "$SPIELSTART_X" "$SPIELSTART_Y" "(Spiel starten)"
echo "      Warte auf GamePage (6s) ..."
sleep 6
shot "03_gamepage_preflop.png"

# 4. Hand 1 – Spielverlauf
#    Runde 1, 2, 4: CALL (kein Effekt wenn nicht am Zug)
#    Runde 3:       1/2-Pot + RAISE (kein Effekt wenn nicht am Zug oder kein Raise möglich)
echo "      Hand 1 – Spielverlauf ..."

# Runde 1 – CALL
sleep 10
click_at "$CALL_X" "$ACTION_Y" "(CALL Runde 1)"
shot "04_hand1_runde1.png"

# Runde 2 – CALL
sleep 10
click_at "$CALL_X" "$ACTION_Y" "(CALL Runde 2)"
shot "04_hand1_runde2.png"

# Runde 3 – 1/2-Pot setzen, dann RAISE
#   Wenn Spieler gerade an der Reihe ist und Raise-Controls sichtbar:
#     1/2-Klick → setzt raiseAmount auf halben Pot → RAISE klicken
#   Sonst: Klicks landen auf Spieltisch (kein Effekt)
sleep 10
echo "      Runde 3: 1/2-Pot + RAISE versuchen ..."
click_at "$HALF_POT_X" "$HALF_POT_Y" "(1/2-Pot Button)"
sleep 0.5
click_at "$RAISE_X" "$RAISE_ACTIVE_Y" "(RAISE)"
shot "04_hand1_runde3.png"

# Runde 4 – CALL
sleep 10
click_at "$CALL_X" "$ACTION_Y" "(CALL Runde 4)"
shot "04_hand1_runde4.png"

# 5. Zurück zur Startseite:
#    1. Escape → mainStackView.pop() → GamePage verlassen → LocalGamePage
#    2. Escape → mainStackView.pop() → LocalGamePage verlassen → StartPage
echo "      Zurück zur Startseite ..."
sleep 2
echo "      Escape (GamePage verlassen) ..."
DISPLAY=":${DISPLAY_NUM}" xdotool key Escape
sleep 2
shot "06_localgame_page_back.png"

echo "      Escape (LocalGamePage verlassen) ..."
DISPLAY=":${DISPLAY_NUM}" xdotool key Escape
sleep 2
shot "07_startseite_final.png"

# ── Aufnahme beenden ──────────────────────────────────────────────────────────
echo ""
echo "      Beende ffmpeg ..."
kill -INT "$FFMPEG_PID" 2>/dev/null || true
wait "$FFMPEG_PID" 2>/dev/null || true
unset FFMPEG_PID

# ── Zusammenfassung ───────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   PokerTH QML – Lokales Spiel Demo – Fertig!    ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "Screenshots:"
ls -lh "${OUTPUT_DIR}"/*.png 2>/dev/null || echo "  (keine)"
echo ""
if [ -f "${VIDEO_FILE}" ]; then
    VIDEO_SIZE=$(du -sh "${VIDEO_FILE}" | cut -f1)
    VIDEO_DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "${VIDEO_FILE}" 2>/dev/null \
        | awk '{printf "%.1fs", $1}' || echo "?")
    echo "Video:  ${VIDEO_FILE}"
    echo "Größe:  ${VIDEO_SIZE}  Länge: ${VIDEO_DUR}"
fi
echo ""
