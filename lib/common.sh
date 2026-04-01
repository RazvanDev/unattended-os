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

migrate_state() {
  if [[ -f "/tmp/install-state" ]]; then
    mv /tmp/install-state /mnt/install-state
    STATE_FILE="/mnt/install-state"

    mkdir -p /mnt/var/log/unattended-os
    cp "$LOG_FILE" "/mnt/var/log/unattended-os/$(basename "$LOG_FILE")"
    LOG_FILE="/mnt/var/log/unattended-os/$(basename "$LOG_FILE")"
    log "State and log migrated to disk"
  fi
  return 0
}

stage_done() {
  echo "DEBUG mark_done: writing '$1' to $STATE_FILE" >&2
  sleep 10
  grep -q "^${1}$" "$STATE_FILE" 2>/dev/null
}

mark_done() {
  echo "$1" >> "$STATE_FILE"
  # sync log to disk after every completed stage
  [[ -d "/mnt/var/log/unattended-os" ]] && \
    cp "/tmp/install-attempt-${ATTEMPT}.log" \
       "/mnt/var/log/unattended-os/install-attempt-${ATTEMPT}.log" 2>/dev/null || true
  return 0
}

CURRENT_STAGE=""

run_stage() {
  local stage=$1
  CURRENT_STAGE="$stage"
  shift
  local fns=()
  local verify_fn=""

  for arg in "$@"; do
    if [[ "$arg" == verify_* ]]; then
      verify_fn="$arg"
    else
      fns+=("$arg")
    fi
  done

  if stage_done "$stage"; then
    log "Skipping '$stage' — already completed"
    return 0
  fi

  for fn in "${fns[@]}"; do
    $fn
  done

  if [[ -n "$verify_fn" ]]; then
    log "Verifying '$stage'..."
    $verify_fn || error "Verification failed for stage '$stage'"
  fi

  mark_done "$stage"
  [[ "$stage" == "partitioning" ]] && migrate_state

  return 0
}

cleanup_mounts() {
  local wipe_stages=("partitioning" "pacstrap")
  local last_completed=""
  
  # read last completed stage from state file
  if [[ -f "/mnt/install-state" ]]; then
    last_completed=$(tail -1 /mnt/install-state)
  elif [[ -f "/tmp/install-state" ]]; then
    last_completed=$(tail -1 /tmp/install-state)
  fi

  # if last completed stage is in wipe_stages or nothing completed yet
  # do full cleanup
  if [[ -z "$last_completed" || " ${wipe_stages[@]} " =~ " ${last_completed} " ]]; then
    warn "Cleaning up mounts and LUKS mappers..."
    swapoff -a 2>/dev/null || true
    cryptsetup close "$MAPPER_MEDIA" 2>/dev/null || true
    cryptsetup close "$MAPPER_HOME"  2>/dev/null || true
    cryptsetup close "$MAPPER_SWAP"  2>/dev/null || true
    cryptsetup close "$MAPPER_ROOT"  2>/dev/null || true
    umount -R /mnt 2>/dev/null || true
  else
    warn "Failed after '${last_completed}' — preserving mounts for retry"
  fi
  return 0
}


# ── Trap ─────────────────────────────────────────────────────
# ERR  — fires on any command returning non-zero (caught by set -e)
# EXIT — fires on any exit, including error(), Ctrl+C, or normal completion
#        cleanup_mounts is idempotent so double-firing is safe
trap 'warn "Unexpected exit — running cleanup"; cleanup_mounts' ERR
trap 'cleanup_mounts' EXIT