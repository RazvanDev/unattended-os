#!/usr/bin/env bash

do_bootloader() {
  section "Installing bootloader"

  # ── Get root partition UUID ────────────────────────────
  ROOT_UUID=$(blkid -s UUID -o value "$PART_ROOT")
  HOME_UUID=$(blkid -s UUID -o value "$PART_HOME")
  SWAP_UUID=$(blkid -s UUID -o value "$PART_SWAP")

  arch-chroot /mnt /bin/bash <<EOF
# ── GRUB cryptdevice ──────────────────────────────────────
if [[ "${LUKS_ENABLED}" == "true" && "${LUKS_ROOT}" == "true" ]]; then
  sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${ROOT_UUID}:cryptroot root=/dev/mapper/cryptroot\"|" /etc/default/grub
  echo "GRUB cryptdevice configured"
fi

# ── crypttab ──────────────────────────────────────────────
if [[ "${LUKS_ENABLED}" == "true" ]]; then
  [[ "${LUKS_HOME}" == "true" ]] && echo "crypthome UUID=${HOME_UUID} none luks" >> /etc/crypttab
  [[ "${LUKS_SWAP}" == "true" ]] && echo "cryptswap UUID=${SWAP_UUID} none luks" >> /etc/crypttab
  echo "crypttab configured"
fi

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
echo "GRUB installed and configured"
EOF

  log "Bootloader installed"
}