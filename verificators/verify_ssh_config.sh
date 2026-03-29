verify_ssh_config() {
  local failed=0
  SSH_CONFIG_FILE=/mnt/etc/ssh/sshd_config

  [[ -f "$SSH_CONFIG_FILE" ]] || \
    { warn "Verify failed: $SSH_CONFIG_FILE missing"; failed=1; }

  [[ -f "/mnt/etc/ssh/banner.txt" ]] || \
    { warn "Verify failed: ssh banner missing"; failed=1; }

  grep -q "PasswordAuthentication yes" "$SSH_CONFIG_FILE" || \
    { warn "Verify failed: PasswordAuthentication not hardened"; failed=1; }

  grep -q "PermitRootLogin no" "$SSH_CONFIG_FILE" || \
    { warn "Verify failed: PermitRootLogin not hardened"; failed=1; }

  [[ "$(stat -c %a $SSH_CONFIG_FILE)" == "600" ]] || \
    { warn "Verify failed: $SSH_CONFIG_FILE permissions incorrect"; failed=1; }

  [[ $failed -eq 0 ]] || error "configs verification failed"
  log "configs verified ✓"
  return 0
}