#!/usr/bin/env bash

do_locale() {
  section "Configuring locale"

  arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

# ── Timezone ──────────────────────────────────────────────
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc
echo "Timezone set to ${TIMEZONE}"

# ── Locale ────────────────────────────────────────────────
sed -i "s/^#${LOCALE_LANG}/${LOCALE_LANG}/" /etc/locale.gen
locale-gen
echo "LANG=${LOCALE_LANG}" > /etc/locale.conf
echo "Locale set to ${LOCALE_LANG}"

# ── Hostname ──────────────────────────────────────────────
echo "${HOSTNAME}" > /etc/hostname
echo "Hostname set to ${HOSTNAME}"
EOF

  log "Locale configured"
  return 0
}