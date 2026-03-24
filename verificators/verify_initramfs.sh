#!/usr/bin/env bash

verify_initramfs() {
  local failed=0

  # verify initramfs images exist for each kernel
  for kernel in $KERNELS; do
    [[ -f "/mnt/boot/initramfs-${kernel}.img" ]] || \
      { warn "Verify failed: initramfs for $kernel missing"; failed=1; }
  done

  # verify encrypt hook is in mkinitcpio.conf if any partition is encrypted
  if [[ "$LUKS_ROOT" == "true" || "$LUKS_HOME" == "true" || \
        "$LUKS_SWAP" == "true" || "$LUKS_MEDIA" == "true" ]]; then
    grep -q "encrypt" "/mnt/etc/mkinitcpio.conf" || \
      { warn "Verify failed: encrypt hook missing from mkinitcpio.conf"; failed=1; }
  fi

  [[ $failed -eq 0 ]] || error "initramfs verification failed"
  log "initramfs verified ✓"
  return 0
}