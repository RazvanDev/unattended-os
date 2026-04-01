#!/usr/bin/env bash
# ============================================================
# Arch Linux Automated Installer
# Usage: ./install.sh [config_file] [secrets_file] [--unattended]
# ============================================================

set -euo pipefail

# ── Parse arguments ─────────────────────────────────────────
UNATTENDED=false
for arg in "$@"; do
  case $arg in
    --unattended) UNATTENDED=true ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/variables.sh"

# ── Redirect all output to log ───────────────────────────────
exec > >(tee -a "$LOG_FILE") 2>&1

for f in "$SCRIPT_DIR"/stages/*.sh; do source "$f"; done

for f in "$SCRIPT_DIR"/verificators/*.sh; do source "$f"; done

command -v yq    &>/dev/null || error "yq is required"
command -v fdisk &>/dev/null || error "fdisk not found"

load_config "${1:-install-conf.yaml}" "${2:-install-secrets.yaml}"

section "Pre-flight checks"
[[ $EUID -eq 0 ]] || error "Must be run as root"
[[ -d /sys/firmware/efi ]] || error "Not booted in UEFI mode"

log "Waiting for network..."
for i in {1..10}; do
  curl -s --max-time 3 https://archlinux.org &>/dev/null && break
  warn "Network not ready, retry $i/10..."
  sleep 5
done
curl -s --max-time 3 https://archlinux.org &>/dev/null || error "No internet connection after retries"
log "All pre-flight checks passed"

section "Detecting disk"
detect_disk

warn "ALL DATA ON $DISK WILL BE DESTROYED"
if [[ "$UNATTENDED" == false ]]; then
  read -rp "Type 'yes' to continue: " CONFIRM
  [[ "$CONFIRM" == "yes" ]] || error "Aborted by user"
else
  warn "Unattended mode — skipping confirmation"
fi

setup_variables

# ── Resume detection ─────────────────────────────────────────
if grep -q "^pacstrap:completed$" "/tmp/install-state" 2>/dev/null || \
   grep -q "^pacstrap:completed$" "/mnt/install-state" 2>/dev/null; then

  log "Previous install detected past pacstrap — attempting remount"

  if ! mountpoint -q /mnt; then
    _WIPE_ROOT=$WIPE_ROOT; _WIPE_HOME=$WIPE_HOME
    _WIPE_SWAP=$WIPE_SWAP; _WIPE_MEDIA=$WIPE_MEDIA

    WIPE_ROOT=false; WIPE_HOME=false
    WIPE_SWAP=false; WIPE_MEDIA=false

    do_format
    do_mount

    WIPE_ROOT=$_WIPE_ROOT; WIPE_HOME=$_WIPE_HOME
    WIPE_SWAP=$_WIPE_SWAP; WIPE_MEDIA=$_WIPE_MEDIA
    unset _WIPE_ROOT _WIPE_HOME _WIPE_SWAP _WIPE_MEDIA
  fi

  # prefer /mnt state — more complete than /tmp
  if [[ -f "/mnt/install-state" ]]; then
    STATE_FILE="/mnt/install-state"
    log "Resuming from /mnt/install-state"
  fi

else
  # no valid install past pacstrap — wipe state and start fresh
  log "No valid previous install — starting fresh"
  rm -f /tmp/install-state 2>/dev/null || true
fi

run_stage "partitioning"       do_partition do_format do_mount  verify_partitioning
run_stage "pacstrap"           do_pacstrap                      verify_pacstrap
run_stage "fstab"              do_fstab                         verify_fstab
run_stage "locale"             do_locale                        verify_locale                        
run_stage "initramfs"          do_initramfs                     verify_initramfs
run_stage "services"           do_services                      verify_services
run_stage "users"              do_users do_passwords            verify_users
run_stage "desktop"            do_desktop                       
run_stage "ssh_config"         do_ssh_config                    verify_ssh_config
run_stage "firewall"           do_firewall                      verify_firewall
run_stage "sysctl"             do_sysctl_config                 verify_sysctl_config
run_stage "bootloader"         do_bootloader                    verify_bootloader

section "Installation complete"
log "Rebooting in 10 seconds..."
sleep 10
reboot