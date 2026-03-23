#!/usr/bin/env bash

do_chroot() {
  section "Configuring system (chroot)"

  cat > /mnt/root/chroot-setup.sh <<EOF
#!/bin/bash
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

# ── mkinitcpio ────────────────────────────────────────────
if [[ "${LUKS_ENABLED}" == "true" ]]; then
  sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/' /etc/mkinitcpio.conf
  mkinitcpio -P
  echo "mkinitcpio updated with encrypt hook"
fi

# ── Enable NetworkManager ─────────────────────────────────
systemctl enable NetworkManager
echo "NetworkManager enabled"

# ── User ──────────────────────────────────────────────────
useradd -mG ${USERGROUPS} ${USERNAME}
echo "User ${USERNAME} created"

# Allow wheel group to use sudo
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "sudo configured for wheel group"
EOF

  chmod +x /mnt/root/chroot-setup.sh
  arch-chroot /mnt /root/chroot-setup.sh
  rm /mnt/root/chroot-setup.sh

  # Set passwords directly outside chroot
  echo "root:${ROOT_HASH}" | arch-chroot /mnt chpasswd -e
  echo "${USERNAME}:${USER_HASH}" | arch-chroot /mnt chpasswd -e
  log "Passwords set"

  log "Chroot configuration complete"
}