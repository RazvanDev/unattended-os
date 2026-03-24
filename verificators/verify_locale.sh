#!/usr/bin/env bash

verify_locale() {
  local failed=0

  # verify timezone symlink
  [[ -L "/mnt/etc/localtime" ]] || { warn "Verify failed: /etc/localtime symlink missing"; failed=1; }

  # verify locale.conf
  [[ -f "/mnt/etc/locale.conf" ]] || { warn "Verify failed: /etc/locale.conf missing"; failed=1; }
  grep -q "LANG=" "/mnt/etc/locale.conf" || { warn "Verify failed: LANG not set in locale.conf"; failed=1; }

  # verify hostname
  [[ -f "/mnt/etc/hostname" ]] || { warn "Verify failed: /etc/hostname missing"; failed=1; }
  grep -q "$HOSTNAME" "/mnt/etc/hostname" || { warn "Verify failed: hostname mismatch"; failed=1; }

  [[ $failed -eq 0 ]] || error "locale verification failed"
  log "locale verified ✓"
  return 0
}