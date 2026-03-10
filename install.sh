#!/usr/bin/env bash
# ============================================================
# Arch Linux Automated Installer
# Usage: ./install.sh [config_file]
# Default config: install.conf.yaml
# ============================================================

set -euo pipefail  # strict mode — exit on error, unset var, pipe failure

# ── Colours ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()     { echo -e "${GREEN}[+]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }
section() { echo -e "\n${CYAN}══ $* ══${NC}"; }

# ── Config file ─────────────────────────────────────────────
CONFIG="${1:-install.conf.yaml}"
[[ -f "$CONFIG" ]] || error "Config file not found: $CONFIG"

# ── Dependency check ────────────────────────────────────────
command -v yq    &>/dev/null || error "yq is required. Install with: pacman -Sy yq"
command -v fdisk &>/dev/null || error "fdisk not found"

# ── Helper: read from yaml ───────────────────────────────────
cfg() { yq e "$1" "$CONFIG"; }

# ── Load config ─────────────────────────────────────────────
section "Loading configuration"

ESP_SIZE=$(cfg '.partitions.esp')
SWAP_SIZE=$(cfg '.partitions.swap')
ROOT_SIZE=$(cfg '.partitions.root')
HOME_SIZE=$(cfg '.partitions.home')

FS_ROOT=$(cfg '.filesystems.root')
FS_HOME=$(cfg '.filesystems.home')
FS_MEDIA=$(cfg '.filesystems.media')

MEDIA_MOUNT=$(cfg '.mounts.media')

LOCALE_LANG=$(cfg '.locale.lang')
TIMEZONE=$(cfg '.locale.timezone')

HOSTNAME=$(cfg '.system.hostname')

USERNAME=$(cfg '.user.name')
USERGROUPS=$(cfg '.user.groups')

# Kernels as space-separated string
KERNELS=$(cfg '.system.kernels[]' | tr '\n' ' ')

# Extra packages as space-separated string
EXTRA_PACKAGES=$(cfg '.packages[]' | tr '\n' ' ')

log "Config loaded from $CONFIG"
log "Hostname: $HOSTNAME | User: $USERNAME | Kernels: $KERNELS"

# ── Sanity checks ───────────────────────────────────────────
section "Pre-flight checks"

# Must run as root
[[ $EUID -eq 0 ]] || error "This script must be run as root"

# Must be booted in UEFI mode
[[ -d /sys/firmware/efi ]] || error "Not booted in UEFI mode. Enable EFI in your VM/BIOS settings."

# Check internet
ping -c 1 -W 3 archlinux.org &>/dev/null || error "No internet connection"

log "All pre-flight checks passed"

# ── Auto-detect disk ────────────────────────────────────────
section "Detecting disk"

# Find the largest disk that isn't a loop or removable device
DISK=$(lsblk -dpno NAME,TYPE,RM,SIZE \
  | awk '$2=="disk" && $3=="0" {print $1, $4}' \
  | sort -k2 -h \
  | tail -1 \
  | awk '{print $1}')

[[ -n "$DISK" ]] || error "No suitable disk found"
log "Target disk: $DISK"

# Warn user — this is destructive
warn "ALL DATA ON $DISK WILL BE DESTROYED"
read -rp "Type 'yes' to continue: " CONFIRM
[[ "$CONFIRM" == "yes" ]] || error "Aborted by user"

# ── Partition ───────────────────────────────────────────────
section "Partitioning $DISK"

# Wipe existing partition table
wipefs -af "$DISK"
sgdisk -Z "$DISK"

# Create partitions using fdisk
# We use a heredoc to drive fdisk non-interactively
fdisk "$DISK" <<EOF
g
n
1

+${ESP_SIZE}M
t
1
n
2

+${SWAP_SIZE}M
t
2
19
n
3

+${ROOT_SIZE}M
n
4

+${HOME_SIZE}M
n
5


w
EOF

# Reload partition table
partprobe "$DISK"
sleep 2

