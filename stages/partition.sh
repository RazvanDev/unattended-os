#!/usr/bin/env bash

do_partition() {
  section "Partitioning $DISK"

  # ── Cleanup previous run ──────────────────────────────
  cleanup_mounts

  wipefs -af "$DISK"
  sgdisk -Z "$DISK"

  fdisk "$DISK" <<EOF
g
n
1

+${ESP_SIZE}M
t
1
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

+${LOG_SIZE}M
n
5

+${HOME_SIZE}M
n
6


w
EOF

  partprobe "$DISK"
  sleep 2

  if [[ "$DISK" == *"nvme"* ]]; then
    PART_ESP="${DISK}p1"
    PART_SWAP="${DISK}p2"
    PART_ROOT="${DISK}p3"
    PART_LOG="${DISK}p4"
    PART_HOME="${DISK}p5"
    PART_MEDIA="${DISK}p6"
  else
    PART_ESP="${DISK}1"
    PART_SWAP="${DISK}2"
    PART_ROOT="${DISK}3"
    PART_LOG="${DISK}4"
    PART_HOME="${DISK}5"
    PART_MEDIA="${DISK}6"
  fi

  log "Partitions created"
  return 0
}