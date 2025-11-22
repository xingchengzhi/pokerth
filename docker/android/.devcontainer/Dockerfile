FROM ubuntu:25.10

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ARG LANG=de_DE.UTF-8
ARG LANGUAGE=de_DE.UTF-8
ARG LC_ALL=de_DE.UTF-8

ENV DEBIAN_FRONTEND=noninteractive

ARG ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_NDK_VERSION=25.2.9519653
ARG GRADLE_VERSION=8.3

# set ANDROID_ARCH to one of the following:
# armv7 x86 arm64_v8a
ENV ANDROID_ARCH x86
ENV QT_VERSION 6.9.3

ENV ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}
ENV ANDROID_NDK_ROOT=${ANDROID_SDK_ROOT}/ndk/${ANDROID_NDK_VERSION}
ENV ANDROID_NDK_HOME=${ANDROID_SDK_ROOT}/ndk/${ANDROID_NDK_VERSION}
ENV PATH=$PATH:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:/opt/gradle/gradle-${GRADLE_VERSION}/bin

ENV VCPKG_ROOT=/opt/vcpkg
ENV VCPKG_CHAINLOAD_TOOLCHAIN_FILE $ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake

ENV QT_ANDROID_DIR=/opt/Qt/${QT_VERSION}/android

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates curl wget unzip git build-essential pkg-config \
    python3 python3-pip python3-venv \
    libwebsocketpp-dev libprotobuf-dev protobuf-compiler libcurl4-gnutls-dev libboost1.88-all-dev  \
    locales sudo nano mc openjdk-17-jdk-headless cmake ninja-build zip unzip \
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
    usermod -aG docker $USERNAME && \
    usermod -aG systemd-journal $USERNAME


RUN chown -R vscode:vscode /opt

# entry-point
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod u+rwx,g+rx,o+rx /usr/local/bin/docker-entrypoint

USER vscode

### Android stuff

# Create sdk root
RUN mkdir -p ${ANDROID_SDK_ROOT}

# Install Android command line tools
WORKDIR /tmp
RUN curl -fSL https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -o cmdline-tools.zip \
  && unzip cmdline-tools.zip -d /tmp \
  && mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
  && if [ -d /tmp/cmdline-tools ]; then \
       mv /tmp/cmdline-tools/* ${ANDROID_SDK_ROOT}/cmdline-tools/latest/; \
     else \
       mv /tmp/commandlinetools* ${ANDROID_SDK_ROOT}/cmdline-tools/latest/ || true; \
     fi \
  && rm -rf /tmp/cmdline-tools* cmdline-tools.zip

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Install SDK components (platform-tools, build-tools, ndk)
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses || true
RUN ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-31" "build-tools;33.0.2" "ndk;${ANDROID_NDK_VERSION}" "cmake;3.22.1"

# Install Gradle (binary distribution)
RUN mkdir -p /opt/gradle \
  && curl -fSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o /tmp/gradle.zip \
  && unzip /tmp/gradle.zip -d /opt/gradle \
  && rm /tmp/gradle.zip

# install aqtinstall
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip
RUN pip install aqtinstall

RUN mkdir -p /opt/Qt

# install Qt for Android
RUN cd /opt/Qt &&aqt install-qt all_os android ${QT_VERSION} android_${ANDROID_ARCH} --autodesktop --modules qt3d qt5compat qtcharts qtconnectivity qtdatavis3d qtgraphs qtgrpc qthttpserver qtimageformats qtlocation qtlottie qtmultimedia qtnetworkauth qtpositioning qtquick3d qtquick3dphysics qtquicktimeline qtremoteobjects qtscxml qtsensors qtserialbus qtserialport qtshadertools qtspeech qtvirtualkeyboard qtwebchannel qtwebsockets qtwebview
ENV QT_ANDROID_DIR=/opt/Qt/${QT_VERSION}/android_${ANDROID_ARCH}

# boost & openssl for android
RUN git clone https://github.com/microsoft/vcpkg.git /opt/vcpkg
RUN /opt/vcpkg/bootstrap-vcpkg.sh && \
  /opt/vcpkg/vcpkg install boost-system:${ANDROID_ARCH}-android \
  boost-filesystem:${ANDROID_ARCH}-android \
  boost-thread:${ANDROID_ARCH}-android boost-regex:${ANDROID_ARCH}-android \
  boost-chrono:${ANDROID_ARCH}-android \
  boost-date-time:${ANDROID_ARCH}-android boost-serialization:${ANDROID_ARCH}-android \
  boost-asio:${ANDROID_ARCH}-android \
  boost-iostreams:${ANDROID_ARCH}-android \
  boost-program-options:${ANDROID_ARCH}-android \
  openssl:${ANDROID_ARCH}-android \
  curl:${ANDROID_ARCH}-android \
  protobuf:${ANDROID_ARCH}-android

### ###

RUN cd /opt && git clone https://github.com/pokerth/pokerth.git && cd pokerth && git checkout android-build
# RUN cd /opt/pokerth && bash docker/android/build_android.sh

# Entrypoint/Command used from docker-compose.yml
# ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]