#!/usr/bin/env bash
set -euo pipefail

SNAP_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="/opt/pokerth-snap/pokerth"

echo "Building snap for PokerTH version 2.0.6..."

# Activate venv if present (snapcraft installed via pip)
if [ -f /opt/pokerth-snap/venv/bin/activate ]; then
    source /opt/pokerth-snap/venv/bin/activate
fi

# Verify snapcraft is available
if ! command -v snapcraft >/dev/null 2>&1; then
    echo "ERROR: snapcraft not found. Install via: pip install snapcraft"
    exit 2
fi

echo "snapcraft version: $(snapcraft --version)"

# snapcraft needs to run from the directory containing snapcraft.yaml
# Copy snapcraft.yaml into the repo root (source: ../../../ relative won't work from repo)
cp "${SNAP_DIR}/snapcraft.yaml" "${REPO_ROOT}/snapcraft.yaml"
cd "${REPO_ROOT}"

echo "Running snapcraft --destructive-mode in ${REPO_ROOT} ..."
snapcraft --destructive-mode

echo "Build finished. Look for .snap files in ${REPO_ROOT}/"
ls -la *.snap 2>/dev/null || echo "No .snap files found."

