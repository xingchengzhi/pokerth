#!/usr/bin/env bash
set -euo pipefail

SNAP_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="/opt/pokerth-snap/pokerth"
CONTAINER_NAME="pokerth-snapcraft-build-$$"
BUILD_IMAGE="pokerth-snapcraft-builder"

echo "Building snap for PokerTH version 2.0.6..."

# snapcraft expects snap/snapcraft.yaml inside the project root
mkdir -p "${REPO_ROOT}/snap"
cp "${SNAP_DIR}/snapcraft.yaml" "${REPO_ROOT}/snap/snapcraft.yaml"
# Remove root-level snapcraft.yaml if present (snapcraft refuses both)
rm -f "${REPO_ROOT}/snapcraft.yaml"

# Build a custom Docker image with snapcraft extracted (no snapd/systemd needed).
# Based on Ubuntu 24.04 (matching base: core24) so --destructive-mode works.
echo "Building snapcraft builder image (first run may take a few minutes)..."

docker build -t "${BUILD_IMAGE}" -f - /dev/null <<'DOCKERFILE'
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Install build tools + all PokerTH build deps available in 24.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl squashfs-tools python3 python3-pip python3-venv \
    build-essential cmake ninja-build git pkg-config \
    qt6-base-dev qt6-svg-dev qt6-declarative-dev qt6-tools-dev linguist-qt6 \
    qt6-websockets-dev qt6-multimedia-dev libssl-dev \
    libprotobuf-dev protobuf-compiler libwebsocketpp-dev \
    libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*

# Download and extract the snapcraft snap (no snapd required)
RUN curl -sL $(curl -s -H "Snap-Device-Series: 16" \
      "https://api.snapcraft.io/v2/snaps/info/snapcraft" \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print([c for c in d['channel-map'] if c['channel']['name']=='latest/stable' and c['channel']['architecture']=='amd64'][0]['download']['url'])") \
    -o /tmp/snapcraft.snap \
    && mkdir -p /snap/snapcraft/current \
    && unsquashfs -d /snap/snapcraft/current /tmp/snapcraft.snap \
    && rm /tmp/snapcraft.snap

# Set up environment so extracted snapcraft is available
ENV PATH="/snap/snapcraft/current/bin:/snap/snapcraft/current/usr/bin:${PATH}"
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"
ENV SNAP_ARCH="amd64"

WORKDIR /build
DOCKERFILE

# Pipe the source into a container and run snapcraft
echo "Sending source tree to build container..."

tar -C "${REPO_ROOT}" -c . \
  | docker run --name "${CONTAINER_NAME}" -i "${BUILD_IMAGE}" \
      bash -c '
        set -e
        tar -C /build -x
        cd /build
        snapcraft --destructive-mode
        echo "=== Snap files ==="
        ls -la *.snap 2>/dev/null || echo "No .snap files produced"
      '

# Copy .snap file(s) out of the stopped container
echo "Extracting .snap file(s)..."
mkdir -p /tmp/snap-output
docker cp "${CONTAINER_NAME}:/build/." /tmp/snap-output/ 2>/dev/null || true
find /tmp/snap-output -maxdepth 1 -name '*.snap' -exec cp {} "${REPO_ROOT}/" \;

# Cleanup container
docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
rm -rf /tmp/snap-output

echo "Build finished."
ls -la "${REPO_ROOT}"/*.snap 2>/dev/null || echo "No .snap files found in ${REPO_ROOT}/"

