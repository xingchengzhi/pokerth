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

# Fix python3 in extracted snapcraft — symlink chain broken after unsquashfs.
# Create wrapper using snap's own python3.12 + its LD_LIBRARY_PATH.
if [ ! -x /snap/snapcraft/current/bin/python3 ] || file /snap/snapcraft/current/bin/python3 2>/dev/null | grep -q ELF; then
  sudo rm -f /snap/snapcraft/current/bin/python3
  printf '#!/bin/sh\nSNAP_ROOT="/snap/snapcraft/current"\nexport LD_LIBRARY_PATH="${SNAP_ROOT}/lib/x86_64-linux-gnu:${SNAP_ROOT}/usr/lib/x86_64-linux-gnu:${SNAP_ROOT}/lib:${SNAP_ROOT}/usr/lib:${LD_LIBRARY_PATH:-}"\nexec "${SNAP_ROOT}/usr/bin/python3.12" "$@"\n' \
    | sudo tee /snap/snapcraft/current/bin/python3 > /dev/null
  sudo chmod +x /snap/snapcraft/current/bin/python3
fi

# Run snapcraft directly (already installed in this container via unsquashfs)
# Set environment variables that snapcraft expects (normally set by snap confinement)
sudo env \
  SNAP="/snap/snapcraft/current" \
  SNAP_NAME="snapcraft" \
  SNAP_VERSION="8.0" \
  SNAP_ARCH="amd64" \
  SNAP_INSTANCE_NAME="snapcraft" \
  PYTHONPATH="/snap/snapcraft/current/lib/python3.12/site-packages:/snap/snapcraft/current/usr/lib/python3/dist-packages" \
  PATH="/snap/snapcraft/current/bin:/snap/snapcraft/current/usr/bin:$PATH" \
  /snap/snapcraft/current/bin/snapcraft --destructive-mode

echo "Build finished."
ls -la "${REPO_ROOT}"/*.snap 2>/dev/null || echo "No .snap files found in ${REPO_ROOT}/"

