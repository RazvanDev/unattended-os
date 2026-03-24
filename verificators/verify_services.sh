#!/usr/bin/env bash

verify_services() {
  local failed=0

  for svc in $ENABLED_SERVICES; do
    [[ -L "/mnt/etc/systemd/system/multi-user.target.wants/${svc}.service" ]] || \
      { warn "Verify failed: $svc not enabled"; failed=1; }
  done

  [[ $failed -eq 0 ]] || error "services verification failed"
  log "services verified ✓"
  return 0
}