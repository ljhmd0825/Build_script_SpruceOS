# Use Official Ubuntu 20.04 for ARM64 (AARCH64)
FROM arm64v8/ubuntu:20.04

# Non-interactive mode to prevent hanging during build
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install EXACT list from your guide
# Added 'ca-certificates' first to ensure wget/git works without SSL issues
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && \
    apt-get install -y --no-install-recommends \
    build-essential git wget libdrm-dev python3 python3-pip python3-setuptools python3-wheel \
    ninja-build libopenal-dev premake4 autoconf libevdev-dev ffmpeg libboost-tools-dev \
    libboost-thread-dev libboost-all-dev pkg-config zlib1g-dev libsdl-mixer1.2-dev \
    libsdl1.2-dev libsdl-gfx1.2-dev libsdl2-mixer-dev clang cmake cmake-data \
    libarchive13 libcurl4 libfreetype6-dev librhash0 libuv1 mercurial mercurial-common \
    libgbm-dev libsdl-image1.2-dev \
    # Standard ScummVM additional deps
    liba52-0.7.4-dev libjpeg-turbo8-dev libfaad-dev libsdl2-net-dev \
    libfribidi-dev libglew-dev libtheora-dev libcurl4-openssl-dev libmpeg2-4-dev libgif-dev && \
    # Special handling for magics++ to avoid dependency breaks
    apt-get install -y --no-install-recommends libmagics++-dev || echo "Warning: magics++ failed, skipping..." && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Build Custom SDL 2.26.2 (As per your requirement)
RUN rm -f /usr/lib/aarch64-linux-gnu/libSDL2.* && \
    wget https://github.com/libsdl-org/SDL/archive/refs/tags/release-2.26.2.tar.gz && \
    tar -xzf release-2.26.2.tar.gz && cd SDL-release-2.26.2 && \
    ./configure --prefix=/usr --disable-video-x11 --disable-pulseaudio --disable-esd && \
    make -j$(nproc) && make install && ldconfig && cd .. && rm -rf SDL-release-2.26.2

# 3. Build FluidSynth v2.3.4 (As per your requirement)
RUN git clone --recursive https://github.com/FluidSynth/fluidsynth.git && \
    cd fluidsynth && git checkout v2.3.4 && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DLIB_SUFFIX="" .. && \
    make -j$(nproc) && make install && ldconfig && cd ../.. && rm -rf fluidsynth

WORKDIR /work
