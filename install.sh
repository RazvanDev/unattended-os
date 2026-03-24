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

# ── Load libraries ───────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/variables.sh"

# ── Redirect all output to log ───────────────────────────────
exec > >(tee -a "$LOG_FILE") 2>&1

# ── Load stages ─────────────────────────────────────────────
for f in "$SCRIPT_DIR"/stages/*.sh; do source "$f"; done

# ── Load verificators ────────────────────────────────────────
for f in "$SCRIPT_DIR"/verificators/*.sh; do source "$f"; done


# ── Dependency check ─────────────────────────────────────────
command -v yq    &>/dev/null || error "yq is required"
command -v fdisk &>/dev/null || error "fdisk not found"

# ── Load config ──────────────────────────────────────────────
load_config "${1:-install-conf.yaml}" "${2:-install-secrets.yaml}"

# ── Pre-flight checks ────────────────────────────────────────
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

# ── Auto-detect disk ─────────────────────────────────────────
section "Detecting disk"
detect_disk

warn "ALL DATA ON $DISK WILL BE DESTROYED"
if [[ "$UNATTENDED" == false ]]; then
  read -rp "Type 'yes' to continue: " CONFIRM
  [[ "$CONFIRM" == "yes" ]] || error "Aborted by user"
else
  warn "Unattended mode — skipping confirmation"
fi

# ── Run stages ───────────────────────────────────────────────
setup_variables
run_stage "partitioning"       do_partition do_format do_mount  verify_partitioning
run_stage "pacstrap"           do_pacstrap                      verify_pacstrap
run_stage "fstab"              do_fstab                         
run_stage "locale"             do_locale                        verify_locale                        
run_stage "initramfs"          do_initramfs                     verify_initramfs
run_stage "services"           do_services                      verify_services
run_stage "users"              do_users do_passwords            
run_stage "bootloader"         do_bootloader                    

# ── Done ─────────────────────────────────────────────────────
section "Installation complete"
log "Rebooting in 10 seconds..."
sleep 10
reboot