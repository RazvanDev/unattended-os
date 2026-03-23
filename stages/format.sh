#!/usr/bin/env bash

do_format() {
  section "Formatting partitions"

  # ── ESP ───────────────────────────────────────────────
  if [[ "$WIPE_ESP" == "true" ]]; then
    mkfs.fat -F32 "$PART_ESP"
    log "ESP formatted as FAT32"
  else
    log "Skipping ESP format — wipe disabled"
  fi

  # ── Root ──────────────────────────────────────────────
  if [[ "$WIPE_ROOT" == "true" ]] || ! cryptsetup isLuks "$PART_ROOT" 2>/dev/null; then
    if [[ "$LUKS_ROOT" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup luksFormat "$PART_ROOT" -
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$PART_ROOT" "$MAPPER_ROOT" -
      mkfs."$FS_ROOT" "/dev/mapper/$MAPPER_ROOT"
      log "Root encrypted and formatted as $FS_ROOT"
    else
      mkfs."$FS_ROOT" -f "$PART_ROOT" 2>/dev/null || mkfs."$FS_ROOT" "$PART_ROOT"
      log "Root formatted as $FS_ROOT"
    fi
  else
    if [[ "$LUKS_ROOT" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$PART_ROOT" "$MAPPER_ROOT" -
    fi
    log "Root wipe disabled — opened existing LUKS"
  fi

  # ── Home ──────────────────────────────────────────────
  if [[ "$WIPE_HOME" == "true" ]] || ! cryptsetup isLuks "$PART_HOME" 2>/dev/null; then
    if [[ "$LUKS_HOME" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup luksFormat "$PART_HOME" -
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$PART_HOME" "$MAPPER_HOME" -
      mkfs."$FS_HOME" "/dev/mapper/$MAPPER_HOME"
      log "Home encrypted and formatted as $FS_HOME"
    else
      mkfs."$FS_HOME" "$PART_HOME"
      log "Home formatted as $FS_HOME"
    fi
  else
    if [[ "$LUKS_HOME" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$PART_HOME" "$MAPPER_HOME" -
    fi
    log "Home wipe disabled — opened existing LUKS"
  fi

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

  # ── Media ─────────────────────────────────────────────
  if [[ "$WIPE_MEDIA" == "true" ]] || ! cryptsetup isLuks "$PART_MEDIA" 2>/dev/null; then
    if [[ "$LUKS_MEDIA" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup luksFormat "$PART_MEDIA" -
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$PART_MEDIA" "$MAPPER_MEDIA" -
      mkfs."$FS_MEDIA" "/dev/mapper/$MAPPER_MEDIA"
      log "Media encrypted and formatted as $FS_MEDIA"
    else
      mkfs."$FS_MEDIA" "$PART_MEDIA"
      log "Media formatted as $FS_MEDIA"
    fi
  else
    if [[ "$LUKS_MEDIA" == "true" ]]; then
      echo -n "$LUKS_PASSPHRASE" | cryptsetup open "$PART_MEDIA" "$MAPPER_MEDIA" -
    fi
    log "Media wipe disabled — opened existing LUKS"
  fi

  return 0
}