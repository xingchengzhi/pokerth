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

# snapcraft env vars (normally set by snap confinement)
export SNAP="/snap/snapcraft/current"
export SNAP_NAME="snapcraft"
export SNAP_VERSION="8.0"
export SNAP_INSTANCE_NAME="snapcraft"
export SNAP_ARCH="amd64"

# Run snapcraft — no LD_LIBRARY_PATH needed (binaries are patched with patchelf)
sudo --preserve-env=SNAP,SNAP_NAME,SNAP_VERSION,SNAP_INSTANCE_NAME,SNAP_ARCH \
  /snap/snapcraft/current/bin/snapcraft --destructive-mode

echo "Build finished."
ls -la "${REPO_ROOT}"/*.snap 2>/dev/null || echo "No .snap files found in ${REPO_ROOT}/"

