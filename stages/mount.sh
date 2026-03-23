#!/usr/bin/env bash

# ── Helper: mount a single partition ────────────────────────
mount_partition() {
  local part=$1        # e.g. /dev/sda3
  local mapper=$2      # e.g. cryptroot
  local mountpoint=$3  # e.g. /mnt/home
  local encrypt=$4     # true/false

  mkdir -p "$mountpoint"
  if [[ "$encrypt" == "true" ]]; then
    mount "/dev/mapper/$mapper" "$mountpoint"
  else
    mount "$part" "$mountpoint"
  fi
  log "Mounted $part → $mountpoint"
  return 0
}

do_mount() {
  section "Mounting partitions"

  mount_partition "$PART_ROOT"  "$MAPPER_ROOT"  "/mnt"                  "$LUKS_ROOT"
  mount_partition "$PART_ESP"   ""              "/mnt/boot"             "false"
  mount_partition "$PART_HOME"  "$MAPPER_HOME"  "/mnt${MOUNT_HOME}"     "$LUKS_HOME"
  mount_partition "$PART_MEDIA" "$MAPPER_MEDIA" "/mnt${MOUNT_MEDIA}"    "$LUKS_MEDIA"

  log "All partitions mounted"

  mkdir -p /mnt/etc
  echo "KEYMAP=${KEYMAP}" > /mnt/etc/vconsole.conf
  log "vconsole.conf created"
  return 0
}