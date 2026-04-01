#!/usr/bin/env bash

verify_partitioning() {
  local failed=0

  # verify all partitions exist
  [[ -b "$PART_ESP" ]]   || { warn "Verify failed: ESP partition $PART_ESP missing";   failed=1; }
  [[ -b "$PART_SWAP" ]]  || { warn "Verify failed: swap partition $PART_SWAP missing"; failed=1; }
  [[ -b "$PART_ROOT" ]]  || { warn "Verify failed: root partition $PART_ROOT missing"; failed=1; }
  [[ -b "$PART_LOG" ]]   || { warn "Verify failed: log partition $PART_LOG missing";   failed=1; }
  [[ -b "$PART_HOME" ]]  || { warn "Verify failed: home partition $PART_HOME missing"; failed=1; }
  [[ -b "$PART_MEDIA" ]] || { warn "Verify failed: media partition $PART_MEDIA missing"; failed=1; }

  # verify root is mounted
  mountpoint -q /mnt || { warn "Verify failed: /mnt not mounted"; failed=1; }

  # verify ESP is mounted
  mountpoint -q /mnt/boot || { warn "Verify failed: /mnt/boot not mounted"; failed=1; }

  # verify log is mounted                                                                          
  mountpoint -q "/mnt${MOUNT_LOG}" || { warn "Verify failed: /mnt${MOUNT_LOG} not mounted"; failed=1; }

  # verify home is mounted
  mountpoint -q "/mnt${MOUNT_HOME}" || { warn "Verify failed: /mnt${MOUNT_HOME} not mounted"; failed=1; }

  # verify swap is active
  SWAP_DEVICE=$(readlink -f "/dev/mapper/$MAPPER_SWAP" 2>/dev/null || echo "$PART_SWAP")
  swapon --show NAME | grep -q "$(basename $SWAP_DEVICE)" || \
    { warn "Verify failed: swap not active"; failed=1; }

  [[ $failed -eq 0 ]] || error "partitioning verification failed"
  log "partitioning verified ✓"
  return 0
}