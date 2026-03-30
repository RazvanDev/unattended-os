do_desktop() {
  section "Installing desktop environment"

  local enabled
  enabled=$(cfg '.desktop.enabled')

  if [[ "$enabled" != "true" ]]; then
    log "Desktop disabled — skipping"
    return 0
  fi

  log "installing desktop environment"
  arch-chroot /mnt pacman -S --noconfirm \
    xorg-server xorg-xinit plasma sddm \
    pipewire pipewire-pulse wireplumber \
    mesa xf86-video-qxl noto-fonts ttf-liberation  
  
  log "enabling display manager"
  arch-chroot /mnt systemctl enable sddm

  log "desktop successfully installed"
  return 0
}