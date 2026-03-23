#!/usr/bin/env bash
# ============================================================
# Arch ISO Builder
# Usage: ./build-iso.sh
# Run this inside an Arch Linux environment (or Docker container)
# ============================================================

set -euo pipefail

REPO_URL="https://github.com/RazvanDev/unattended-os.git"
PROFILE_DIR="/root/myarch-iso"
WORK_DIR="/tmp/archiso-work"
OUT_DIR="/root/myarch-iso/out"
YQ_URL="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log()     { echo -e "${GREEN}[+]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }
section() { echo -e "\n${CYAN}══ $* ══${NC}"; }

# ── Checks ──────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || error "Must run as root"
command -v pacman &>/dev/null || error "This script must run on Arch Linux"

# ── Dependencies ────────────────────────────────────────────
section "Installing dependencies"
pacman -Sy --noconfirm archiso git wget

# ── Base profile ────────────────────────────────────────────
section "Setting up archiso profile"
[[ -d "$PROFILE_DIR" ]] && rm -rf "$PROFILE_DIR"
cp -r /usr/share/archiso/configs/releng "$PROFILE_DIR"

# ── yq binary ───────────────────────────────────────────────
section "Baking in yq"
wget "$YQ_URL" -O "$PROFILE_DIR/airootfs/usr/local/bin/yq"

# ── Repo ────────────────────────────────────────────────────
section "Cloning repo into ISO"
git clone "$REPO_URL" "$PROFILE_DIR/airootfs/root/unattended-os"

# ── Secrets file ─────────────────────────────────────────────
section "Verifying secrets"
[[ -f "$PROFILE_DIR/airootfs/root/unattended-os/install-secrets.yaml" ]] || \
  error "Secrets file not found in repo — add install-secrets.yaml"
log "Secrets verified"

# ── Permissions ─────────────────────────────────────────────
section "Setting file permissions"
sed -i '/^\s*\[\"\/root\"\]/a\  ["/usr/local/bin/yq"]="0:0:755"\n  ["/root/unattended-os/install.sh"]="0:0:755"' \
  "$PROFILE_DIR/profiledef.sh"

# ── Auto-install service ─────────────────────────────────────
section "Installing auto-install service"
cp "$PROFILE_DIR/airootfs/root/unattended-os/auto-install.service" \
  "$PROFILE_DIR/airootfs/etc/systemd/system/auto-install.service"

mkdir -p "$PROFILE_DIR/airootfs/etc/systemd/system/multi-user.target.wants"
ln -sf /etc/systemd/system/auto-install.service \
  "$PROFILE_DIR/airootfs/etc/systemd/system/multi-user.target.wants/auto-install.service"

# ── Disable autologin ────────────────────────────────────────
section "Disabling autologin"
rm -f "$PROFILE_DIR/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf"

# ── Build ────────────────────────────────────────────────────
section "Building ISO"
rm -rf "$WORK_DIR"
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

section "Done"
log "ISO is at: $OUT_DIR"
ls -lh "$OUT_DIR"/*.iso
