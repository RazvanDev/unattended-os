#!/usr/bin/env bash

do_initramfs() {
  section "Configuring initramfs"

  arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

if [[ "${LUKS_ROOT}" == "true" || "${LUKS_HOME}" == "true" || \
      "${LUKS_SWAP}" == "true" || "${LUKS_MEDIA}" == "true" ]]; then
  sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/' /etc/mkinitcpio.conf
  mkinitcpio -P
  echo "mkinitcpio updated with encrypt hook"
else
  echo "No encryption — skipping mkinitcpio rebuild"
fi
EOF

  log "initramfs configured"
  return 0
}