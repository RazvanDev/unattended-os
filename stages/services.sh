#!/usr/bin/env bash

do_services() {
  section "Configuring services"

  arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

# ── NetworkManager ────────────────────────────────────────
systemctl enable NetworkManager
echo "NetworkManager enabled"

# ── SSH ───────────────────────────────────────────────────
systemctl enable sshd
echo "sshd enabled"
EOF

  log "Services configured"
  return 0
}