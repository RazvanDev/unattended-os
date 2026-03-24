#!/usr/bin/env bash

verify_fstab() {
  local failed=0

  # verify fstab exists
  [[ -f "/mnt/etc/fstab" ]] || { warn "Verify failed: fstab missing"; failed=1; }

  # verify fstab has entries
  [[ $(grep -v "^#" "/mnt/etc/fstab" | grep -v "^$" | wc -l) -gt 0 ]] || \
    { warn "Verify failed: fstab is empty"; failed=1; }

  # verify root entry exists
  grep -qE '[[:space:]]/[[:space:]]' "/mnt/etc/fstab" || \
    { warn "Verify failed: root entry missing from fstab"; failed=1; }

  # verify boot entry exists
  grep -qE '[[:space:]]/boot[[:space:]]' "/mnt/etc/fstab" || \
    { warn "Verify failed: boot entry missing from fstab"; failed=1; }

  # verify swap entry exists
  grep -q "swap" "/mnt/etc/fstab" || \
    { warn "Verify failed: swap entry missing from fstab"; failed=1; }

  [[ $failed -eq 0 ]] || error "fstab verification failed"
  log "fstab verified ✓"
  return 0
}