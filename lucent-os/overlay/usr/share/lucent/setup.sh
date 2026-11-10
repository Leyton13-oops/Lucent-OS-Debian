#!/usr/bin/env bash
# Lucent OS shared setup. Runs as root, either inside the ISO build chroot
# or on an installed Debian 13 (trixie) GNOME system.
#
# Optional steps are best-effort on purpose: a failed theme download warns and
# carries on instead of breaking the whole build.
set -uo pipefail

LUCENT_DIR=/usr/share/lucent
# shellcheck source=/dev/null
. "$LUCENT_DIR/os.conf"

export DEBIAN_FRONTEND=noninteractive
# WhiteSur's installer needs a user name and sudo, and chroots have neither set up.
export USER=root SUDO_USER=root HOME="${HOME:-/root}"

log()  { printf '[lucent] %s\n' "$*"; }
warn() { printf '[lucent] WARNING: %s\n' "$*" >&2; }

install_extras() {
  log "Installing optional packages"
  apt-get update -qq || warn "apt update failed"
  local pkg
  while read -r pkg; do
    [[ -z $pkg || $pkg == \#* ]] && continue
    if apt-get install -y "$pkg" >/dev/null 2>&1; then log "  + $pkg"; else warn "  skipped $pkg"; fi
  done < "$LUCENT_DIR/packages-extra.txt"
}

install_wine32() {
  log "Enabling 32-bit Windows app support"
  dpkg --add-architecture i386
  apt-get update -qq || true
  apt-get install -y wine32 >/dev/null 2>&1 \
    || apt-get install -y wine32:i386 >/dev/null 2>&1 \
    || warn "wine32 unavailable; some 32-bit Windows apps may not run"
}

install_themes() {
  log "Installing WhiteSur themes (needs internet)"
  local tmp ref=()
  tmp=$(mktemp -d)
  [[ -n ${WHITESUR_REF:-} ]] && ref=(--branch "$WHITESUR_REF")

  if git clone --depth=1 -q "${ref[@]}" https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$tmp/gtk" \
     && (cd "$tmp/gtk" && bash ./install.sh -d /usr/share/themes -o normal -c light -c dark -N glassy); then
    log "  GTK and GNOME Shell themes installed"
  else
    warn "WhiteSur GTK theme failed; the default GNOME theme will be used"
  fi

  if git clone --depth=1 -q "${ref[@]}" https://github.com/vinceliuice/WhiteSur-icon-theme.git "$tmp/icons" \
     && (cd "$tmp/icons" && bash ./install.sh -d /usr/share/icons); then
    log "  Icon theme installed"
  else
    warn "WhiteSur icon theme failed; the default icons will be used"
  fi
  rm -rf "$tmp"
}

apply_dconf() {
  log "Compiling desktop defaults"
  local profile=/etc/dconf/profile/user
  mkdir -p /etc/dconf/profile
  [[ -f $profile ]] || echo 'user-db:user' > "$profile"
  grep -qx 'system-db:local' "$profile" || echo 'system-db:local' >> "$profile"
  dconf update || warn "dconf update failed"
}

apply_branding() {
  log "Applying $OS_NAME branding"
  if [[ -f /usr/lib/os-release ]]; then
    # Keep ID=debian so Debian tooling keeps working; identify as a variant instead.
    sed -e '/^PRETTY_NAME=/d' -e '/^VARIANT=/d' -e '/^VARIANT_ID=/d' /usr/lib/os-release > /etc/os-release.lucent
    {
      printf 'PRETTY_NAME="%s %s (based on Debian 13)"\n' "$OS_NAME" "$OS_VERSION"
      printf 'VARIANT="%s"\nVARIANT_ID=%s\n' "$OS_NAME" "$OS_ID"
    } >> /etc/os-release.lucent
    rm -f /etc/os-release
    mv /etc/os-release.lucent /etc/os-release
  fi
  if [[ -f /etc/default/grub ]]; then
    if grep -q '^GRUB_DISTRIBUTOR=' /etc/default/grub; then
      sed -i "s|^GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR=\"$OS_NAME\"|" /etc/default/grub
    else
      echo "GRUB_DISTRIBUTOR=\"$OS_NAME\"" >> /etc/default/grub
    fi
  fi
  # Installer launcher and wording, if present.
  if [[ -f /usr/share/applications/install-debian.desktop ]]; then
    sed -i "s/^Name=.*/Name=Install $OS_NAME/" /usr/share/applications/install-debian.desktop
  fi
  find /etc/calamares /usr/share/calamares -name branding.desc -print0 2>/dev/null \
    | xargs -0 -r sed -i -E "s/^([[:space:]]*(productName|shortProductName|versionedName|shortVersionedName|bootloaderEntryName):[[:space:]]*).*/\1$OS_NAME/" \
    || true
}

refresh_caches() {
  chmod 0755 /usr/local/bin/lucent-* 2>/dev/null || true
  gtk-update-icon-cache -qf /usr/share/icons/hicolor 2>/dev/null || true
  update-desktop-database -q 2>/dev/null || true
  glib-compile-schemas /usr/share/glib-2.0/schemas 2>/dev/null || true
}

main() {
  [[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }
  install_extras
  install_wine32
  install_themes
  apply_dconf
  apply_branding
  refresh_caches
  [[ ${1:-} == --chroot ]] && apt-get clean
  log "Setup finished."
}

main "$@"
