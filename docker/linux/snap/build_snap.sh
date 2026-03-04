#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "Building snap for PokerTH version 2.0.6..."

# Determine snapcraft invocation. Prefer LXD if available, otherwise destructive-mode.
if command -v snapcraft >/dev/null 2>&1; then
	echo "snapcraft found locally"
	if command -v lxd >/dev/null 2>&1 || command -v lxd.lxc >/dev/null 2>&1; then
		echo "Using LXD for clean build"
		snapcraft
	else
		echo "LXD not found — using destructive-mode (unsafe for host)"
		snapcraft --destructive-mode
	fi
else
	echo "snapcraft not found in PATH. Expect to run inside a snapcraft-enabled container. Trying snapcraft command (may fail)..."
	snapcraft --destructive-mode || { echo "snapcraft failed or not available."; exit 2; }
fi

echo "Build finished. Look for .snap files in the current directory or in parts/*/install/*/snap/"

