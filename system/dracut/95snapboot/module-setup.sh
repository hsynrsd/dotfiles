#!/usr/bin/bash
# snapboot: when booting a btrfs snapshot from the GRUB menu (grub-btrfs), put a tmpfs
# overlay on top of the read-only snapshot so the system can boot normally.
# Changes made while booted into a snapshot are kept in RAM and lost on reboot.
check() { return 0; }
depends() { echo base; }
installkernel() { hostonly="" instmods overlay; }
install() { inst_hook pre-pivot 08 "$moddir/snapboot-overlay.sh"; }
