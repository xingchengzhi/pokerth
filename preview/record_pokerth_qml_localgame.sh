#!/bin/bash
# PokerTH QML-Client – Lokales Spiel Preview
# Flow: Startseite → Lokales Spiel starten → 2 Hände spielen
#       → kurz in Hand 3 anlaufen lassen → zurück zur Startseite
#
# Benötigte apt-Pakete:
#   sudo apt install xvfb openbox ffmpeg scrot xdotool pulseaudio pulseaudio-utils
#
# Desktop-Aufnahme auf 1440er Breite, Spiel startet im Portrait-Fenster.
# Im Spiel wird dann alle 20s zwischen Portrait und Fullscreen gewechselt.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DISPLAY_NUM=99
DESKTOP_W=1440
DESKTOP_H=900
DISPLAY_RES="${DESKTOP_W}x${DESKTOP_H}"
PORTRAIT_W=390
PORTRAIT_H=844
MODE_TOGGLE_INTERVAL=20
BINARY="/opt/pokerth_env/repos/pokerth-test/build/bin/pokerth_qml-client"
OUTPUT_DIR="${SCRIPT_DIR}/screenshots_localgame"
VIDEO_FILE="${SCRIPT_DIR}/pokerth_qml_localgame_demo.mp4"
export DISPLAY=":${DISPLAY_NUM}"

AUDIO_ENABLED=0
AUDIO_SOURCE=""
AUDIO_RUNTIME_DIR=""
AUDIO_SYNC_DELAY_MS=1200
GAME_MODE_TOGGLE_ACTIVE=0
CURRENT_VIEW_MODE="portrait"
NEXT_MODE_SWITCH_AT=0
WX=0
WY=0
WW=0
WH=0

# Preview-Aufnahme soll möglichst nah an der UI-Aktion bleiben.
# Der Pulse-Monitor der virtuellen Null-Sink hat sonst standardmäßig sehr hohe
# Puffer/Latenz, was den Ton im Video sichtbar hinter die Aktion schiebt.
export PULSE_LATENCY_MSEC=60

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

wait_preview() {
    local seconds="$1"
    local remaining=$seconds

    echo "      Warte ${seconds}s ..."
    while [ "$remaining" -gt 0 ]; do
        if [ "$GAME_MODE_TOGGLE_ACTIVE" -eq 1 ] && [ "$SECONDS" -ge "$NEXT_MODE_SWITCH_AT" ]; then
            toggle_view_mode
            NEXT_MODE_SWITCH_AT=$((SECONDS + MODE_TOGGLE_INTERVAL))
            continue
        fi

        local chunk=$remaining
        if [ "$GAME_MODE_TOGGLE_ACTIVE" -eq 1 ]; then
            local until_switch=$((NEXT_MODE_SWITCH_AT - SECONDS))
            if [ "$until_switch" -lt "$chunk" ]; then
                chunk=$until_switch
            fi
        fi

        if [ "$chunk" -le 0 ]; then
            chunk=1
        fi

        sleep "$chunk"
        remaining=$((remaining - chunk))
    done
}

refresh_window_geometry() {
    local geom
    geom=$(DISPLAY=":${DISPLAY_NUM}" xdotool getwindowgeometry --shell "$WIN_ID" 2>/dev/null)
    eval "$geom"
    WX=$X
    WY=$Y
    WW=$WIDTH
    WH=$HEIGHT
}

update_click_coords() {
    refresh_window_geometry

    LOKALGAME_X=$(( WX + (WW * 195 / 390) ))
    LOKALGAME_Y=$(( WY + (WH * 405 / 844) ))

    SPIELSTART_X=$(( WX + (WW * 288 / 390) ))
    SPIELSTART_Y=$(( WY + (WH * 671 / 844) ))

    DOOR_X=$(( WX + (WW * 19 / 390) ))
    DOOR_Y=$(( WY + (WH * 19 / 844) ))

    FOLD_X=$(( WX + (WW * 68 / 390) ))
    CALL_X=$(( WX + (WW * 195 / 390) ))
    RAISE_X=$(( WX + (WW * 322 / 390) ))
    ACTION_Y=$(( WY + (WH * 789 / 844) ))

    HALF_POT_X=$(( WX + (WW * 151 / 390) ))
    HALF_POT_Y=$(( WY + (WH * 748 / 844) ))
    RAISE_ACTIVE_Y=$(( WY + (WH * 792 / 844) ))
}

