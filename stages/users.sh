#!/usr/bin/env bash

do_users() {
  section "Configuring user"

  arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

# ── User ──────────────────────────────────────────────────
id "${USERNAME}" &>/dev/null || useradd -mG ${USERGROUPS} ${USERNAME}
echo "User ${USERNAME} created or already exists"

# ── sudo ──────────────────────────────────────────────────
grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers || \
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "sudo configured for wheel group"
EOF

  log "User configured"
  return 0
}

do_passwords() {
  section "Setting passwords"

  echo "root:${ROOT_HASH}" | arch-chroot /mnt chpasswd -e
  echo "${USERNAME}:${USER_HASH}" | arch-chroot /mnt chpasswd -e
  log "Passwords set"
  return 0
}