#!/bin/bash
# Wrapper für den event-driven Python-Recorder.
# Benötigte apt-Pakete:
#   sudo apt install xvfb openbox ffmpeg scrot xdotool

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec python3 "${SCRIPT_DIR}/record_pokerth_qml.py" "$@"
