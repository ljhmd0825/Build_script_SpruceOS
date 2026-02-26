#!/bin/bash

# Target: A523 (Cortex-A55) TSPS
export DEVICE=A523
export ARCH=arm64

# Path settings
export XTOOL="$HOME/x-tools/sdk_tg5050_linux_v1.0.0/host"
export XHOSTP="aarch64-none-linux-gnu"
export XBIN="$XTOOL/bin"
export LD_LIBRARY_PATH="$XTOOL/lib:$LD_LIBRARY_PATH"
export PATH="$XBIN:$PATH"

# Sysroot settings
export SYSROOT="$XTOOL/aarch64-buildroot-linux-gnu/sysroot"
export DESTDIR="$SYSROOT"

# Cross-Compile Prefix
export CROSS_COMPILE="$XBIN/$XHOSTP-"

# Specifying compilers and Toolchain binaries
export CC="$XBIN/$XHOSTP-gcc"
export CXX="$XBIN/$XHOSTP-g++"
export AS="$XBIN/$XHOSTP-as"
export AR="$XBIN/$XHOSTP-ar"
export LD="$XBIN/$XHOSTP-ld"
export STRIP="$XBIN/$XHOSTP-strip"
export RANLIB="$XBIN/$XHOSTP-ranlib"

# Build flags
export CPP_FLAGS="--sysroot=$SYSROOT -I$SYSROOT/usr/include"
export LD_FLAGS="--sysroot=$SYSROOT -L$SYSROOT/lib -L$SYSROOT/usr/lib"
export CPPFLAGS="$CPP_FLAGS"
export LDFLAGS="$LD_FLAGS"
export CFLAGS="-mcpu=cortex-a55 -O3 $CPP_FLAGS"
export CXXFLAGS="$CFLAGS"

# Build Helpers
export PKG_CONFIG_SYSROOT_DIR="$SYSROOT"
export PKG_CONFIG_PATH="$SYSROOT/usr/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$PKG_CONFIG_PATH"

echo "=========================================="
echo "🛡️  TSPS (A523)  Toochain load"
echo "CC      : $CC"
echo "AS      : $AS"
echo "SYSROOT : $SYSROOT"
echo "=========================================="