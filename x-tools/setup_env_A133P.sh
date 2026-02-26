#!/bin/bash

# Target: A133P (Cortex-A53) TSP Brick
export DEVICE=A133P
export ARCH=arm64

# Path settings
export XTOOL="$HOME/x-tools/aarch64-linux-gnu-7.5.0-linaro"
export XHOSTP="aarch64-linux-gnu"
export XBIN="$XTOOL/bin"
export PATH="$XBIN:$PATH"

# Sysroot settings
export SYSROOT="$XTOOL/aarch64-linux-gnu/libc"

# Cross-Compile Prefix
export CROSS_COMPILE="$XBIN/$XHOSTP-"

# Specifying compilers - [Assigning sysroot to compiler]
export CC="$CROSS_COMPILE"gcc
export CXX="$CROSS_COMPILE"g++
export AS="$CROSS_COMPILE"as
export AR="$CROSS_COMPILE"ar
export LD="$CROSS_COMPILE"ld
export STRIP="$CROSS_COMPILE"strip
export RANLIB="$CROSS_COMPILE"ranlib
export NM="$CROSS_COMPILE"nm

# Build flags - [Remove duplicates]
# Since CC/CXX already has a sysroot, we only leave the architecture option here.
export COMMON_FLAGS="--sysroot=$SYSROOT -march=armv8-a+simd -mtune=cortex-a53"

# -pipe removal and optimization options sorting
export CFLAGS="$COMMON_FLAGS -O3"
export CXXFLAGS="$CFLAGS"

# Leave FLAGS empty to prevent configure from creating duplicate paths.
export CPPFLAGS=""
export LDFLAGS=""

# Build Helpers
export PKG_CONFIG_PATH=""
export PKG_CONFIG_LIBDIR="$SYSROOT/usr/lib/pkgconfig:$SYSROOT/usr/share/pkgconfig"
export PKG_CONFIG_SYSROOT_DIR="$SYSROOT"

# SDL2 dedicated path
export SDL2_CONFIG="$SYSROOT/usr/bin/sdl2-config"

echo "=========================================="
echo "TSP(A133P) Fixed Toolchain loaded"
echo "CC      : $CC"
echo "SYSROOT : $SYSROOT"
echo "=========================================="