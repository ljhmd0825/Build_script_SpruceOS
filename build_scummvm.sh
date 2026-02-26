#!/bin/bash

# shellcheck source=/dev/null

# ==== About ====
# ScummVM build script for SpruceOS / TrimUI Smart Pro S
# Stop if any command fails
set -e

# 1. Target device collection
DEVICE="${1:-}"
if [[ -z "$DEVICE" ]]; then
    echo "Usage: $0 <DEVICE> (A133P, A523)" >&2
    exit 1
fi

# Device-specific build environment settings
case "$DEVICE" in
  A133P)
    TOOLCHAIN_SCRIPT="$HOME/x-tools/setup_env_A133P.sh"
    SVM_BIN="scummvm_a133p"
    ;;
  A523)
    TOOLCHAIN_SCRIPT="$HOME/x-tools/setup_env_A523.sh"
    SVM_BIN="scummvm_a523"
    ;;
  *)
    echo "Error: Unknown device '$DEVICE'. Supported: A133P, A523" >&2
    exit 1
    ;;
esac

# ===== Repo & Directory Settings =====
REPO_URL="https://github.com/scummvm/scummvm.git"
REPO_DIR="scummvm"
BRANCH="branch-2026-1-0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$SCRIPT_DIR/scummvm/output"

# ===== Init Toolchain =====
echo "[Step 01] Loading toolchain environment..."
if [ ! -f "$TOOLCHAIN_SCRIPT" ]; then
    echo "Error: Toolchain script not found at $TOOLCHAIN_SCRIPT" >&2
    exit 1
fi
. "$TOOLCHAIN_SCRIPT"

echo "[Step 02] Checking toolchain health..."
$CC --version | head -n 1

# ===== Start =====
echo "[Step 03] Fresh Cloning ScummVM Repository (Target: $BRANCH)..."

# 1.Always delete the repo
if [ -d "$REPO_DIR" ]; then
    echo "Removing old source to ensure a clean environment..."
    rm -rf "$REPO_DIR"
fi

# 2. cloning the repo
git clone --depth 1 --branch "$BRANCH" --recurse-submodules -j"$(nproc)" "$REPO_URL" "$REPO_DIR"
cd "$REPO_DIR"

# ===== [Step 04] Apply Patches =====
PATCH_DIR="$SCRIPT_DIR/patches"
if [ -d "$PATCH_DIR" ]; then
    echo "[Step 4] Applying patches from $PATCH_DIR..."
    for patch_file in "$PATCH_DIR/${REPO_DIR}"*.patch; do
        if [ -f "$patch_file" ]; then
            echo "Applying patch: $(basename "$patch_file")"
            git apply --ignore-whitespace "$patch_file"
        fi
    done
fi

# [Step 05] Configuring ScummVM
echo "[Step 05] Configuring ScummVM..."

if [ "$DEVICE" == "A133P" ]; then
    echo "🛡️ A133P: Direct Forensic Path Injection (ncurses Resolved)..."

    SYSROOT="/home/ark/x-tools/aarch64-linux-gnu-7.5.0-linaro/aarch64-linux-gnu/libc"
    # 1. Setting environment variables
    export LDFLAGS="--sysroot=${SYSROOT} -L${SYSROOT}/lib -L${SYSROOT}/usr/lib -Wl,-rpath-link,${SYSROOT}/lib -Wl,-rpath-link,${SYSROOT}/usr/lib -lncurses"
    export PKG_CONFIG_SYSROOT_DIR="${SYSROOT}"
    export PKG_CONFIG_LIBDIR="${SYSROOT}/usr/lib/pkgconfig"

    # 2. Run configure (inject ncurses and remove ghosts)
    # Remove -lintl and -liconv, as they are not present on our system.
    # Inject -lncurses, which has been verified to be present, to prevent libreadline from complaining.
    FLUIDSYNTH_CFLAGS="-I${SYSROOT}/usr/include -I${SYSROOT}/usr/include/fluidsynth" \
    FLUIDSYNTH_LIBS="-L${SYSROOT}/usr/lib -lfluidsynth -lglib-2.0 -lpcre -lncurses -lm -lpthread" \
    ./configure --host=aarch64-linux-gnu \
                --with-sdl-prefix="${SYSROOT}/usr" \
                --enable-release \
                --enable-all-engines \
                --enable-vkeybd \
                --enable-ext-neon \
                --opengl-mode=gles2 \
                --disable-taskbar \
                --enable-text-console \
                --disable-dlc \
                --disable-scummvmdlc \
                --enable-freetype2 \
                --enable-fribidi \
                --enable-fluidsynth \
                --disable-readline \
                --with-fluidsynth-prefix="${SYSROOT}/usr" \
                --with-png-prefix="${SYSROOT}/usr" \
                --with-zlib-prefix="${SYSROOT}/usr" \
                --with-jpeg-prefix="${SYSROOT}/usr"

