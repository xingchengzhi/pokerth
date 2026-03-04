FROM ubuntu:25.10

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies that match Ubuntu 25.10 repositories (includes libboost 1.88)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg lsb-release build-essential cmake git python3-pip \
    pkg-config libssl-dev zlib1g-dev libsqlite3-dev wget sudo \
    libboost-all-dev protobuf-compiler libprotobuf-dev \
    qtbase5-dev qtdeclarative5-dev libqt5svg5-dev libx11-dev \
  && rm -rf /var/lib/apt/lists/*

# Install docker CLI to allow usage if needed inside container (optional)
RUN apt-get update && apt-get install -y --no-install-recommends docker.io && rm -rf /var/lib/apt/lists/*

# Install snapd/snapcraft via snaps (may require privileged container/runtime that supports snapd)
RUN apt-get update && apt-get install -y --no-install-recommends snapd squashfuse fuse && rm -rf /var/lib/apt/lists/*
RUN snap install core20 --classic || true
RUN snap install snapcraft --classic || true

WORKDIR /workspace

COPY build_snap.sh /workspace/docker/linux/snap/build_snap.sh
RUN chmod +x /workspace/docker/linux/snap/build_snap.sh

CMD ["/bin/bash"]
