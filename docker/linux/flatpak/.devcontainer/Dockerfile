FROM ubuntu:25.10

ENV TARGET=pokerth_client

RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://de.archive.ubuntu.com/ubuntu/|' /etc/apt/sources.list.d/ubuntu.sources

# Set other build environment variables
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ARG LANG=de_DE.UTF-8
ARG LANGUAGE=de_DE.UTF-8
ARG LC_ALL=de_DE.UTF-8

ARG ROOT=/opt/pokerth-flatpak
ENV ROOT=${ROOT}
ENV DEBIAN_FRONTEND=noninteractive

# Enable deb-src for questing
RUN echo '\nTypes: deb-src' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'URIs: http://archive.ubuntu.com/ubuntu/' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'Suites: questing questing-updates questing-backports' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'Components: main universe restricted multiverse' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg' >> /etc/apt/sources.list.d/ubuntu.sources

# Build dependencies (Qt 6.9, libboost 1.88, protobuf, websocketpp)
RUN apt-get update && apt-get install -y \
    ca-certificates curl wget unzip git build-essential pkg-config \
    cmake ninja-build debhelper zip \
    libwebsocketpp-dev libprotobuf-dev protobuf-compiler libboost1.88-all-dev \
    qt6-base-dev qt6-svg-dev qt6-declarative-dev qt6-tools-dev linguist-qt6 qt6-websockets-dev \
    qt6-multimedia-dev libqt6sql6-mysql libssl-dev \
    locales sudo nano mc \
    flatpak flatpak-builder \
    && rm -rf /var/lib/apt/lists/*

# Install docker
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# locales & timezone
RUN sed -i '/'${LANG}'/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG ${LANG}
ENV LANGUAGE ${LANGUAGE}
ENV LC_ALL ${LC_ALL}
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# apt cleanup
RUN apt-get autoremove --purge && rm -Rf /var/cache/apt/archives && \
    unset DEBIAN_FRONTEND

# vscode user
RUN userdel ubuntu && \
    rm -Rf /home/ubuntu && \
    groupadd -g $USER_GID $USERNAME && \
    useradd -s /bin/bash -m -d /home/vscode -u $USER_UID -g $USER_GID $USERNAME && \
    mkdir -p /etc/sudoers.d && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    usermod -aG docker $USERNAME

RUN mkdir -p ${ROOT} && chown -R vscode:vscode ${ROOT}

USER vscode

# Clone pokerth repo
RUN cd ${ROOT} && git clone https://github.com/pokerth/pokerth.git && cd pokerth && git checkout stable

# Entrypoint/Command used from docker-compose.yml
# ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
