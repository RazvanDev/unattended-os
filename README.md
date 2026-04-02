# unattended-os
 
An unattended, hardened Arch Linux installer with full disk encryption, firewall, kernel hardening, and optional desktop environment. Designed for repeatability, auditability, and security-first deployments.
 
---
 
## Features
 
- Fully unattended installation driven by YAML configuration
- LUKS full disk encryption on root, home, swap, and log partitions
- SSH hardening with post-quantum cryptography
- nftables firewall with dynamic rule generation from config
- Kernel hardening via sysctl
- Separate encrypted log partition
- Optional KDE Plasma desktop environment
- Stage-based install with resume on failure
- Mirror validation before package installation
- Per-stage verification
 
---
 
## Requirements
 
- UEFI firmware
- Active network connection (ethernet recommended)
- Arch Linux live ISO booted
- Target disk with at least 80G available
 
---
 
## Quick Start
 
```bash
# clone the repo
git clone https://github.com/RazvanDev/unattended-os
cd unattended-os
 
# edit configuration
vim install-conf.yaml
vim install-secrets.yaml
 
# run installer
./install.sh install-conf.yaml install-secrets.yaml --unattended
```
 
---
 
## Configuration
 
### install-conf.yaml
 
Main configuration file. Controls partitioning, locale, packages, services, SSH, firewall, mirrors, logging, and desktop.
 
```yaml
partitions:
  esp:
    size: 512
    unit: M
    wipe: true
  swap:
    size: 2
    unit: G
    wipe: true
    encrypt: true
  root:
    size: 25
    unit: G
    wipe: true
    fs: ext4
    encrypt: true
  log:
    size: 5
    unit: G
    wipe: true
    fs: ext4
    encrypt: true
    mount: /var/log
  home:
    size: 40
    unit: G
    wipe: false
    fs: ext4
    encrypt: true
    mount: /home
  media:
    wipe: false
    fs: ext4
    encrypt: false
    mount: /mnt/media
 
locale:
  lang: en_US.UTF-8
  timezone: Europe/Bucharest
  keymap: us
 
system:
  hostname: archie
  kernels:
    - linux
    - linux-lts
 
packages:
  - vim
  - networkmanager
  - sudo
  - grub
  - efibootmgr
  - openssh
  - nftables
  - iptables-nft
  - bind-tools
 
services:
  - name: NetworkManager
    enabled: true
    start: true
  - name: sshd
    enabled: true
    start: true
  - name: nftables
    enabled: true
    start: false
 
user:
  name: raz
  groups: wheel
 
ssh:
  port: 10022
  allow_users:
    - name: raz
      from: "10.0.0.0/8"
 
firewall:
  interface: []        # empty = auto-detect
  icmp:
    enabled: true
    rate: "10/second"
  inbound:
    - proto: tcp
      dport: 10022
      saddr: "10.0.0.0/8"
      rate: "15/minute"
      comment: "ssh"
  outbound:
    - proto: udp
      dport: 53
      daddr: []
      comment: "dns"
    - proto: udp
      dport: 123
      daddr: []
      comment: "ntp"
    - proto: tcp
      dport: 443
      daddr: []
      comment: "https"
 
mirrors:
  countries:
    - RO
    - DE
  protocol: https
  ip_version:
    - 4
    - 6
 
desktop:
  enabled: false       # set true for KDE Plasma
```
 
### install-secrets.yaml
 
Sensitive values kept separate from main config. Never commit this file to version control.
 
```yaml
encryption:
  passphrase: "your-luks-passphrase"
 
root:
  password: "your-root-password"
 
user:
  password: "your-user-password"
```
 
---
 
## Project Structure
 
