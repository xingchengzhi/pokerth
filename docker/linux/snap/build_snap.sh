#!/usr/bin/env bash
set -euo pipefail

SNAP_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="/opt/pokerth-snap/pokerth"
CONTAINER_NAME="pokerth-snapcraft-build-$$"

echo "Building snap for PokerTH version 2.0.6..."

# snapcraft expects snap/snapcraft.yaml inside the project root
mkdir -p "${REPO_ROOT}/snap"
cp "${SNAP_DIR}/snapcraft.yaml" "${REPO_ROOT}/snap/snapcraft.yaml"

# Run snapcraft via the official snapcore/snapcraft Docker image.
# We pipe the source via tar to avoid Docker-in-Docker volume mount issues
# (volume paths refer to the Docker HOST, not to this devcontainer).
echo "Sending source tree to snapcraft container and building..."

# 1) Create container, pipe source in, build
tar -C "${REPO_ROOT}" -c . \
  | docker run --name "${CONTAINER_NAME}" -i snapcore/snapcraft:stable \
      bash -c 'set -e; mkdir -p /build; tar -C /build -x; cd /build; snapcraft --destructive-mode'

# 2) Copy .snap file(s) out of the stopped container
echo "Extracting .snap file(s)..."
docker cp "${CONTAINER_NAME}:/build/." /tmp/snap-output/ 2>/dev/null || true
find /tmp/snap-output -name '*.snap' -exec cp {} "${REPO_ROOT}/" \; 2>/dev/null

# 3) Cleanup container
docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
rm -rf /tmp/snap-output

echo "Build finished."
ls -la "${REPO_ROOT}"/*.snap 2>/dev/null || echo "No .snap files found in ${REPO_ROOT}/"

