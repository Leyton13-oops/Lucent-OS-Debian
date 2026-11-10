#!/usr/bin/env bash
# Turn an existing Debian 13 (trixie) GNOME install into Lucent OS.
#
#   sudo ./install-on-debian.sh
#
# Install Debian 13 with the GNOME desktop first (debian.org), then run this.
# Log out and back in afterwards to activate the shell extensions.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ $EUID -eq 0 ]] || exec sudo -E bash "$0" "$@"

# shellcheck source=/dev/null
. /etc/os-release
if [[ "${VERSION_CODENAME:-}" != trixie ]]; then
  echo "This needs Debian 13 (trixie) with GNOME. Found: ${PRETTY_NAME:-unknown}." >&2
  exit 1
fi

# winetricks and firmware live in contrib / non-free.
if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
  sed -i -E 's/^Components:.*/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
elif [[ -f /etc/apt/sources.list ]]; then
  sed -i -E '/^deb / s/ main( .*)?$/ main contrib non-free non-free-firmware/' /etc/apt/sources.list
fi

apt-get update
mapfile -t core < <(grep -hvE '^[[:space:]]*(#|$)' "$HERE/overlay/usr/share/lucent/packages-core.txt")
apt-get install -y task-gnome-desktop "${core[@]}"

# Copy the overlay into the system (owned by root, whoever unpacked the files).
cp -rT --no-preserve=ownership "$HERE/overlay" /
chmod 0755 /usr/local/bin/lucent-* /usr/share/lucent/setup.sh

# Existing accounts get the new look the first time they log in.
touch /usr/share/lucent/.apply-on-first-login

bash /usr/share/lucent/setup.sh

echo
echo "Lucent OS is installed. Log out and back in to see the new desktop."
