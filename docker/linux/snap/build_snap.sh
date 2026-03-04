#!/usr/bin/env bash
set -euo pipefail

SNAP_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="/opt/pokerth-snap/pokerth"
CONTAINER_NAME="pokerth-snapcraft-build-$$"

echo "Building snap for PokerTH version 2.0.6..."

# snapcraft expects snap/snapcraft.yaml inside the project root
mkdir -p "${REPO_ROOT}/snap"
cp "${SNAP_DIR}/snapcraft.yaml" "${REPO_ROOT}/snap/snapcraft.yaml"
# Remove root-level snapcraft.yaml if present (snapcraft refuses both)
rm -f "${REPO_ROOT}/snapcraft.yaml"

# snapcraft with base: core24 requires a build env based on Ubuntu 24.04.
# The old snapcore/snapcraft:stable image is xenial-based and unusable.
# We use an Ubuntu 24.04 container, install snapcraft via snap, and build.
echo "Sending source tree to build container..."

tar -C "${REPO_ROOT}" -c . \
  | docker run --name "${CONTAINER_NAME}" --privileged -i ubuntu:24.04 \
      bash -c '
        set -e
        export DEBIAN_FRONTEND=noninteractive

        # Unpack source
        mkdir -p /build && tar -C /build -x && cd /build

        # Install snapd and snapcraft
        apt-get update
        apt-get install -y snapd
        # Start snapd manually (no systemd)
        /usr/lib/snapd/snapd &
        sleep 3
        snap install snapcraft --classic
        snap install core24

        # Build
        cd /build
        snapcraft --destructive-mode
      '

# Copy .snap file(s) out of the stopped container
echo "Extracting .snap file(s)..."
mkdir -p /tmp/snap-output
docker cp "${CONTAINER_NAME}:/build/." /tmp/snap-output/ 2>/dev/null || true
find /tmp/snap-output -name '*.snap' -exec cp {} "${REPO_ROOT}/" \;

# Cleanup container
docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
rm -rf /tmp/snap-output

echo "Build finished."
ls -la "${REPO_ROOT}"/*.snap 2>/dev/null || echo "No .snap files found in ${REPO_ROOT}/"

