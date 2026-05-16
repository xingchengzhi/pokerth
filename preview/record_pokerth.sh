#!/bin/bash
# PokerTH Headless-Demo: Screenshots + Video
# Flow: Startfenster → Einstellungen → Internet-Login → Lobby (als Gast)
#
# Menü-Shortcuts (deutsch):
#   &PokerTH       → Alt+P
#   &Einstellungen → Alt+E
# Button-Shortcuts (im Startfenster):
#   &1 Lokales Spiel starten → Alt+1
#   &2 Internetspiel         → Alt+2
#
# Benötigte apt-Pakete (einmalig installieren):
#   sudo apt install xvfb openbox ffmpeg scrot xdotool

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DISPLAY_NUM=99
DISPLAY_RES="1024x768"
BINARY="/opt/pokerth_env/repos/pokerth-test/build/bin/pokerth_client"
OUTPUT_DIR="${SCRIPT_DIR}/screenshots"
VIDEO_FILE="${SCRIPT_DIR}/pokerth_demo.mp4"
export DISPLAY=":${DISPLAY_NUM}"

mkdir -p "$OUTPUT_DIR"
# Alte Screenshots entfernen
rm -f "${OUTPUT_DIR}"/0*.png

# ── Hilfsfunktion: Vollbild-Screenshot (Xvfb-Display) ──────────────────────────
shot_window() {
    local label="$1"
    local win_id="$2"
    local out="${OUTPUT_DIR}/${label}"
    DISPLAY=":${DISPLAY_NUM}" xdotool windowactivate --sync "$win_id" 2>/dev/null || true
    sleep 0.5
    DISPLAY=":${DISPLAY_NUM}" scrot "$out"
    echo "      Screenshot → $out"
}

# ── Cleanup-Funktion ────────────────────────────────────────────────────────────
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

# ── Xvfb starten ───────────────────────────────────────────────────────────────
echo "[1/8] Starte Xvfb :${DISPLAY_NUM} (${DISPLAY_RES}x24) ..."
Xvfb ":${DISPLAY_NUM}" -screen 0 "${DISPLAY_RES}x24" -ac &
XVFB_PID=$!
sleep 1

# ── Window-Manager ─────────────────────────────────────────────────────────────
echo "[2/8] Starte openbox ..."
DISPLAY=":${DISPLAY_NUM}" openbox &
WM_PID=$!
sleep 1

# ── ffmpeg-Aufnahme starten ─────────────────────────────────────────────────────
echo "[3/8] Starte ffmpeg-Aufnahme → ${VIDEO_FILE} ..."
ffmpeg -f x11grab \
    -video_size "${DISPLAY_RES}" \
    -framerate 15 \
    -i ":${DISPLAY_NUM}" \
    -c:v libx264 -preset fast -crf 23 \
    -pix_fmt yuv420p \
    -profile:v baseline -level 3.1 \
    -movflags +faststart \
    -y "${VIDEO_FILE}" \
    > "${SCRIPT_DIR}/ffmpeg_pokerth.log" 2>&1 &
FFMPEG_PID=$!
sleep 1

# ── PokerTH starten ─────────────────────────────────────────────────────────────
echo "[4/8] Starte PokerTH ..."
# Config auf Registrierter-Spieler-Modus zurücksetzen (für konsistente Tab-Navigation)
if [ -f ~/.pokerth/config.xml ]; then
    sed -i 's|<InternetLoginMode value="[0-9]*"/>|<InternetLoginMode value="0"/>|' ~/.pokerth/config.xml
fi
DISPLAY=":${DISPLAY_NUM}" "${BINARY}" > "${SCRIPT_DIR}/pokerth_client.log" 2>&1 &
POKERTH_PID=$!

# ── Auf Startfenster warten ──────────────────────────────────────────────────────
echo "      Warte auf PokerTH-Startfenster ..."
WIN_ID=""
for i in $(seq 1 40); do
    WIN_ID=$(DISPLAY=":${DISPLAY_NUM}" xdotool search --onlyvisible --name "PokerTH" 2>/dev/null | head -1 || true)
    [ -n "$WIN_ID" ] && break
    sleep 1
    echo "      ... $i/40"
done

if [ -z "$WIN_ID" ]; then
    echo "[FEHLER] PokerTH-Fenster nicht gefunden!"
    DISPLAY=":${DISPLAY_NUM}" scrot "${OUTPUT_DIR}/debug_no_window.png" || true
    exit 1
fi

echo "      Fenster-ID: $WIN_ID – Warte 3s auf vollständiges Laden ..."
DISPLAY=":${DISPLAY_NUM}" xdotool windowactivate --sync "$WIN_ID"
sleep 3

# ── Screenshot 1: Startfenster ───────────────────────────────────────────────────
echo ""
echo "[5/8] Screenshot 1: Startfenster"
shot_window "01_startfenster.png" "$WIN_ID"
sleep 1

# ── Einstellungen öffnen: Alt+E → Enter (erster Eintrag) ─────────────────────
echo ""
echo "      Öffne Einstellungen-Menü (Alt+E → Enter) ..."
DISPLAY=":${DISPLAY_NUM}" xdotool windowactivate --sync "$WIN_ID"
sleep 0.5
DISPLAY=":${DISPLAY_NUM}" xdotool key --window "$WIN_ID" alt+e
sleep 0.8
DISPLAY=":${DISPLAY_NUM}" xdotool key Return
sleep 2

