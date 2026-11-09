#!/usr/bin/env bash
# One-time root setup. Run with: sudo bash setup-root.sh
set -u
U=hsynrsd
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail=()

step "Enable COPRs for keyd and lazygit"
dnf -y copr enable alternateved/keyd || fail+=("copr keyd")
dnf -y copr enable atim/lazygit      || fail+=("copr lazygit")

step "Install packages"
dnf -y install restic just waydroid nvtop || fail+=("dnf base")
dnf -y install keyd    || fail+=("keyd")
dnf -y install lazygit || fail+=("lazygit")

step "Local backup repo folder on /mnt/innovation"
mkdir -p /mnt/innovation/restic-home && chown $U:$U /mnt/innovation/restic-home || fail+=("backup dir")

step "Snapper config for /home"
if ! snapper list-configs | grep -q '^home '; then
  snapper -c home create-config /home || fail+=("snapper home")
fi
snapper -c home set-config ALLOW_USERS=$U SYNC_ACL=yes \
  TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes \
  TIMELINE_LIMIT_HOURLY=10 TIMELINE_LIMIT_DAILY=7 TIMELINE_LIMIT_WEEKLY=4 \
  TIMELINE_LIMIT_MONTHLY=3 TIMELINE_LIMIT_YEARLY=0 || fail+=("snapper settings")
systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

step "keyd: CapsLock = Esc on tap, Ctrl on hold"
if command -v keyd >/dev/null; then
  mkdir -p /etc/keyd
  cat > /etc/keyd/default.conf <<'EOF'
[ids]
*

[main]
capslock = overload(control, esc)
EOF
  systemctl enable --now keyd && keyd reload || fail+=("keyd service")
fi

step "Default shell -> fish"
chsh -s /usr/bin/fish $U || fail+=("chsh")

step "Waydroid (downloads ~1 GB Android image)"
if command -v waydroid >/dev/null; then
  systemctl enable --now waydroid-container
  [ -d /var/lib/waydroid/images ] || waydroid init || fail+=("waydroid init")
  # NVIDIA GPUs aren't supported for Android graphics -> use software rendering
  PROP=/var/lib/waydroid/waydroid_base.prop
  if [ -f "$PROP" ] && ! grep -q swiftshader "$PROP"; then
    sed -i '/^ro.hardware.gralloc=/d;/^ro.hardware.egl=/d' "$PROP"
    printf 'ro.hardware.gralloc=default\nro.hardware.egl=swiftshader\n' >> "$PROP"
  fi
  systemctl restart waydroid-container
fi

echo
if ((${#fail[@]})); then echo -e "\033[1;31mProblems: ${fail[*]}\033[0m"; else echo -e "\033[1;32mAll done.\033[0m"; fi
