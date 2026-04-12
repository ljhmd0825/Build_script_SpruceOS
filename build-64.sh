#!/bin/bash
set -e

SCUMMVM_VERSION="${SCUMMVM_VERSION:-v2.8.1}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
EMU_DIR="$OUTPUT_DIR/Emu/SCUMMVM"
LIB_DIR="$OUTPUT_DIR/lib"
LOGS_DIR="$OUTPUT_DIR/logs"

echo "=== Building ScummVM ${SCUMMVM_VERSION} for aarch64 (universal 64-bit) ==="

# Clone ScummVM
if [ ! -d "scummvm" ]; then
    git clone -b branch-2-8-1 https://github.com/british-choi/scummvm.git
fi

cd scummvm

# Cross-compilation environment
export CC="ccache aarch64-linux-gnu-gcc"
export CXX="ccache aarch64-linux-gnu-g++"
export AR="aarch64-linux-gnu-ar"
export STRIP="aarch64-linux-gnu-strip"
export PKG_CONFIG_PATH="/usr/lib/aarch64-linux-gnu/pkgconfig"
export PKG_CONFIG_LIBDIR="/usr/lib/aarch64-linux-gnu/pkgconfig"
export CCACHE_DIR="${CCACHE_DIR:-/ccache}"

# Configure for universal 64-bit: SDL2 + OpenGL ES2, all engines
./configure \
    --host=aarch64-linux-gnu \
    --backend=sdl \
    --disable-all-engines \
    --enable-engine=grim \
    --enable-optimizations \
    --enable-release \
    --disable-debug \
    --disable-eventrecorder \
    --enable-vkeybd \
    --enable-fluidsynth

# Build
make -j$(nproc)

# Output
mkdir -p "$EMU_DIR/LICENSES" "$EMU_DIR/Theme" "$EMU_DIR/Extra"
mkdir -p "$LIB_DIR"
mkdir -p "$LOGS_DIR"

# Binary & Strip
cp scummvm "$EMU_DIR/scummvm.64"
aarch64-linux-gnu-strip "$EMU_DIR/scummvm.64"

# Assets copy
cp -f LICENSES/* "$EMU_DIR/LICENSES/"
[ -f dists/soundfonts/COPYRIGHT.Roland_SC-55 ] && cp -f dists/soundfonts/COPYRIGHT.Roland_SC-55 "$EMU_DIR/LICENSES/"
cp -f gui/themes/*.dat gui/themes/*.zip "$EMU_DIR/Theme/"
cp -f dists/networking/wwwroot.zip "$EMU_DIR/Theme/"
cp -f -r dists/engine-data/* "$EMU_DIR/Extra/"
rm -rf "$EMU_DIR/Extra/patches" "$EMU_DIR/Extra/testbed-audiocd-files"
rm -f "$EMU_DIR/Extra/README" "$EMU_DIR/Extra/"*.mk "$EMU_DIR/Extra/"*.sh
cp -f backends/vkeybd/packs/vkeybd_default.zip "$EMU_DIR/Extra/"
cp -f backends/vkeybd/packs/vkeybd_small.zip "$EMU_DIR/Extra/"
[ -f dists/soundfonts/Roland_SC-55.sf2 ] && cp -f dists/soundfonts/Roland_SC-55.sf2 "$EMU_DIR/Extra/"

mkdir -p "$EMU_DIR/Extra/shaders"
find engines/ -type f \( -name "*.fragment" -o -name "*.vertex" \) -exec cp -f {} "$EMU_DIR/Extra/shaders/" \;

# Library Collection (Targeting $LIB_DIR)
LIBS=(
  "liba52-0.7.4.so" "libasn1.so.8" "libasound.so.2" "libbrotlicommon.so.1"
  "libbrotlidec.so.1" "libbsd.so.0" "libcom_err.so.2" "libcrypt.so.1"
  "libcrypto.so.1.1" "libcurl.so.4" "libcurl-gnutls.so.4" "libfaad.so.2"
  "libffi.so.7" "libFLAC.so.8" "libfluidsynth.so.3" "libfreetype.so.6"
  "libfribidi.so.0" "libgif.so.7" "libgmp.so.10" "libgnutls.so.30"
  "libgssapi.so.3" "libgssapi_krb5.so.2" "libhcrypto.so.4" "libheimbase.so.1"
  "libheimntlm.so.0" "libhogweed.so.5" "libhx509.so.5" "libidn2.so.0"
  "libk5crypto.so.3" "libkeyutils.so.1" "libkrb5.so.3" "libkrb5.so.26"
  "libkrb5support.so.0" "liblber-2.4.so.2" "libldap_r-2.4.so.2" "liblzma.so.5"
  "libmikmod.so.3" "libmpeg2.so.0" "libnettle.so.7" "libnghttp2.so.14"
  "libp11-kit.so.0" "libpng16.so.16" "libpsl.so.5" "libroken.so.18"
  "librtmp.so.1" "libsasl2.so.2" "libsndio.so.7.0" "libspeechd.so.2"
  "libsqlite3.so.0" "libssh.so.4" "libssl.so.1.1" "libtasn1.so.6" "libreadline.so.8"
  "libunistring.so.2" "libwind.so.0" "libz.so.1" "libvpx.so.6" "libopenmpt.so.0"
)

for lib in "${LIBS[@]}"; do
    TARGET=$(find /usr/lib/aarch64-linux-gnu -name "$lib*" -print -quit)
    if [ -n "$TARGET" ]; then
        cp -L "$TARGET" "$LIB_DIR/$lib"
    fi
done

# Logs
cp -f configure_summary.txt config.log config.h config.mk "$LOGS_DIR/"

# Archive (Include Emu, lib, logs as top-level)
cd "$OUTPUT_DIR"

BUILD_DATE=$(date +%m%d)
OUT_FILENAME="scummvm.${BUILD_TYPE}.${BUILD_DATE}.7z"
7z a -t7z -m0=lzma2 -mx=9 "$OUT_FILENAME" Emu/ lib/ logs/

echo "=== Build complete: ${OUTPUT_DIR}/${OUT_FILENAME} ==="
