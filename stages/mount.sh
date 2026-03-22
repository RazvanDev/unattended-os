#!/usr/bin/env bash

do_mount() {
  section "Mounting partitions"

  # ── Root ──────────────────────────────────────────────
  if [[ "$LUKS_ENABLED" == "true" && "$LUKS_ROOT" == "true" ]]; then
    mount /dev/mapper/cryptroot /mnt
  else
    mount "$PART_ROOT" /mnt
  fi

  # ── ESP — never encrypted ─────────────────────────────
  mkdir -p /mnt/boot
  mount "$PART_ESP" /mnt/boot

  # ── Home ──────────────────────────────────────────────
  mkdir -p /mnt/home
  if [[ "$LUKS_ENABLED" == "true" && "$LUKS_HOME" == "true" ]]; then
    mount /dev/mapper/crypthome /mnt/home
  else
    mount "$PART_HOME" /mnt/home
  fi

  # ── Media ─────────────────────────────────────────────
  mkdir -p "/mnt${MEDIA_MOUNT}"
  if [[ "$LUKS_ENABLED" == "true" && "$LUKS_MEDIA" == "true" ]]; then
    mount /dev/mapper/cryptmedia "/mnt${MEDIA_MOUNT}"
  else
    mount "$PART_MEDIA" "/mnt${MEDIA_MOUNT}"
  fi

  log "All partitions mounted"
}