#!/usr/bin/env bash
# ── Colours ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Logging ──────────────────────────────────────────────────
ATTEMPT=1
while [[ -f "/tmp/install-attempt-${ATTEMPT}.log" ]] || \
      [[ -f "/mnt/var/log/unattended-os/install-attempt-${ATTEMPT}.log" ]]; do
  ((ATTEMPT++))
done
LOG_FILE="/tmp/install-attempt-${ATTEMPT}.log"

log()     { echo -e "${GREEN}[+]${NC} $*" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG_FILE"; }
error()   { echo -e "${RED}[✗]${NC} $*" | tee -a "$LOG_FILE" >&2; exit 1; }
section() { echo -e "\n${CYAN}══ $* ══${NC}" | tee -a "$LOG_FILE"; }
# ── State tracking ───────────────────────────────────────────
STATE_FILE="/tmp/install-state"

# called after do_mount inside run_stage
migrate_state() {
  if [[ -f "/tmp/install-state" ]]; then
    cp /tmp/install-state /mnt/install-state
    STATE_FILE="/mnt/install-state"

    mkdir -p /mnt/var/log/unattended-os
    cp "$LOG_FILE" "/mnt/var/log/unattended-os/$(basename "$LOG_FILE")"
    LOG_FILE="/mnt/var/log/unattended-os/$(basename "$LOG_FILE")"
    log "State and log migrated to disk"
  fi
}

stage_done() {
  grep -q "^${1}$" "$STATE_FILE" 2>/dev/null
}

mark_done() {
  echo "$1" >> "$STATE_FILE"
}

run_stage() {
  local stage=$1
  shift
  local fns=("$@")

  if stage_done "$stage"; then
    log "Skipping '$stage' — already completed"
    return
  fi

  for fn in "${fns[@]}"; do
    $fn
  done

  mark_done "$stage"

  # migrate state to disk after partitioning stage
  [[ "$stage" == "partitioning" ]] && migrate_state
}