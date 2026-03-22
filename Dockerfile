# Use Official Ubuntu 20.04 for ARM64
FROM arm64v8/ubuntu:20.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install "Helpful development tools & libraries"
# [Fix] libjpeg62-turbo-dev -> libjpeg-turbo8-dev
# [Fix] magics++ -> libmagics++-dev
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git wget python3 ninja-build libopenal-dev premake4 autoconf \
    libevdev-dev ffmpeg libboost-all-dev pkg-config zlib1g-dev libsdl-mixer1.2-dev \
    libsdl1.2-dev libsdl-gfx1.2-dev libsdl2-mixer-dev clang cmake libmagics++-dev \
    liba52-0.7.4-dev libjpeg-turbo8-dev libfaad-dev libsdl2-net-dev \
    libfribidi-dev libglew-dev libtheora-dev libcurl4-openssl-dev libmpeg2-4-dev libgif-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Build Custom SDL 2.26.2
RUN rm -f /usr/lib/aarch64-linux-gnu/libSDL2.* && \
    wget https://github.com/libsdl-org/SDL/archive/refs/tags/release-2.26.2.tar.gz && \
    tar -xzf release-2.26.2.tar.gz && cd SDL-release-2.26.2 && \
    ./configure --prefix=/usr --disable-video-x11 --disable-pulseaudio --disable-esd && \
    make -j$(nproc) && make install && ldconfig && cd .. && rm -rf SDL-release-2.26.2

# 3. Build FluidSynth v2.3.4
RUN git clone --recursive https://github.com/FluidSynth/fluidsynth.git && \
    cd fluidsynth && git checkout v2.3.4 && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DLIB_SUFFIX="" .. && \
    make -j$(nproc) && make install && ldconfig && cd ../.. && rm -rf fluidsynth

WORKDIR /work
