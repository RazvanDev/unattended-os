#!/usr/bin/env bash

do_services() {
  section "Configuring services"

  arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

# ── Enable services ───────────────────────────────────────
for svc in ${ENABLED_SERVICES}; do
  systemctl enable "\$svc"
  echo "\$svc enabled"
done

# ── Start services ────────────────────────────────────────
for svc in ${START_SERVICES}; do
  systemctl start "\$svc" 2>/dev/null || echo "\$svc start skipped (will start on boot)"
done
EOF

  log "Services configured"
  return 0
}