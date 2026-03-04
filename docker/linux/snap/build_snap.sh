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

# Run snapcraft directly (already installed in this container via unsquashfs)
# Use full path to avoid sudo PATH issues
sudo /snap/snapcraft/current/bin/snapcraft --destructive-mode

echo "Build finished."
ls -la "${REPO_ROOT}"/*.snap 2>/dev/null || echo "No .snap files found in ${REPO_ROOT}/"