elif [ "$DEVICE" == "A523" ]; then
    echo "🛡️ A523: Configuring"

    ./configure \
      --host=aarch64-none-linux-gnu \
      --with-sdl-prefix="$SYSROOT/usr" \
      --with-freetype2-prefix="$SYSROOT/usr" \
      --with-libcurl-prefix="$SYSROOT/usr" \
      --enable-release \
      --disable-debug \
      --enable-vkeybd \
      --enable-ext-neon \
      --opengl-mode=gles2 \
      --disable-taskbar \
      --enable-text-console \
      --enable-dlc \
      --enable-scummvmdlc \
      --enable-freetype2 \
      --enable-fluidsynth \
      --enable-all-engines
fi

echo "[Step 06] Building ScummVM..."
make -j"$(nproc)"

echo "[Step 07] Preparing Binary..."
$STRIP "scummvm"
mv "scummvm" "$SVM_BIN"
md5sum "$SVM_BIN" | cut -d ' ' -f 1 > "$SVM_BIN.md5"
tar -czf "${SVM_BIN}.tar.gz" "$SVM_BIN"

echo "[Step 08] Bundling all required files..."
mkdir -p "$OUT_DIR/LICENSES" "$OUT_DIR/Theme" "$OUT_DIR/Extra"

cp -f "${SVM_BIN}.tar.gz" "${SVM_BIN}.md5" "$OUT_DIR/"
cp -f LICENSES/* "$OUT_DIR/LICENSES/"
[ -f dists/soundfonts/COPYRIGHT.Roland_SC-55 ] && cp -f dists/soundfonts/COPYRIGHT.Roland_SC-55 "$OUT_DIR/LICENSES/"
cp -f gui/themes/*.dat gui/themes/*.zip "$OUT_DIR/Theme/"
cp -f dists/networking/wwwroot.zip "$OUT_DIR/Theme/"
cp -f -r dists/engine-data/* "$OUT_DIR/Extra/"
rm -rf "$OUT_DIR/Extra/patches"
rm -rf "$OUT_DIR/Extra/testbed-audiocd-files"
rm -f "$OUT_DIR/Extra/README"
rm -f "$OUT_DIR/Extra/"*.mk
rm -f "$OUT_DIR/Extra/"*.sh
cp -f backends/vkeybd/packs/vkeybd_default.zip "$OUT_DIR/Extra/"
cp -f backends/vkeybd/packs/vkeybd_small.zip "$OUT_DIR/Extra/"
[ -f dists/soundfonts/Roland_SC-55.sf2 ] && cp -f dists/soundfonts/Roland_SC-55.sf2 "$OUT_DIR/Extra/"
mkdir -p "$OUT_DIR/Extra/shaders"
find engines/ -type f \( -name "*.fragment" -o -name "*.vertex" \) -exec cp -f {} "$OUT_DIR/Extra/shaders/" \;

echo "[Step 09] Creating Final Assets Archive..."
# Run in a subshell to keep the path inside the compressed file clean with only Theme, Extra, and LICENSES.
(cd "$OUT_DIR" && 7z a scummvm_assets.7z Theme Extra LICENSES)

# ===== Cleanup =====
rm -f "$SVM_BIN" "${SVM_BIN}.md5" "${SVM_BIN}.tar.gz"

echo "Build complete. Files are in $OUT_DIR"