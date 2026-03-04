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

# Ensure snap's ELF interpreter path exists and snapcraft env vars are set
if [ ! -e /snap/core24/current/lib64/ld-linux-x86-64.so.2 ]; then
  sudo mkdir -p /snap/core24/current/lib64
  sudo ln -s /lib64/ld-linux-x86-64.so.2 /snap/core24/current/lib64/ld-linux-x86-64.so.2
fi
export SNAP="/snap/snapcraft/current"
export SNAP_NAME="snapcraft"
export SNAP_VERSION="8.0"
export SNAP_INSTANCE_NAME="snapcraft"
export SNAP_ARCH="amd64"
export LD_LIBRARY_PATH="/snap/snapcraft/current/lib/x86_64-linux-gnu:/snap/snapcraft/current/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"

# Run snapcraft directly — sudo --preserve-env passes all SNAP_* and LD_LIBRARY_PATH
sudo --preserve-env=SNAP,SNAP_NAME,SNAP_VERSION,SNAP_INSTANCE_NAME,SNAP_ARCH,LD_LIBRARY_PATH,PATH \
  snapcraft --destructive-mode

echo "Build finished."
ls -la "${REPO_ROOT}"/*.snap 2>/dev/null || echo "No .snap files found in ${REPO_ROOT}/"

