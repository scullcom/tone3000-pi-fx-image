#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ "$(uname -s)/$(uname -m)" == Linux/aarch64 ]] || {
  echo 'Build the image on 64-bit ARM Linux (for example, a Pi 5 running Raspberry Pi OS).' >&2
  exit 1
}
[[ "$repo" != *[[:space:]]* ]] || { echo 'Use a checkout path without whitespace.' >&2; exit 1; }
jobs=${T3K_IMAGE_JOBS:-2}
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || { echo 'T3K_IMAGE_JOBS must be a positive integer.' >&2; exit 1; }
cd "$repo"
mkdir -p .build dist
builder="$repo/.build/pi-gen"
version=2026-06-18-raspios-trixie-arm64
revision=ca8aeed0ae300c2a89f55ce9617d5f96a27e99e5
if [[ ! -d "$builder/.git" ]]; then
  git clone --depth 1 --branch "$version" https://github.com/RPi-Distro/pi-gen.git "$builder"
fi
[[ "$(git -C "$builder" rev-parse HEAD)" == "$revision" ]] ||
  { echo 'The image builder checkout is at an unexpected revision.' >&2; exit 1; }

touch "$builder/stage2/SKIP_IMAGES"
# pi-gen requires executable host scripts. Keep a staged copy for Git clients that omit file modes.
cp -R stage-kiosk patches "$builder/"
chmod +x "$builder/stage-kiosk/prerun.sh" "$builder/stage-kiosk/00-app/00-run.sh"
cat > "$builder/kiosk-config" <<EOF
IMG_NAME=tone3000-pi-fx
RELEASE=trixie
TARGET_HOSTNAME=tone3000-fx
KEYBOARD_KEYMAP=gb
KEYBOARD_LAYOUT='English (UK)'
ENABLE_SSH=0
DEPLOY_COMPRESSION=xz
COMPRESSION_LEVEL=3
CLEAN=1
STAGE_LIST='stage0 stage1 stage2 stage-kiosk'
DEPLOY_DIR='$repo/dist'
export T3K_IMAGE_JOBS=$jobs
EOF
cd "$builder"
sudo ./build.sh -c kiosk-config
cd "$repo/dist"
shopt -s nullglob
images=(*.img.xz)
(( ${#images[@]} )) || { echo 'pi-gen did not produce an image.' >&2; exit 1; }
for image in "${images[@]}"; do
  sha256sum -- "$image" > "$image.sha256"
done
