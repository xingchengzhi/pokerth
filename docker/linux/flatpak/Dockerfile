FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg lsb-release build-essential cmake git python3-pip \
    pkg-config libssl-dev zlib1g-dev libsqlite3-dev wget sudo \
    flatpak flatpak-builder \
    qtbase5-dev qtdeclarative5-dev libqt5svg5-dev libx11-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY build_flatpak.sh /workspace/docker/linux/flatpak/build_flatpak.sh
RUN chmod +x /workspace/docker/linux/flatpak/build_flatpak.sh

CMD ["/bin/bash"]
