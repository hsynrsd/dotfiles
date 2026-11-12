#!/usr/bin/env bash
# Quiet, full-res boot: hide GRUB menu + hand a 1920x1080 framebuffer to Plymouth.
# Run with: sudo bash 06-quiet-boot.sh
# Menu still reachable: hold Shift (or tap Esc/F8) right after the BIOS logo.
# It also shows automatically after a failed boot.
set -eu
G=/etc/default/grub
cp -n "$G" "$G.bak-quiet-boot" || true

setkey() {  # setkey KEY VALUE
  if grep -q "^$1=" "$G"; then sed -i "s|^$1=.*|$1=$2|" "$G"; else echo "$1=$2" >> "$G"; fi
}
setkey GRUB_TERMINAL_OUTPUT '"gfxterm"'
setkey GRUB_GFXMODE '"1920x1080,auto"'
setkey GRUB_GFXPAYLOAD_LINUX '"keep"'

grub2-editenv - set menu_auto_hide=1
grub2-mkconfig -o /boot/grub2/grub.cfg
echo "✓ done — reboot to check"