# Resolve partition names (handles both sda1 and nvme0n1p1 style)
if [[ "$DISK" == *"nvme"* ]]; then
  PART_ESP="${DISK}p1"
  PART_SWAP="${DISK}p2"
  PART_ROOT="${DISK}p3"
  PART_HOME="${DISK}p4"
  PART_MEDIA="${DISK}p5"
else
  PART_ESP="${DISK}1"
  PART_SWAP="${DISK}2"
  PART_ROOT="${DISK}3"
  PART_HOME="${DISK}4"
  PART_MEDIA="${DISK}5"
fi

log "Partitions created"

# ── Format ──────────────────────────────────────────────────
section "Formatting partitions"

mkfs.fat -F32 "$PART_ESP"
log "ESP formatted as FAT32"

mkswap "$PART_SWAP"
swapon "$PART_SWAP"
log "Swap formatted and activated"

mkfs."$FS_ROOT" -f "$PART_ROOT" 2>/dev/null || mkfs."$FS_ROOT" "$PART_ROOT"
log "Root formatted as $FS_ROOT"

mkfs."$FS_HOME" "$PART_HOME"
log "Home formatted as $FS_HOME"

mkfs."$FS_MEDIA" "$PART_MEDIA"
log "Media formatted as $FS_MEDIA"

# ── Mount ───────────────────────────────────────────────────
section "Mounting partitions"

mount "$PART_ROOT" /mnt

mkdir -p /mnt/boot
mount "$PART_ESP" /mnt/boot

mkdir -p /mnt/home
mount "$PART_HOME" /mnt/home

mkdir -p "/mnt${MEDIA_MOUNT}"
mount "$PART_MEDIA" "/mnt${MEDIA_MOUNT}"

log "All partitions mounted"

# ── pacstrap ────────────────────────────────────────────────
section "Installing base system (pacstrap)"

# shellcheck disable=SC2086
pacstrap /mnt base $KERNELS linux-firmware $EXTRA_PACKAGES

log "Base system installed"

# ── fstab ───────────────────────────────────────────────────
section "Generating fstab"

genfstab -U /mnt >> /mnt/etc/fstab
log "fstab generated"

# ── chroot configuration ─────────────────────────────────────
section "Configuring system (chroot)"

# We write a secondary script that runs inside the chroot
# and pass all variables into it via the environment
arch-chroot /mnt /bin/bash <<CHROOT
set -euo pipefail

# ── Timezone ──────────────────────────────────────────────
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc
echo "Timezone set to ${TIMEZONE}"

# ── Locale ────────────────────────────────────────────────
sed -i "s/^#${LOCALE_LANG}/${LOCALE_LANG}/" /etc/locale.gen
locale-gen
echo "LANG=${LOCALE_LANG}" > /etc/locale.conf
echo "Locale set to ${LOCALE_LANG}"

# ── Hostname ──────────────────────────────────────────────
echo "${HOSTNAME}" > /etc/hostname
echo "Hostname set to ${HOSTNAME}"

# ── Enable NetworkManager ─────────────────────────────────
systemctl enable NetworkManager
echo "NetworkManager enabled"

# ── Bootloader (GRUB) ─────────────────────────────────────
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
echo "GRUB installed and configured"

# ── User ──────────────────────────────────────────────────
useradd -mG ${USERGROUPS} ${USERNAME}
echo "User ${USERNAME} created"

# Allow wheel group to use sudo
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "sudo configured for wheel group"

# ── Passwords ─────────────────────────────────────────────
echo "--------------------------------------"
echo "Setting password for root: "
ROOT_PASS=$(cfg '.root.password')
echo "root:$(openssl passwd -6 "$ROOT_PASS")" | chpasswd -e
echo "Password set for root"
echo "--------------------------------------"
echo "Setting password for ${USERNAME}: "
USER_PASS=$(cfg '.user.password')
echo "${USERNAME}:$(openssl passwd -6 "$USER_PASS")" | chpasswd -e
echo "Password set for ${USERNAME}"

CHROOT

log "Chroot configuration complete"

# ── Done ────────────────────────────────────────────────────
section "Installation complete"
log "You can now reboot into your new Arch Linux system"
log "Remember to remove the installation media before booting"
echo ""
warn "Run: reboot"