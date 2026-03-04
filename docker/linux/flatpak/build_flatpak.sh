#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "Building Flatpak for PokerTH version 2.0.6..."

# Create a local repo and build
flatpak-builder --force-clean --repo=repo build-dir org.pokerth.PokerTH.json

# Create a bundle file (version tag used as branch)
flatpak build-bundle repo pokerth-2.0.6.flatpak org.pokerth.PokerTH 2.0.6

echo "Done. Bundle: pokerth-2.0.6.flatpak"
