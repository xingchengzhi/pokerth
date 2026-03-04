FROM ubuntu:questing
# Based on docker/linux/Dockerfile — Ubuntu 25.10 (questing)

ENV TZ=Europe/Berlin

USER root

# Enable deb-src for questing
RUN echo '\nTypes: deb-src' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'URIs: http://archive.ubuntu.com/ubuntu/' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'Suites: questing questing-updates questing-backports' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'Components: main universe restricted multiverse' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg' >> /etc/apt/sources.list.d/ubuntu.sources

# Build dependencies (Qt 6.9, libboost 1.88, protobuf, websocketpp)
RUN apt update && DEBIAN_FRONTEND="noninteractive" && apt upgrade -y
RUN apt install -y wget git ca-certificates build-essential cmake debhelper zip ninja-build \
    libwebsocketpp-dev libprotobuf-dev protobuf-compiler libboost1.88-all-dev \
    qt6-base-dev qt6-svg-dev qt6-declarative-dev qt6-tools-dev linguist-qt6 qt6-websockets-dev \
    qt6-multimedia-dev libqt6sql6-mysql libssl-dev

# Install flatpak and flatpak-builder for flatpak packaging
RUN apt install -y flatpak flatpak-builder

# Cleanup
RUN apt clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]