apply_portrait_mode() {
    local px=$(( (DESKTOP_W - PORTRAIT_W) / 2 ))
    local py=$(( (DESKTOP_H - PORTRAIT_H) / 2 ))

    DISPLAY=":${DISPLAY_NUM}" xdotool windowsize --sync "$WIN_ID" "$PORTRAIT_W" "$PORTRAIT_H"
    DISPLAY=":${DISPLAY_NUM}" xdotool windowmove --sync "$WIN_ID" "$px" "$py"
    DISPLAY=":${DISPLAY_NUM}" xdotool windowfocus "$WIN_ID" 2>/dev/null || true
    CURRENT_VIEW_MODE="portrait"
    update_click_coords
}

apply_fullscreen_mode() {
    DISPLAY=":${DISPLAY_NUM}" xdotool windowsize --sync "$WIN_ID" "$DESKTOP_W" "$DESKTOP_H"
    DISPLAY=":${DISPLAY_NUM}" xdotool windowmove --sync "$WIN_ID" 0 0
    DISPLAY=":${DISPLAY_NUM}" xdotool windowfocus "$WIN_ID" 2>/dev/null || true
    CURRENT_VIEW_MODE="fullscreen"
    update_click_coords
}

toggle_view_mode() {
    if [ "$CURRENT_VIEW_MODE" = "portrait" ]; then
        echo "      ViewMode-Wechsel: portrait -> fullscreen"
        apply_fullscreen_mode
    else
        echo "      ViewMode-Wechsel: fullscreen -> portrait"
        apply_portrait_mode
    fi
}