```
unattended-os/
├── install.sh                  # main entry point
├── install-conf.yaml           # configuration
├── install-secrets.yaml        # secrets (never commit)
├── build-iso.sh                # builds custom archiso
├── auto-install.service        # systemd service for auto-start
├── configs/
│   ├── 99-hardened-sshd_config # hardened SSH config
│   ├── 99-hardened-nftables.conf
│   ├── 99-hardened-sysctl.conf
│   └── ssh-banner.txt
├── lib/
│   ├── common.sh               # logging, state tracking, run_stage
│   ├── config.sh               # yaml parsing, variable loading
│   └── variables.sh            # disk detection, partition naming
├── stages/
│   ├── mirror-check.sh         # validate and update mirrorlist
│   ├── partition.sh            # fdisk partition table
│   ├── format.sh               # LUKS + filesystem formatting
│   ├── mount.sh                # mount partitions
│   ├── pacstrap.sh             # base system install
│   ├── fstab.sh                # generate fstab
│   ├── locale.sh               # timezone, locale, keymap
│   ├── initramfs.sh            # mkinitcpio with encrypt hook
│   ├── services.sh             # enable/start systemd services
│   ├── users.sh                # create users and set passwords
│   ├── desktop.sh              # optional KDE Plasma install
│   ├── ssh_config.sh           # deploy hardened SSH config
│   ├── firewall.sh             # generate and deploy nftables rules
│   ├── sysctl.sh               # deploy kernel hardening params
│   └── bootloader.sh           # GRUB + crypttab
└── verificators/
    ├── verify_partitioning.sh
    ├── verify_pacstrap.sh
    ├── verify_fstab.sh
    ├── verify_locale.sh
    ├── verify_initramfs.sh
    ├── verify_services.sh
    ├── verify_users.sh
    ├── verify_ssh_config.sh
    ├── verify_firewall.sh
    ├── verify_sysctl.sh
    ├── verify_bootloader.sh
    └── ...
```
 
---
 
## Install Stages
 
The installer runs stages in order, tracking completion state. Failed stages can be resumed without restarting from scratch.
 
| Stage | Description |
|---|---|
| mirrors | Fetch optimal mirrorlist for configured countries |
| partitioning | Create partition table, format, encrypt, mount |
| pacstrap | Install base system and packages |
| fstab | Generate filesystem table |
| locale | Set timezone, locale, keymap |
| initramfs | Configure mkinitcpio with encryption hooks |
| services | Enable and start systemd services |
| users | Create user accounts and set passwords |
| desktop | Install KDE Plasma (if enabled) |
| ssh_config | Deploy hardened SSH configuration |
| firewall | Generate and deploy nftables ruleset |
| sysctl | Deploy kernel hardening parameters |
| bootloader | Install GRUB and configure crypttab |
 
---
 
## Security Hardening
 
### SSH
- Password authentication disabled — keys only
- Root login disabled
- Forwarding disabled (TCP, agent, X11)
- Post-quantum key exchange algorithms
- Restricted to specific users and IP ranges
- Rate limited new connections
- Verbose logging
 
### Firewall (nftables)
- Default drop policy on input, output, and forward
- Stateful connection tracking
- ICMP rate limited
- SSH restricted by source IP and rate
- Outbound restricted to DNS, NTP, HTTPS
- All drops logged
 
### Kernel (sysctl)
- Full ASLR enabled
- Kernel pointer restriction
- dmesg restricted to root
- IP forwarding disabled
- ICMP redirect attacks mitigated
- SYN flood protection
- Martian packet logging
- BPF restricted to root
- ptrace restricted
- Unprivileged user namespaces disabled
- Core dumps disabled
 
### Disk Encryption
- LUKS2 on root, home, swap, and log partitions
- ESP unencrypted (required for GRUB)
- Media partition optionally unencrypted
 
---
 
## Resume on Failure
 
The installer tracks stage completion in a state file. On failure:
 
- Failures at partitioning or pacstrap → full cleanup and fresh start
- Failures after pacstrap → mounts preserved, resume from failed stage
 
State file location: `/mnt/install-state` (migrated from `/tmp/install-state` after partitioning)
 
---
 
## Testing with QEMU
 
```bash
# create test disk
qemu-img create -f qcow2 ~/workspace/test-disk.qcow2 100G
 
# run installer
sudo kvm -m 4G -smp 4 \
  -bios /usr/share/ovmf/OVMF.fd \
  -cdrom ~/unattendedos/unattended-os/out/archlinux-*.iso \
  -drive file=~/workspace/test-disk.qcow2,format=qcow2,snapshot=on \
  -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:10022 \
  -boot d
 
# SSH into installed system
ssh -p 2222 raz@localhost
```
 
---
 
## Roadmap
 
- [ ] auditd rules (Session 4)
- [ ] AppArmor/SELinux profiles
- [ ] Secure Boot integration
- [ ] Log rotation (journald + logrotate)
- [ ] Post-install verification
- [ ] USB keyfile boot unlock
- [ ] CIS/STIG benchmark scanning
- [ ] `--force-reinstall` flag
- [ ] Dynamic partition layout
 
---
 
## License
 
MIT
