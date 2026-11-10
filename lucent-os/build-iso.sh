#!/usr/bin/env bash
# Build the Lucent OS installer ISO.
#
#   ./build-iso.sh docker    build inside a Debian 13 container (needs Docker; easiest)
#   sudo ./build-iso.sh      build directly on a Debian machine
#
# Needs roughly 20 GB of free disk and an internet connection. Takes 30-60 minutes.
# Result: out/lucent-os-*.iso (plus SHA256SUMS)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
ROOT=$PWD

if [[ ${1:-} == docker ]]; then
  command -v docker >/dev/null || { echo "Docker was not found. Install it, or use GitHub Actions (see README)." >&2; exit 1; }
  exec docker run --rm --privileged -v "$ROOT":/src -w /src debian:trixie bash build-iso.sh
fi

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo ./build-iso.sh) or use: ./build-iso.sh docker" >&2; exit 1; }

# shellcheck source=/dev/null
. overlay/usr/share/lucent/os.conf

if grep -qi '^ID=ubuntu' /etc/os-release 2>/dev/null; then
  echo "Note: building a Debian 13 image on Ubuntu can fail on package signing keys. ./build-iso.sh docker is safer." >&2
fi

if ! command -v lb >/dev/null; then
  apt-get update
  apt-get install -y live-build debootstrap squashfs-tools xorriso git ca-certificates
fi

WORK=${WORK:-/var/tmp/lucent-build}
rm -rf "$WORK"
mkdir -p "$WORK/config/package-lists" "$WORK/config/includes.chroot"
cp -a iso/. "$WORK"/
cp overlay/usr/share/lucent/os.conf "$WORK"/os.conf
cp -rT overlay "$WORK/config/includes.chroot"

# One package list: ISO-only packages plus the shared core list (comments stripped).
grep -hvE '^[[:space:]]*(#|$)' iso/live-packages.txt overlay/usr/share/lucent/packages-core.txt \
  > "$WORK/config/package-lists/lucent.list.chroot"

# Zip files and Windows checkouts lose the executable bit, so set it explicitly.
chmod +x "$WORK"/auto/* "$WORK"/config/hooks/live/* \
  "$WORK"/config/includes.chroot/usr/local/bin/* \
  "$WORK"/config/includes.chroot/usr/share/lucent/setup.sh

cd "$WORK"
lb config
lb build 2>&1 | tee build.log

mkdir -p "$ROOT/out"
shopt -s nullglob
isos=(./*.iso)
if [[ ${#isos[@]} -eq 0 ]]; then
  echo "The build finished but produced no ISO. See $WORK/build.log" >&2
  exit 1
fi
cp "${isos[@]}" "$ROOT/out/"
(cd "$ROOT/out" && sha256sum ./*.iso > SHA256SUMS)
echo "Done: $ROOT/out/"
