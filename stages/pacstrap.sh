#!/usr/bin/env bash

do_pacstrap() {
  section "Installing base system (pacstrap)"

  # shellcheck disable=SC2086
  pacstrap /mnt base $KERNELS linux-firmware $EXTRA_PACKAGES --noconfirm

  log "Base system installed"
  return 0
}