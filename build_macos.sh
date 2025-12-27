#!/usr/bin/env bash

###
# you need to install latest xcode and xcode commandline tools before running this script

set -euo pipefail

########################################
# Configuration
########################################

BREW_PREFIX_DEFAULT="/opt/homebrew"   # Apple Silicon
VCPKG_DIR="$HOME/vcpkg"
PYTHON_USER_BASE="$HOME/.local"
AQT_BIN="$PYTHON_USER_BASE/bin/aqt"

########################################
# Helper functions
########################################

log() {
  echo "▶ $1"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

########################################
# 1. Homebrew
########################################

if ! command_exists brew; then
  log "Installing Homebrew…"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # shellenv (Apple Silicon)
  if [ -d "$BREW_PREFIX_DEFAULT" ]; then
    eval "$($BREW_PREFIX_DEFAULT/bin/brew shellenv)"
  fi
else
  log "Homebrew already installed"
fi

########################################
# 2. Base packages
########################################

log "Installing base packages via Homebrew…"
brew update
brew install \
  cmake \
  ninja \
  git \
  python \
  pkg-config

########################################
# 3. pipx
########################################

if ! command_exists pipx; then
  log "Installing pipx…"
  brew install pipx
  pipx ensurepath
else
  log "pipx already installed"
fi

########################################
# 4. aqtinstall (via pipx)
########################################

if ! command_exists aqt; then
  log "Installing aqtinstall via pipx…"
  pipx install aqtinstall
else
  log "aqtinstall already installed"
fi

export PATH="$HOME/.local/bin:$PATH"

########################################
# 5. vcpkg
########################################

if [ ! -d "$VCPKG_DIR" ]; then
  log "Cloning vcpkg…"
  git clone https://github.com/microsoft/vcpkg.git "$VCPKG_DIR"
else
  log "vcpkg directory already exists"
fi

log "Bootstrapping vcpkg…"
"$VCPKG_DIR/bootstrap-vcpkg.sh"


########################################
# vcpkg dependencies
########################################

brew install \
  cmake \
  ninja \
  git \
  python \
  pkg-config \
  autoconf \
  autoconf-archive \
  automake \
  libtool

declare -a VCPKG_PORTS=(
  boost
  protobuf
  curl
)

# Architektur bestimmen
if [[ "$(uname -m)" == "arm64" ]]; then
  VCPKG_TRIPLET="arm64-osx"
else
  VCPKG_TRIPLET="x64-osx"
fi

log "Installing vcpkg dependencies (${VCPKG_TRIPLET})…"
"$HOME/vcpkg/vcpkg" install \
  --triplet="$VCPKG_TRIPLET" \
  "${VCPKG_PORTS[@]}"

########################################
# Qt installation (aqtinstall)
########################################

QT_VERSION="6.10.0"
QT_OUTPUT_DIR="$HOME/Qt"

QT_MODULES=(
  qt3d
  qt5compat
  qtcharts
  qtconnectivity
  qtdatavis3d
  qtgraphs
  qtgrpc
  qthttpserver
  qtimageformats
  qtlocation
  qtlottie
  qtmultimedia
  qtnetworkauth
  qtpositioning
  qtquick3d
  qtquick3dphysics
  qtquicktimeline
  qtremoteobjects
  qtscxml
  qtsensors
  qtserialbus
  qtserialport
  qtshadertools
  qtspeech
  qtvirtualkeyboard
  qtwebchannel
  qtwebsockets
  qtwebview
)

log "Installing Qt ${QT_VERSION} for macOS (clang_64) with modules…"
aqt install-qt mac desktop "$QT_VERSION" clang_64 \
  --outputdir "$QT_OUTPUT_DIR" \
  --modules "${QT_MODULES[@]}"

QT_DIR="$QT_OUTPUT_DIR/$QT_VERSION/macos"
log "Qt installed at: $QT_DIR"
########################################


