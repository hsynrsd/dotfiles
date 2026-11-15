#!/usr/bin/env bash
# Remove ydotool (voice typing is gone). Small upgrades: yazi (terminal file manager), espanso (text expander, Wayland build),
# automatic security updates (dnf5-automatic), Waydroid (Android apps).
# Run with: sudo bash 08-small-upgrades.sh
set -eu
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
U=${SUDO_USER:?run via sudo from your user}
H=$(getent passwd "$U" | cut -d: -f6)

echo "── remove voice typing leftovers (ydotool) ──"
systemctl disable --now ydotool.service 2>/dev/null || true
rm -rf /etc/systemd/system/ydotool.service.d
dnf -y remove ydotool || true
systemctl daemon-reload

echo "── yazi ─────────────────────────────"
dnf -y copr enable lihaohong/yazi
dnf -y install yazi ffmpegthumbnailer poppler-utils 7zip jq fd-find ripgrep chafa

echo "── automatic security updates ───────"
dnf -y install dnf5-plugin-automatic
mkdir -p /etc/dnf
cat > /etc/dnf/automatic.conf <<'EOF'
# Daily: install security updates only. Never reboots. Snapper snapshots each run (dnf actions).
[commands]
upgrade_type = security
download_updates = yes
apply_updates = yes
reboot = never

[emitters]
emit_via = stdio
EOF
systemctl enable --now dnf5-automatic.timer

echo "── waydroid ─────────────────────────"
dnf -y install waydroid
systemctl enable --now waydroid-container
[ -d /var/lib/waydroid/images ] || waydroid init
# RTX/NVIDIA has no hardware path in Waydroid → software rendering, or it shows a black screen
prop=/var/lib/waydroid/waydroid_base.prop
sed -i '/^ro.hardware.gralloc=/d;/^ro.hardware.egl=/d' "$prop"
printf 'ro.hardware.gralloc=default\nro.hardware.egl=swiftshader\n' >> "$prop"

echo "── espanso (build for Wayland, ~5 min) ──"
dnf -y install rust cargo wxGTK-devel libxkbcommon-devel dbus-devel wayland-devel openssl-devel wl-clipboard
runuser -u "$U" -- bash -c '
  set -eu
  src=~/.cache/espanso-src
  [ -d "$src" ] || git clone -q --depth 1 --branch v2.4.1 https://github.com/espanso/espanso "$src"
  cd "$src"
  cargo build -q -p espanso --release --no-default-features --features modulo,vendored-tls,wayland
  install -Dm755 target/release/espanso ~/.local/bin/espanso
'
# espanso reads the keyboard directly on Wayland; this lets it without running as root
setcap "cap_dac_override+p" "$H/.local/bin/espanso"
uid=$(id -u "$U")
runuser -u "$U" -- env XDG_RUNTIME_DIR=/run/user/$uid DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus \
  bash -c '~/.local/bin/espanso service register && ~/.local/bin/espanso start' || true

echo "✓ done. yazi: type y   espanso: type :date anywhere   Android: open Waydroid from the app menu"
