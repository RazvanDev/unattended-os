#!/usr/bin/env bash

detect_disk() {
  DISK=$(lsblk -dpno NAME,TYPE,RM,SIZE \
    | awk '$2=="disk" && $3=="0" {print $1, $4}' \
    | sort -k2 -h \
    | tail -1 \
    | awk '{print $1}')
  [[ -n "$DISK" ]] || error "No suitable disk found"
  log "Target disk: $DISK"
  return 0
}

setup_variables() {
  # ── Partition names ──────────────────────────────────
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

  # ── Mapper names (used if LUKS enabled) ──────────────
  MAPPER_ROOT="cryptroot"
  MAPPER_LOG="cryptlog"
  MAPPER_HOME="crypthome"
  MAPPER_SWAP="cryptswap"
  MAPPER_MEDIA="cryptmedia"
  return 0
}