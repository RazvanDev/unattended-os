#!/usr/bin/env bash

do_partition() {
  section "Partitioning $DISK"

  # ── Cleanup previous run ──────────────────────────────
  log "Cleaning up previous mounts..."
  swapoff -a 2>/dev/null || true
  umount -R /mnt 2>/dev/null || true
  cryptsetup close cryptroot 2>/dev/null || true
  cryptsetup close crypthome 2>/dev/null || true
  cryptsetup close cryptswap 2>/dev/null || true
  cryptsetup close cryptmedia 2>/dev/null || true

  wipefs -af "$DISK"
  sgdisk -Z "$DISK"

  fdisk "$DISK" <<EOF
g
n
1

+${ESP_SIZE}M
t
1
n
2

+${SWAP_SIZE}M
t
2
19
n
3

+${ROOT_SIZE}M
n
4

+${HOME_SIZE}M
n
5


w
EOF

  partprobe "$DISK"
  sleep 2

  if [[ "$DISK" == *"nvme"* ]]; then
    PART_ESP="${DISK}p1"
    PART_SWAP="${DISK}p2"
    PART_ROOT="${DISK}p3"
    PART_HOME="${DISK}p4"
    PART_MEDIA="${DISK}p5"
  else
    PART_ESP="${DISK}1"
    PART_SWAP="${DISK}2"
    PART_ROOT="${DISK}3"
    PART_HOME="${DISK}4"
    PART_MEDIA="${DISK}5"
  fi

  log "Partitions created"
}