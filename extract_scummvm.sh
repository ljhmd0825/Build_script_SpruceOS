#!/bin/bash
set -ex

LABEL=$1
BUILD_DATE=$2
OUT_DIR="OUT_DIR_${LABEL}"
ARCHIVE_NAME="scummvm_AARCH64_${LABEL,,}_${BUILD_DATE}.7z"

mkdir -p ./${OUT_DIR}/libs ./${OUT_DIR}/Theme ./${OUT_DIR}/Extra/shaders ./${OUT_DIR}/LICENSES

cp -f src/scummvm ./${OUT_DIR}/
cp -f src/LICENSES/* ./${OUT_DIR}/LICENSES/
cp -f src/gui/themes/*.dat src/gui/themes/*.zip ./${OUT_DIR}/Theme/
cp -f src/dists/networking/wwwroot.zip ./${OUT_DIR}/Theme/
cp -f -r src/dists/engine-data/* ./${OUT_DIR}/Extra/
cp -f src/backends/vkeybd/packs/*.zip ./${OUT_DIR}/Extra/
cp -f src/dists/soundfonts/Roland_SC-55.sf2 ./${OUT_DIR}/Extra/
find src/engines/ -type f \( -name '*.fragment' -o -name '*.vertex' \) -exec cp -f {} ./${OUT_DIR}/Extra/shaders/ \;

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
  "libsqlite3.so.0" "libssh.so.4" "libssl.so.1.1" "libtasn1.so.6"
  "libunistring.so.2" "libwind.so.0" "libz.so.1"
)

for LIB_NAME in "${LIBS[@]}"; do
  LIB_PATH=$(find /usr/lib/aarch64-linux-gnu /usr/lib -name "$LIB_NAME" -print -quit)
  if [ -n "$LIB_PATH" ]; then
    cp -L "$LIB_PATH" "./${OUT_DIR}/libs/$LIB_NAME"
  fi
done

7z a -t7z -m0=lzma2 -mx=9 "${ARCHIVE_NAME}" "./${OUT_DIR}/*"
