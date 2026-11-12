#!/usr/bin/env bash
# After NVIDIA driver / kernel updates: wait for akmods, make sure the nvidia module baked
# into the initramfs matches the driver, rebuild it if not, and send a desktop notification.
# (Prevents "Driver/library version mismatch" → Steam segfaults after reboot.)
# Run with: sudo bash 07-nvidia-initramfs.sh     Manual check: sudo nvidia-initramfs-sync
set -eu

cat > /usr/local/sbin/nvidia-initramfs-sync <<'EOF'
#!/usr/bin/env bash
set -u
notify() {  # notify URGENCY TITLE BODY → every logged-in desktop user
  for bus in /run/user/*/bus; do
    uid=$(stat -c %u "$bus"); user=$(id -nu "$uid") || continue
    runuser -u "$user" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
      notify-send -a "NVIDIA" -i nvidia -u "$1" "$2" "$3" 2>/dev/null || true
  done
  echo "$2: $3"
}

# akmods builds in the background after dnf; give it up to 15 min
for _ in $(seq 180); do pgrep -x akmods >/dev/null || pgrep -f 'akmodsbuild|rpmbuild.*nvidia' >/dev/null || break; sleep 5; done

drv=$(rpm -q --qf '%{VERSION}\n' xorg-x11-drv-nvidia 2>/dev/null | sort -V | tail -1)
[ -n "$drv" ] || exit 0
kver=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core | sort -V | tail -1)
img=/boot/initramfs-$kver.img

mod=$(modinfo -k "$kver" -F version nvidia 2>/dev/null)
if [ "$mod" != "$drv" ]; then
  notify critical "Don't reboot yet" "NVIDIA module for $kver is '${mod:-missing}', driver is $drv. Run: sudo akmods --force --kernels $kver && sudo nvidia-initramfs-sync"
  exit 1
fi

ko=$(lsinitrd "$img" 2>/dev/null | grep -oE 'usr/lib/modules/[^ ]+/nvidia\.ko(\.xz|\.zst)?$' | head -1)
inird=""
if [ -n "$ko" ]; then
  case $ko in *.xz) dec="xz -dc";; *.zst) dec="zstd -dc";; *) dec=cat;; esac
  inird=$(lsinitrd -f "$ko" "$img" | $dec | strings | sed -n 's/^version=//p' | head -1)
fi

if [ "$inird" = "$drv" ]; then
  echo "initramfs for $kver already has nvidia $drv"
  [ "${1:-}" = "--quiet" ] || notify low "NVIDIA OK" "initramfs for $kver has driver $drv. Safe to reboot."
  exit 0
fi

notify normal "Rebuilding initramfs" "NVIDIA ${inird:-none} → $drv for $kver. Don't reboot until done."
if dracut -f --kver "$kver"; then
  notify normal "NVIDIA updated" "initramfs rebuilt with driver $drv. Safe to reboot."
else
  notify critical "initramfs rebuild FAILED" "Don't reboot. Run: sudo dracut -f --kver $kver"
  exit 1
fi
EOF
chmod 755 /usr/local/sbin/nvidia-initramfs-sync

# dnf5 actions: fire (detached, so dnf isn't blocked while akmods builds) on driver or kernel updates
run='/usr/bin/sh -c systemctl\ reset-failed\ nvidia-initramfs-sync\ 2>/dev/null;\ systemd-run\ --no-block\ --unit=nvidia-initramfs-sync\ /usr/local/sbin/nvidia-initramfs-sync\ 2>/dev/null\ ||\ true'
{
  echo "# Keep the nvidia module in the initramfs in sync with the driver (see 07-nvidia-initramfs.sh)"
  for p in 'xorg-x11-drv-nvidia' 'akmod-nvidia' 'kmod-nvidia-*' 'kernel-core'; do
    echo "post_transaction:$p:in::$run"
  done
} > /etc/dnf/libdnf5-plugins/actions.d/nvidia-initramfs.actions

echo "✓ nvidia-initramfs-sync installed; checking now:"
/usr/local/sbin/nvidia-initramfs-sync
