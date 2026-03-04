# Ubuntu 24.04 = core24 base → snapcraft --destructive-mode works directly
FROM ubuntu:24.04

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ARG LANG=de_DE.UTF-8
ARG LANGUAGE=de_DE.UTF-8
ARG LC_ALL=de_DE.UTF-8

ARG ROOT=/opt/pokerth-snap
ENV ROOT=${ROOT}
ENV DEBIAN_FRONTEND=noninteractive

# Build dependencies (Qt6, Boost, protobuf, websocketpp) + snapcraft extraction tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget unzip git build-essential pkg-config \
    cmake ninja-build debhelper zip \
    squashfs-tools python3 patchelf \
    libwebsocketpp-dev libprotobuf-dev protobuf-compiler libboost-all-dev \
    qt6-base-dev qt6-svg-dev qt6-declarative-dev qt6-tools-dev linguist-qt6 \
    qt6-websockets-dev qt6-multimedia-dev libssl-dev \
    locales sudo nano mc \
    && rm -rf /var/lib/apt/lists/*

# Download and extract snapcraft snap (no snapd/systemd needed)
RUN SNAP_URL=$(curl -s -H "Snap-Device-Series: 16" \
      "https://api.snapcraft.io/v2/snaps/info/snapcraft" \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print([c for c in d['channel-map'] if c['channel']['name']=='stable' and c['channel']['architecture']=='amd64'][0]['download']['url'])") \
    && curl -sL "${SNAP_URL}" -o /tmp/snapcraft.snap \
    && mkdir -p /snap/snapcraft/current \
    && unsquashfs -d /snap/snapcraft/current /tmp/snapcraft.snap \
    && rm /tmp/snapcraft.snap

# Patch ALL snap ELF binaries to use system ld-linux + combined RPATH.
# core24 = Ubuntu 24.04 = this system, so system libs are ABI-compatible.
# This replaces the snap interpreter (/snap/core24/...) and adds system lib dirs to RPATH
# so binaries find BOTH system libs (libm, libc, ...) AND snap-specific libs (_yaml, etc.)
RUN SNAP_ROOT="/snap/snapcraft/current" \
    && RPATH="/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:${SNAP_ROOT}/lib/x86_64-linux-gnu:${SNAP_ROOT}/usr/lib/x86_64-linux-gnu:${SNAP_ROOT}/lib:${SNAP_ROOT}/usr/lib" \
    && find "${SNAP_ROOT}/usr/bin" "${SNAP_ROOT}/bin" "${SNAP_ROOT}/lib" "${SNAP_ROOT}/usr/lib" \
       -type f -executable 2>/dev/null | while read f; do \
         if readelf -l "$f" 2>/dev/null | grep -q 'Requesting program interpreter'; then \
           patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 --set-rpath "$RPATH" "$f" 2>/dev/null || true; \
         fi; \
       done \
    && rm -f "${SNAP_ROOT}/bin/python3" "${SNAP_ROOT}/bin/python" \
    && ln -s ../usr/bin/python3.12 "${SNAP_ROOT}/bin/python3" \
    && ln -s python3 "${SNAP_ROOT}/bin/python"

# Snapcraft env vars (safe — no path/lib changes yet)
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"
ENV SNAP_VERSION="8.0"
ENV SNAP_INSTANCE_NAME="snapcraft"
ENV SNAP_ARCH="amd64"

# Locales & timezone
RUN sed -i '/'${LANG}'/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG=${LANG}
ENV LANGUAGE=${LANGUAGE}
ENV LC_ALL=${LC_ALL}
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# apt cleanup (PATH/LD_LIBRARY_PATH not yet modified — system apt works)
RUN apt-get autoremove --purge && rm -Rf /var/cache/apt/archives && \
    unset DEBIAN_FRONTEND

# vscode user (remove default ubuntu user first — GID 1000 conflict)
RUN userdel -r ubuntu 2>/dev/null || true && \
    groupadd -g $USER_GID $USERNAME && \
    useradd -s /bin/bash -m -d /home/vscode -u $USER_UID -g $USER_GID $USERNAME && \
    mkdir -p /etc/sudoers.d && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

RUN mkdir -p ${ROOT} && chown -R vscode:vscode ${ROOT}

USER vscode

# Clone pokerth repo (before any snap PATH/LD changes)
RUN cd ${ROOT} && git clone https://github.com/pokerth/pokerth.git && cd pokerth && git checkout stable

# PATH only adds snap/bin (for snapcraft itself) — NOT snap/usr/bin (contains apt, git, dpkg...)
# LD_LIBRARY_PATH is NOT set globally — it breaks system binaries.
# build_snap.sh sets both LD_LIBRARY_PATH and extended PATH only for the snapcraft invocation.
ENV PATH="/snap/snapcraft/current/bin:${PATH}"

# snapcraft is available directly — run: ./build_snap.sh
