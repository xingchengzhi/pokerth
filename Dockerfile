FROM ubuntu:questing
# ubuntu:24.04 aka ubuntu:noble might also work with the following procedure (changing deb-src entries from questing to noble)

ENV TZ=Europe/Berlin

USER root

RUN echo '\nTypes: deb-src' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'URIs: http://archive.ubuntu.com/ubuntu/' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'Suites: questing questing-updates questing-backports' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'Components: main universe restricted multiverse' >> /etc/apt/sources.list.d/ubuntu.sources
RUN echo 'Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg' >> /etc/apt/sources.list.d/ubuntu.sources

# build-deps
RUN apt update && DEBIAN_FRONTEND="noninteractive" && apt upgrade -y
RUN apt install -y wget git ca-certificates build-essential cmake debhelper libmysql++-dev \ 
    libwebsocketpp-dev libprotobuf-dev protobuf-compiler libsdl-mixer1.2-dev libcurl4-gnutls-dev libsdl1.2-dev libsqlite3-dev \
    qt6-base-dev qt6-svg-dev qt6-declarative-dev qt6-tools-dev linguist-qt6 qt6-websockets-dev libboost1.88-all-dev ninja-build
# INFO: libmysql++-dev only required for official_server build target
# INFO: libwebsocketpp-dev only required for pokerth server build target
## INFO: in order to run a gui client inside a docker container you should use distrobox as it automatically integrates necessary xserver components

# cleanup
RUN apt clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/boost*

# fetch repo:
RUN cd /opt && git clone https://github.com/pokerth/pokerth.git && cd pokerth && git checkout stable
RUN cd /opt/pokerth && cmake -DCMAKE_BUILD_TYPE:STRING=Release -S. -B./build -G Ninja

# compile all targets:
RUN cd /opt/pokerth && cmake --build ./build --config Release --target all --

# install
# RUN cd /opt/pokerth && cmake --install ./build

ENTRYPOINT ["/bin/bash"]
