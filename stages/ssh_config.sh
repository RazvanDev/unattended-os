do_ssh_config() {
  section "Applying hardened configs"

  # guard — fail early if dynamic values are missing
  [[ -z "$SSH_PORT" ]] && error "SSH_PORT not set — check load_config"
  [[ -z "$SSH_ALLOWED_USERS" ]] && error "SSH_ALLOWED_USERS not set — check load_config"

  SSH_CONFIG_FILE=/mnt/etc/ssh/sshd_config
  CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs"

  mkdir -p /mnt/etc/ssh/sshd_config.d/
  cp "$CONFIG_DIR/99-hardened-sshd_config" "$SSH_CONFIG_FILE"
  cp "$CONFIG_DIR/ssh-banner.txt" "/mnt/etc/ssh/banner.txt"

  sed -i "s|^Port.*|Port ${SSH_PORT}|" "$SSH_CONFIG_FILE"
  sed -i "s|^AllowUsers.*|AllowUsers ${SSH_ALLOWED_USERS}|" "$SSH_CONFIG_FILE"

  chmod 600 "$SSH_CONFIG_FILE"
  chmod 644 /mnt/etc/ssh/banner.txt

  log "Hardened configs applied"
  return 0
}