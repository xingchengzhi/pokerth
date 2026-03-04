#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
==========================================================
  PokerTH Snap Build
==========================================================

  Snap builds use GitHub Actions (snapcore/action-build).
  
  To trigger a build:
    1. Push to 'testing' or 'stable' branch
    2. Or trigger manually via GitHub → Actions → Run workflow
  
  The workflow is at: .github/workflows/snap.yml
  
  To publish to Snap Store from 'stable':
    - Set SNAPCRAFT_STORE_CREDENTIALS secret in GitHub repo
    - Run: snapcraft export-login --snaps pokerth --channels stable credentials.txt
    - Copy contents of credentials.txt to the GitHub secret

  For local CMake build testing (in this devcontainer):
    cd /opt/pokerth-snap/pokerth
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
    cmake --build build

==========================================================
EOF