setup_virtual_audio() {
    if ! command -v pulseaudio >/dev/null 2>&1; then
        echo "      Hinweis: 'pulseaudio' fehlt – Preview wird ohne Audio aufgenommen."
        return
    fi
    if ! command -v pactl >/dev/null 2>&1; then
        echo "      Hinweis: 'pactl' fehlt – Preview wird ohne Audio aufgenommen."
        return
    fi

    AUDIO_RUNTIME_DIR="$(mktemp -d "${SCRIPT_DIR}/pulse-runtime.XXXXXX")"
    export XDG_RUNTIME_DIR="$AUDIO_RUNTIME_DIR"
    export PULSE_RUNTIME_PATH="${AUDIO_RUNTIME_DIR}/pulse"
    mkdir -p "$PULSE_RUNTIME_PATH"
    export PULSE_SERVER="unix:${PULSE_RUNTIME_PATH}/native"

    echo "      Starte virtuelle PulseAudio-Sink ..."
    pulseaudio --daemonize=yes --exit-idle-time=-1 --disable-shm=true \
        --log-target=file:"${SCRIPT_DIR}/pulseaudio_localgame.log" \
        > /dev/null 2>&1 || {
        echo "      Hinweis: PulseAudio konnte nicht gestartet werden – ohne Audio weitermachen."
        return
    }

    for _ in $(seq 1 20); do
        if pactl info >/dev/null 2>&1; then
            break
        fi
        sleep 0.2
    done

    if ! pactl info >/dev/null 2>&1; then
        echo "      Hinweis: PulseAudio antwortet nicht – ohne Audio weitermachen."
        pulseaudio --kill >/dev/null 2>&1 || true
        return
    fi

    pactl load-module module-null-sink \
        sink_name=pokerth_preview \
        sink_properties=device.description=PokerTHPreview \
        > /dev/null
    pactl set-default-sink pokerth_preview >/dev/null 2>&1 || true

    AUDIO_SOURCE="pokerth_preview.monitor"
    AUDIO_ENABLED=1
    echo "      Audio aktiv: ${AUDIO_SOURCE}"
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
    if [ "$AUDIO_ENABLED" -eq 1 ]; then
        pulseaudio --kill >/dev/null 2>&1 || true
    fi
    rm -rf "${AUDIO_RUNTIME_DIR:-}" 2>/dev/null || true
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

# ── Virtuelles Audio ─────────────────────────────────────────────────────────
echo "[3/6] Initialisiere Audio ..."
setup_virtual_audio

# ── ffmpeg-Aufnahme ───────────────────────────────────────────────────────────
echo "[4/6] Starte ffmpeg-Aufnahme → ${VIDEO_FILE} ..."
ffmpeg_args=(
    -f x11grab
    -video_size "${DISPLAY_RES}"
    -framerate 15
    -i ":${DISPLAY_NUM}"
)

if [ "$AUDIO_ENABLED" -eq 1 ]; then
    ffmpeg_args+=(
        -thread_queue_size 512
        -sample_rate 44100
        -channels 2
        -fragment_size 8820
        -f pulse
        -i "$AUDIO_SOURCE"
    )
fi

ffmpeg_args+=(
    -c:v libx264 -preset fast -crf 23
    -pix_fmt yuv420p
    -profile:v baseline -level 3.1
)

if [ "$AUDIO_ENABLED" -eq 1 ]; then
    ffmpeg_args+=(
        -c:a aac -b:a 128k
        -ar 44100
        -af "adelay=${AUDIO_SYNC_DELAY_MS}|${AUDIO_SYNC_DELAY_MS}"
    )
fi

ffmpeg_args+=(
    -movflags +faststart
    -y "${VIDEO_FILE}"
)

ffmpeg "${ffmpeg_args[@]}" > "${SCRIPT_DIR}/ffmpeg_localgame.log" 2>&1 &
FFMPEG_PID=$!
sleep 1

# ── QML-Client starten ────────────────────────────────────────────────────────
echo "[5/6] Starte QML-Client ..."
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

echo "      Setze initialen Portrait-Modus ..."
apply_portrait_mode

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

update_click_coords

echo "      DEBUG: WX=${WX} WY=${WY}"
echo "             LokalesSpiel=(${LOKALGAME_X},${LOKALGAME_Y})"
echo "             SpielStarten=(${SPIELSTART_X},${SPIELSTART_Y})"
echo "             Door=(${DOOR_X},${DOOR_Y})"
echo "             FOLD=(${FOLD_X},${ACTION_Y})  CALL=(${CALL_X},${ACTION_Y})  RAISE=(${RAISE_X},${ACTION_Y})"
echo "             1/2-Pot=(${HALF_POT_X},${HALF_POT_Y})  RAISE-aktiv=(${RAISE_X},${RAISE_ACTIVE_Y})"

# ── Demo-Flow ─────────────────────────────────────────────────────────────────
echo ""
echo "[6/6] Demo-Flow ..."

PLAYER_ACTION_DELAY=2
HAND_SWITCH_DELAY=7
HAND3_EXIT_DELAY=4

# 1. Startseite screenshotten
shot "01_startseite.png"

# 2. Lokales Spiel starten → LocalGamePage
click_at "$LOKALGAME_X" "$LOKALGAME_Y" "(Lokales Spiel starten)"
sleep 2
shot "02_localgame_settings.png"

# 3. Spiel starten mit Standardeinstellungen (10 Spieler, 5000 Startkapital)
update_click_coords
click_at "$SPIELSTART_X" "$SPIELSTART_Y" "(Spiel starten)"
echo "      Warte auf GamePage (6s) ..."
sleep 6
shot "03_gamepage_preflop.png"

GAME_MODE_TOGGLE_ACTIVE=1
NEXT_MODE_SWITCH_AT=$((SECONDS + MODE_TOGGLE_INTERVAL))
echo "      ViewMode-Toggle aktiv: alle ${MODE_TOGGLE_INTERVAL}s"

# 4. Hand 1 – Spielverlauf
#    Runde 1, 2, 4: CALL (kein Effekt wenn nicht am Zug)
#    Runde 3:       1/2-Pot + RAISE (kein Effekt wenn nicht am Zug oder kein Raise möglich)
echo "      Hand 1 – Spielverlauf ..."

# Runde 1 – CALL
wait_preview "$PLAYER_ACTION_DELAY"
update_click_coords
click_at "$CALL_X" "$ACTION_Y" "(CALL Runde 1)"
shot "04_hand1_runde1.png"

# Runde 2 – CALL
wait_preview "$PLAYER_ACTION_DELAY"
update_click_coords
click_at "$CALL_X" "$ACTION_Y" "(CALL Runde 2)"
shot "04_hand1_runde2.png"

# Runde 3 – 1/2-Pot setzen, dann RAISE
#   Wenn Spieler gerade an der Reihe ist und Raise-Controls sichtbar:
#     1/2-Klick → setzt raiseAmount auf halben Pot → RAISE klicken
#   Sonst: Klicks landen auf Spieltisch (kein Effekt)
wait_preview "$PLAYER_ACTION_DELAY"
echo "      Runde 3: 1/2-Pot + RAISE versuchen ..."
update_click_coords
click_at "$HALF_POT_X" "$HALF_POT_Y" "(1/2-Pot Button)"
sleep 0.5
update_click_coords
click_at "$RAISE_X" "$RAISE_ACTIVE_Y" "(RAISE)"
shot "04_hand1_runde3.png"

# Runde 4 – CALL
wait_preview "$PLAYER_ACTION_DELAY"
update_click_coords
click_at "$CALL_X" "$ACTION_Y" "(CALL Runde 4)"
shot "04_hand1_runde4.png"

# 5. Hand 2 – kompakt durchspielen und dann in Hand 3 überleiten
echo "      Hand 2 – Spielverlauf ..."

wait_preview "$HAND_SWITCH_DELAY"
shot "05_hand2_preflop.png"

# Runde 1 – CALL
wait_preview "$PLAYER_ACTION_DELAY"
update_click_coords
click_at "$CALL_X" "$ACTION_Y" "(CALL Hand 2 Runde 1)"
shot "05_hand2_runde1.png"

# Runde 2 – CALL
wait_preview "$PLAYER_ACTION_DELAY"
update_click_coords
click_at "$CALL_X" "$ACTION_Y" "(CALL Hand 2 Runde 2)"
shot "05_hand2_runde2.png"

# Runde 3 – 1/2-Pot + RAISE
wait_preview "$PLAYER_ACTION_DELAY"
echo "      Hand 2 Runde 3: 1/2-Pot + RAISE versuchen ..."
update_click_coords
click_at "$HALF_POT_X" "$HALF_POT_Y" "(1/2-Pot Button Hand 2)"
sleep 0.5
update_click_coords
click_at "$RAISE_X" "$RAISE_ACTIVE_Y" "(RAISE Hand 2)"
shot "05_hand2_runde3.png"

# Hand 2 entspannt auslaufen lassen; es reicht, wenn der Ablauf sichtbar in die
# dritte Hand übergeht, bevor wir sauber zurück navigieren.
echo "      Warte auf den Übergang in Hand 3 ..."
wait_preview "$HAND_SWITCH_DELAY"
shot "05_hand3_start.png"

# 6. Zurück zur Startseite:
#    1. Escape → mainStackView.pop() → GamePage verlassen → LocalGamePage
#    2. Escape → mainStackView.pop() → LocalGamePage verlassen → StartPage
echo "      Zurück zur Startseite ..."
wait_preview "$HAND3_EXIT_DELAY"
GAME_MODE_TOGGLE_ACTIVE=0

if [ "$CURRENT_VIEW_MODE" != "portrait" ]; then
    echo "      Wechsel zurück in Portrait vor dem Exit ..."
    apply_portrait_mode
fi

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