# Einstellungen-Dialog: neues Fenster suchen
SETTINGS_WIN_ID=$(DISPLAY=":${DISPLAY_NUM}" xdotool search --onlyvisible --name "PokerTH" 2>/dev/null | grep -v "^${WIN_ID}$" | head -1 || true)
[ -z "$SETTINGS_WIN_ID" ] && SETTINGS_WIN_ID="$WIN_ID"

# Screenshot 2: Einstellungen-Dialog
echo "      Screenshot 2: Einstellungen-Dialog"
shot_window "02_einstellungen.png" "$SETTINGS_WIN_ID"
sleep 1

# Einstellungen schließen (Escape oder OK/Cancel-Taste)
DISPLAY=":${DISPLAY_NUM}" xdotool key Escape
sleep 1

# ── 2 Internetspiel → Login-Dialog ───────────────────────────────────────────
echo ""
echo "[6/8] Klicke '2 Internetspiel' (Alt+2) ..."
DISPLAY=":${DISPLAY_NUM}" xdotool windowactivate --sync "$WIN_ID"
sleep 0.5
DISPLAY=":${DISPLAY_NUM}" xdotool key --window "$WIN_ID" alt+2
sleep 3

# Login-Dialog: suche neues Fenster
LOGIN_WIN=$(DISPLAY=":${DISPLAY_NUM}" xdotool search --onlyvisible --name "." 2>/dev/null | grep -v "^${WIN_ID}$" | head -1 || true)
[ -z "$LOGIN_WIN" ] && LOGIN_WIN="$WIN_ID"

# Screenshot 3: Login-Dialog
echo "      Screenshot 3: Internet Game Login"
shot_window "03_login.png" "$LOGIN_WIN"
sleep 1

# ── Gast-Login: Tab-Navigation ────────────────────────────────────────────────
# Tabstops: groupBox(1) → lineEdit_username(2) → lineEdit_password(3)
#            → checkBox_rememberPassword(4) → checkBox_guest(5) → pushButton_login(6)
echo ""
echo "[7/8] Gast-Login: Tab x4 → Space (Checkbox) → Tab → Enter (Login) ..."
DISPLAY=":${DISPLAY_NUM}" xdotool windowactivate --sync "$LOGIN_WIN"
sleep 0.5
# Fokus sicherstellen: erst Tab damit aus groupBox raus
DISPLAY=":${DISPLAY_NUM}" xdotool key Tab Tab Tab Tab
sleep 0.4
# checkBox_guest aktivieren
DISPLAY=":${DISPLAY_NUM}" xdotool key space
sleep 0.4
# Zum Login-Button
DISPLAY=":${DISPLAY_NUM}" xdotool key Tab
sleep 0.3
# Login bestätigen
DISPLAY=":${DISPLAY_NUM}" xdotool key Return

echo "      Warte auf Lobby-Verbindung (bis 35s) ..."
LOBBY_WIN=""
for i in $(seq 1 35); do
    # Lobby hat ein anderes Fenster als Startfenster + Login-Dialog
    ALL_WINS=$(DISPLAY=":${DISPLAY_NUM}" xdotool search --onlyvisible --name "." 2>/dev/null || true)
    for wid in $ALL_WINS; do
        if [ "$wid" != "$WIN_ID" ] && [ "$wid" != "$LOGIN_WIN" ]; then
            W_TITLE=$(DISPLAY=":${DISPLAY_NUM}" xdotool getwindowname "$wid" 2>/dev/null || true)
            if echo "$W_TITLE" | grep -qi "lobby\|PokerTH\|Spiel"; then
                LOBBY_WIN="$wid"
                echo "      Lobby-Fenster gefunden: $wid ('$W_TITLE')"
                break 2
            fi
        fi
    done
    sleep 1
    echo "      ... warte $i/35"
done

# Falls kein separates Lobby-Fenster: Startfenster könnte sich gewandelt haben
if [ -z "$LOBBY_WIN" ]; then
    LOBBY_WIN=$(DISPLAY=":${DISPLAY_NUM}" xdotool search --onlyvisible --name "." 2>/dev/null | head -1 || true)
    echo "      Verwende aktuell aktives Fenster: $LOBBY_WIN"
fi

sleep 2

# Screenshot 4: Lobby (oder Verbindungsstatus)
echo "      Screenshot 4: Lobby / Verbindungsstatus"
shot_window "04_lobby.png" "${LOBBY_WIN:-$WIN_ID}"
sleep 5  # Zusätzliche Zeit im Video

# ── Aufnahme beenden ─────────────────────────────────────────────────────────────
echo ""
echo "      Beende ffmpeg-Aufnahme ..."
kill -INT "$FFMPEG_PID" 2>/dev/null || true
wait "$FFMPEG_PID" 2>/dev/null || true
unset FFMPEG_PID  # verhindert doppeltes Kill in cleanup

# ── Zusammenfassung ──────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "║         PokerTH Demo – Fertig        ║"
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
    echo "Video: nicht erstellt (Log: ${SCRIPT_DIR}/ffmpeg_pokerth.log)"
fi
