#!/usr/bin/env bash
set -euo pipefail

SNAP_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="/opt/pokerth-snap/pokerth"

echo "Building snap for PokerTH version 2.0.6..."

# Copy snapcraft.yaml into repo root (snapcraft expects it there)
cp "${SNAP_DIR}/snapcraft.yaml" "${REPO_ROOT}/snapcraft.yaml"

# Run snapcraft via the official snapcore/snapcraft Docker image
# This avoids needing snapd/systemd in the devcontainer
echo "Running snapcraft via Docker (snapcore/snapcraft image)..."
docker run --rm \
    -v "${REPO_ROOT}":/build \
    -w /build \
    snapcore/snapcraft:stable \
    snapcraft --destructive-mode

echo "Build finished."
ls -la "${REPO_ROOT}"/*.snap 2>/dev/null || echo "No .snap files found in ${REPO_ROOT}/"

