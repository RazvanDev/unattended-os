#!/usr/bin/env bash
# ── Helper: read from yaml ───────────────────────────────────
cfg() { yq e "$1" "$CONFIG"; }
sec() { yq e "$1" "$SECRETS"; }

load_config() {
  CONFIG="${1:-install-conf.yaml}"
  SECRETS="${2:-${SECRETS_FILE:-install-secrets.yaml}}"

  [[ -f "$CONFIG" ]] || error "Config file not found: $CONFIG"
  [[ -f "$SECRETS" ]] || error "Secrets file not found: $SECRETS"

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
  KEYMAP=$(cfg '.locale.keymap')
  HOSTNAME=$(cfg '.system.hostname')
  USERNAME=$(cfg '.user.name')
  USERGROUPS=$(cfg '.user.groups')
  ROOT_HASH=$(openssl passwd -6 "$(sec '.root.password')")
  USER_HASH=$(openssl passwd -6 "$(sec '.user.password')")
  KERNELS=$(cfg '.system.kernels[]' | tr '\n' ' ')
  EXTRA_PACKAGES=$(cfg '.packages[]' | tr '\n' ' ')
  LUKS_ENABLED=$(cfg '.encryption.enabled')
  LUKS_PASSPHRASE=$(sec '.encryption.passphrase')
  LUKS_ROOT=$(cfg '.encryption.partitions.root')
  LUKS_HOME=$(cfg '.encryption.partitions.home')
  LUKS_SWAP=$(cfg '.encryption.partitions.swap')
  LUKS_MEDIA=$(cfg '.encryption.partitions.media')

  log "Config loaded from $CONFIG"
  log "Hostname: $HOSTNAME | User: $USERNAME | Kernels: $KERNELS"
}