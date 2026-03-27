do_configs() {
  section "Applying hardened configs"

  CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/configs"

  mkdir -p /mnt/etc/ssh/sshd_config.d/
  cp "$CONFIG_DIR/99-hardened-sshd_config" "/mnt/etc/ssh/sshd_config.d/99-hardened.conf"
  cp "$CONFIG_DIR/ssh-banner.txt" "/mnt/etc/ssh/banner.txt"

  chmod 600 /mnt/etc/ssh/sshd_config.d/99-hardened.conf
  chmod 644 /mnt/etc/ssh/banner.txt

  log "Hardened configs applied"
  return 0
}