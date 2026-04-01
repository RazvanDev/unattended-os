#!/usr/bin/env bash

# ── Helper: format or open a single partition ────────────────
format_partition() {
  local part=$1        # e.g. /dev/sda3
  local mapper=$2      # e.g. cryptroot
  local fs=$3          # e.g. ext4
  local wipe=$4        # true/false
  local encrypt=$5     # true/false
  local label=$6       # e.g. Root, Home, Media

  if [[ "$wipe" == "true" ]] || ! cryptsetup isLuks "$part" 2>/dev/null; then
    if [[ "$encrypt" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup luksFormat "$part" -
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$part" "$mapper" -
      mkfs."$fs" "/dev/mapper/$mapper"
      log "$label encrypted and formatted as $fs"
    else
      mkfs."$fs" -f "$part" 2>/dev/null || mkfs."$fs" "$part"
      log "$label formatted as $fs"
    fi
  else
    if [[ "$encrypt" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$part" "$mapper" -
    fi
    log "$label wipe disabled — opened existing"
  fi
  return 0
}

do_format() {
  section "Formatting partitions"

  # ── ESP ───────────────────────────────────────────────
  if [[ "$WIPE_ESP" == "true" ]]; then
    mkfs.fat -F32 "$PART_ESP"
    log "ESP formatted as FAT32"
  else
    log "Skipping ESP format — wipe disabled"
  fi

  format_partition "$PART_ROOT"  "$MAPPER_ROOT"  "$FS_ROOT"  "$WIPE_ROOT"  "$LUKS_ROOT"  "Root"
  format_partition "$PART_LOG"   "$MAPPER_LOG"   "$FS_LOG"   "$WIPE_LOG"   "$LUKS_LOG"   "Log"
  format_partition "$PART_HOME"  "$MAPPER_HOME"  "$FS_HOME"  "$WIPE_HOME"  "$LUKS_HOME"  "Home"
  format_partition "$PART_MEDIA" "$MAPPER_MEDIA" "$FS_MEDIA" "$WIPE_MEDIA" "$LUKS_MEDIA" "Media"

  # ── Swap ──────────────────────────────────────────────
  swapoff "$PART_SWAP" 2>/dev/null || true
  if [[ "$WIPE_SWAP" == "true" ]] || ! cryptsetup isLuks "$PART_SWAP" 2>/dev/null; then
    if [[ "$LUKS_SWAP" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup luksFormat "$PART_SWAP" -
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$PART_SWAP" "$MAPPER_SWAP" -
      mkswap "/dev/mapper/$MAPPER_SWAP"
      swapon "/dev/mapper/$MAPPER_SWAP"
      log "Swap encrypted and activated"
    else
      mkswap "$PART_SWAP"
      swapon "$PART_SWAP"
      log "Swap formatted and activated"
    fi
  else
    if [[ "$LUKS_SWAP" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$PART_SWAP" "$MAPPER_SWAP" -
      swapon "/dev/mapper/$MAPPER_SWAP"
    else
      swapon "$PART_SWAP"
    fi
    log "Swap wipe disabled — opened existing LUKS"
  fi

  return 0
}