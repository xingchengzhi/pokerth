#!/usr/bin/env bash
set -euo pipefail

SNAP_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="/opt/pokerth-snap/pokerth"

echo "Building snap for PokerTH version 2.0.6..."

# snapcraft expects snap/snapcraft.yaml inside the project root
mkdir -p "${REPO_ROOT}/snap"
cp "${SNAP_DIR}/snapcraft.yaml" "${REPO_ROOT}/snap/snapcraft.yaml"
# Remove root-level snapcraft.yaml if present (snapcraft refuses both)
rm -f "${REPO_ROOT}/snapcraft.yaml"

cd "${REPO_ROOT}"

# Fix python3 in extracted snapcraft — snap's binary can't run outside confinement,
# replace with wrapper using system python3 + snap's PYTHONPATH
if [ ! -x /snap/snapcraft/current/bin/python3 ] || file /snap/snapcraft/current/bin/python3 | grep -q ELF; then
  sudo rm -f /snap/snapcraft/current/bin/python3
  printf '#!/bin/sh\nSNAP_ROOT="/snap/snapcraft/current"\nexport PYTHONPATH="${SNAP_ROOT}/lib/python3.12/site-packages:${SNAP_ROOT}/usr/lib/python3/dist-packages:${PYTHONPATH:-}"\nexec /usr/bin/python3 "$@"\n' \
    | sudo tee /snap/snapcraft/current/bin/python3 > /dev/null
  sudo chmod +x /snap/snapcraft/current/bin/python3
fi

# Run snapcraft directly (already installed in this container via unsquashfs)
sudo /snap/snapcraft/current/bin/snapcraft --destructive-mode

echo "Build finished."
ls -la "${REPO_ROOT}"/*.snap 2>/dev/null || echo "No .snap files found in ${REPO_ROOT}/"

