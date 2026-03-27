verify_configs() {
  local failed=0

  [[ -f "/mnt/etc/ssh/sshd_config.d/99-hardened.conf" ]] || \
    { warn "Verify failed: 99-hardened.conf missing"; failed=1; }

  [[ -f "/mnt/etc/ssh/banner.txt" ]] || \
    { warn "Verify failed: ssh banner missing"; failed=1; }

  grep -q "PasswordAuthentication no" "/mnt/etc/ssh/sshd_config.d/99-hardened.conf" || \
    { warn "Verify failed: PasswordAuthentication not hardened"; failed=1; }

  grep -q "PermitRootLogin no" "/mnt/etc/ssh/sshd_config.d/99-hardened.conf" || \
    { warn "Verify failed: PermitRootLogin not hardened"; failed=1; }

  [[ "$(stat -c %a /mnt/etc/ssh/sshd_config.d/99-hardened.conf)" == "600" ]] || \
    { warn "Verify failed: 99-hardened.conf permissions incorrect"; failed=1; }

  [[ $failed -eq 0 ]] || error "configs verification failed"
  log "configs verified ✓"
  return 0
}