#!/usr/bin/env bash

# ── Helper: format or open a single partition ────────────────
format_partition() {
  local part=$1        # e.g. /dev/sda3
  local mapper=$2      # e.g. cryptroot
  local fs=$3          # e.g. ext4
  local wipe=$4        # true/false
  local encrypt=$5     # true/false
  local label=$6       # e.g. Root, Home, Swap, Media

  if [[ "$wipe" == "true" ]] || ! cryptsetup isLuks "$part" 2>/dev/null; then
    if [[ "$encrypt" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup luksFormat "$part" -
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$part" "$mapper" -
      if [[ "$fs" == "swap" ]]; then
        mkswap "/dev/mapper/$mapper"
        swapon "/dev/mapper/$mapper"
      else
        mkfs."$fs" "/dev/mapper/$mapper"
      fi
      log "$label encrypted and formatted as $fs"
    else
      if [[ "$fs" == "swap" ]]; then
        mkswap "$part"
        swapon "$part"
      else
        mkfs."$fs" -f "$part" 2>/dev/null || mkfs."$fs" "$part"
      fi
      log "$label formatted as $fs"
    fi
  else
    if [[ "$encrypt" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$part" "$mapper" -
      [[ "$fs" == "swap" ]] && swapon "/dev/mapper/$mapper"
    else
      [[ "$fs" == "swap" ]] && swapon "$part"
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

  mkswap "$PART_SWAP"
  swapon "$PART_SWAP"
  log "Swap formatted and activated"

  format_partition "$PART_ROOT"  "$MAPPER_ROOT"  "$FS_ROOT"  "$WIPE_ROOT"  "$LUKS_ROOT"  "Root"
  format_partition "$PART_HOME"  "$MAPPER_HOME"  "$FS_HOME"  "$WIPE_HOME"  "$LUKS_HOME"  "Home"
  
  swapoff "$PART_SWAP" 2>/dev/null || true
  format_partition "$PART_SWAP"  "$MAPPER_SWAP"  "swap"      "$WIPE_SWAP"  "$LUKS_SWAP"  "Swap"
  
  format_partition "$PART_MEDIA" "$MAPPER_MEDIA" "$FS_MEDIA" "$WIPE_MEDIA" "$LUKS_MEDIA" "Media"

  return 0
}