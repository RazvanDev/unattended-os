do_configs() {
  section "Applying hardened configs"

  # guard — fail early if dynamic values are missing
  [[ -z "$SSH_PORT" ]] && error "SSH_PORT not set — check load_config"
  [[ -z "$SSH_ALLOWED_USERS" ]] && error "SSH_ALLOWED_USERS not set — check load_config"

  CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs"

  mkdir -p /mnt/etc/ssh/sshd_config.d/
  cp "$CONFIG_DIR/99-hardened-sshd_config" "/mnt/etc/ssh/sshd_config"
  cp "$CONFIG_DIR/ssh-banner.txt" "/mnt/etc/ssh/banner.txt"

  sed -i "s|^Port.*|Port ${SSH_PORT}|" /mnt/etc/ssh/sshd_config.d/99-hardened.conf
  sed -i "s|^AllowUsers.*|AllowUsers ${SSH_ALLOWED_USERS}|" /mnt/etc/ssh/sshd_config.d/99-hardened.conf

  chmod 600 /mnt/etc/ssh/sshd_config.d/99-hardened.conf
  chmod 644 /mnt/etc/ssh/banner.txt

  log "Hardened configs applied"
  return 0
}