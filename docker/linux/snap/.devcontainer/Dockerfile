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

# Build dependencies (Qt6, Boost, protobuf, websocketpp)
# python3-yaml: system PyYAML with libyaml C bindings (snap's version can't load outside snap)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget unzip git build-essential pkg-config \
    cmake ninja-build debhelper zip \
    squashfs-tools python3 python3-yaml python3-apt \
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

# Remove snap's yaml/C-extension packages — we use system python3-yaml instead
# (snap's .so files can't run outside snap confinement)
RUN rm -rf /snap/snapcraft/current/lib/python3.12/site-packages/yaml \
           /snap/snapcraft/current/lib/python3.12/site-packages/_yaml \
           /snap/snapcraft/current/lib/python3.12/site-packages/PyYAML*

# Create /usr/local/bin/snapcraft wrapper that uses SYSTEM python3
# with snap's packages via PYTHONPATH (no snap binaries needed at all)
RUN echo '#!/bin/bash' > /usr/local/bin/snapcraft \
    && echo 'export PYTHONPATH="/snap/snapcraft/current/lib/python3.12/site-packages${PYTHONPATH:+:$PYTHONPATH}"' >> /usr/local/bin/snapcraft \
    && echo 'export SNAP="/snap/snapcraft/current"' >> /usr/local/bin/snapcraft \
    && echo 'export SNAP_NAME="snapcraft"' >> /usr/local/bin/snapcraft \
    && echo 'export SNAP_VERSION="8.0"' >> /usr/local/bin/snapcraft \
    && echo 'export SNAP_INSTANCE_NAME="snapcraft"' >> /usr/local/bin/snapcraft \
    && echo 'export SNAP_ARCH="amd64"' >> /usr/local/bin/snapcraft \
    && echo 'exec /usr/bin/python3 -c "import sys; from snapcraft.application import main; sys.exit(main())" "$@"' >> /usr/local/bin/snapcraft \
    && chmod +x /usr/local/bin/snapcraft

# Locales & timezone
RUN sed -i '/'${LANG}'/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG=${LANG}
ENV LANGUAGE=${LANGUAGE}
ENV LC_ALL=${LC_ALL}
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# apt cleanup
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

# Clone pokerth repo
RUN cd ${ROOT} && git clone https://github.com/pokerth/pokerth.git && cd pokerth && git checkout stable

# snapcraft is available as /usr/local/bin/snapcraft — run: ./build_snap.sh
