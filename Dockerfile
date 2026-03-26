FROM arm64v8/ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/lib/ccache:$PATH"
ENV CCACHE_DIR=/root/.ccache

# 1. Install EXACT list from your guide
# Added 'ca-certificates' and 'p7zip-full' to ensure zero-host-dependency
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && \
    apt-get install -y --no-install-recommends \
    build-essential git wget ccache libdrm-dev python3 python3-pip python3-setuptools python3-wheel \
    ninja-build libopenal-dev premake4 autoconf automake libevdev-dev ffmpeg libboost-tools-dev \
    libboost-thread-dev libboost-all-dev pkg-config zlib1g-dev clang cmake cmake-data \
    libarchive13 libcurl4 libfreetype6-dev librhash0 libuv1 mercurial mercurial-common \
    libgbm-dev libsdl-image1.2-dev liba52-0.7.4-dev libjpeg62-dev libspeechd-dev libfaad-dev \
    libsdl2-net-dev libfribidi-dev libglew-dev libtheora-dev libcurl4-openssl-dev \
    libmpeg2-4-dev libgif-dev libreadline-dev libexpat1-dev libasound2-dev \
    libslang2-dev libncurses5-dev libncursesw5-dev p7zip-full && \
# magics++
    apt-get install -y --no-install-recommends libmagics++-dev && \
# 2. Build Custom SDL 2.26.2
    rm -f /usr/lib/aarch64-linux-gnu/libSDL2.* && \
    wget https://github.com/libsdl-org/SDL/archive/refs/tags/release-2.26.2.tar.gz && \
    tar -xzf release-2.26.2.tar.gz && cd SDL-release-2.26.2 && \
    ./configure --prefix=/usr --disable-video-x11 --disable-pulseaudio --disable-esd && \
    make -j$(nproc) && make install && ldconfig && cd .. && rm -rf SDL-release-2.26.2 && \
# 3. Build FluidSynth v2.3.4
    git clone --recursive https://github.com/FluidSynth/fluidsynth.git && \
    cd fluidsynth && git checkout v2.3.4 && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DLIB_SUFFIX="" -DENABLE_READLINE=OFF -DENABLE_LASH=OFF -DENABLE_JACK=OFF .. && \
    make -j$(nproc) && make install && ldconfig && cd ../.. && rm -rf fluidsynth && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /work
