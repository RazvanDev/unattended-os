#!/usr/bin/env bash
# ── Helper: read from yaml ───────────────────────────────────
cfg() { yq e "$1" "$CONFIG"; }
sec() { yq e "$1" "$SECRETS"; }

to_mib() {
  local size=$1
  local unit=$2
  case "$unit" in
    G|g) echo $((size * 1024)) ;;
    M|m) echo "$size" ;;
    *) error "Unknown unit: $unit" ;;
  esac
  return 0
}

load_config() {
  CONFIG="${1:-install-conf.yaml}"
  SECRETS="${2:-${SECRETS_FILE:-install-secrets.yaml}}"

  [[ -f "$CONFIG" ]] || error "Config file not found: $CONFIG"
  [[ -f "$SECRETS" ]] || error "Secrets file not found: $SECRETS"

  # Partition sizes
  ESP_SIZE=$(to_mib "$(cfg '.partitions.esp.size')" "$(cfg '.partitions.esp.unit')")
  SWAP_SIZE=$(to_mib "$(cfg '.partitions.swap.size')" "$(cfg '.partitions.swap.unit')")
  ROOT_SIZE=$(to_mib "$(cfg '.partitions.root.size')" "$(cfg '.partitions.root.unit')")
  HOME_SIZE=$(to_mib "$(cfg '.partitions.home.size')" "$(cfg '.partitions.home.unit')")

  # Filesystems
  FS_ROOT=$(cfg '.partitions.root.fs')
  FS_HOME=$(cfg '.partitions.home.fs')
  FS_MEDIA=$(cfg '.partitions.media.fs')

  # Wipe flags
  WIPE_ESP=$(cfg '.partitions.esp.wipe')
  WIPE_SWAP=$(cfg '.partitions.swap.wipe')
  WIPE_ROOT=$(cfg '.partitions.root.wipe')
  WIPE_HOME=$(cfg '.partitions.home.wipe')
  WIPE_MEDIA=$(cfg '.partitions.media.wipe')

  # Encryption per partition
  LUKS_ROOT=$(cfg '.partitions.root.encrypt')
  LUKS_HOME=$(cfg '.partitions.home.encrypt')
  LUKS_SWAP=$(cfg '.partitions.swap.encrypt')
  LUKS_MEDIA=$(cfg '.partitions.media.encrypt')
  LUKS_PASSPHRASE=$(sec '.encryption.passphrase')

  # Mount points
  MOUNT_HOME=$(cfg '.partitions.home.mount')
  MOUNT_MEDIA=$(cfg '.partitions.media.mount')

  # Locale
  LOCALE_LANG=$(cfg '.locale.lang')
  TIMEZONE=$(cfg '.locale.timezone')
  KEYMAP=$(cfg '.locale.keymap')

  # System
  HOSTNAME=$(cfg '.system.hostname')
  KERNELS=$(cfg '.system.kernels[]' | tr '\n' ' ')
  EXTRA_PACKAGES=$(cfg '.packages[]' | tr '\n' ' ')
  ENABLED_SERVICES=$(cfg '.services[] | select(.enabled == true) | .name' | tr '\n' ' ')
  START_SERVICES=$(cfg '.services[] | select(.start == true) | .name' | tr '\n' ' ')

  # User
  USERNAME=$(cfg '.user.name')
  USERGROUPS=$(cfg '.user.groups')
  ROOT_HASH=$(openssl passwd -6 "$(sec '.root.password')")
  USER_HASH=$(openssl passwd -6 "$(sec '.user.password')")

  log "Config loaded from $CONFIG"
  log "Hostname: $HOSTNAME | User: $USERNAME | Kernels: $KERNELS"
  return 0
}