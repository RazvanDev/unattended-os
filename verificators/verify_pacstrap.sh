#!/usr/bin/env bash

verify_pacstrap() {
  local failed=0

  # verify filesystem structure
  [[ -d "/mnt/usr" ]]  || { warn "Verify failed: /mnt/usr missing";  failed=1; }
  [[ -d "/mnt/etc" ]]  || { warn "Verify failed: /mnt/etc missing";  failed=1; }
  [[ -d "/mnt/boot" ]] || { warn "Verify failed: /mnt/boot missing"; failed=1; }
  [[ -d "/mnt/home" ]] || { warn "Verify failed: /mnt/home missing"; failed=1; }

  # verify pacman database
  [[ -d "/mnt/var/lib/pacman/local" ]] || { warn "Verify failed: pacman database missing"; failed=1; }

  # verify all packages from config are installed
  for pkg in base $KERNELS linux-firmware $EXTRA_PACKAGES; do
    if ! arch-chroot /mnt pacman -Q "$pkg" &>/dev/null; then
      warn "Verify failed: package '$pkg' not installed"
      failed=1
    fi
  done

  [[ $failed -eq 0 ]] || error "pacstrap verification failed"
  log "pacstrap verified ✓"
  return 0
}