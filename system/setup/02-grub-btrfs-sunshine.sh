#!/usr/bin/env bash
# Part 2 root setup: (1) boot into snapshots from GRUB, (6) Sunshine game streaming.
# Run with: sudo bash setup-root-2.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
U=hsynrsd
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail=()

# ---------------------------------------------------------------- 1. snapshots
step "Install grub-btrfs + dnf snapshot hook"
dnf -y copr enable kylegospo/grub-btrfs || fail+=("copr grub-btrfs")
dnf -y install grub-btrfs libdnf5-plugin-actions || fail+=("dnf grub-btrfs/actions")

step "Snapshot before/after every dnf transaction"
cat > /etc/dnf/libdnf5-plugins/actions.d/snapper.actions <<'EOF'
# Snapper pre/post snapshots around every dnf transaction (from libdnf5-actions(8) example)
pre_transaction::::/usr/bin/sh -c echo\ "tmp.snapper_descr=$(ps\ -o\ command\ --no-headers\ -p\ '${pid}')"
pre_transaction::::/usr/bin/sh -c echo\ "tmp.snapper_pre_number=$(snapper\ --config\ root\ create\ --type\ pre\ --cleanup-algorithm\ number\ --print-number\ --description\ '${tmp.snapper_descr}')"
post_transaction::::/usr/bin/sh -c [\ -n\ "${tmp.snapper_pre_number}"\ ]\ &&\ snapper\ --config\ root\ create\ --type\ post\ --cleanup-algorithm\ number\ --pre-number\ "${tmp.snapper_pre_number}"\ --description\ "${tmp.snapper_descr}"\ ;\ echo\ tmp.snapper_pre_number\ ;\ echo\ tmp.snapper_descr
EOF
snapper -c root set-config NUMBER_CLEANUP=yes NUMBER_LIMIT=20 NUMBER_LIMIT_IMPORTANT=10 || fail+=("snapper root config")

step "Boot module: make read-only snapshots bootable (tmpfs overlay)"
install -d /usr/lib/dracut/modules.d/95snapboot
install -m 0755 "$HERE/../dracut/95snapboot/module-setup.sh" "$HERE/../dracut/95snapboot/snapboot-overlay.sh" /usr/lib/dracut/modules.d/95snapboot/
echo 'add_dracutmodules+=" snapboot "' > /etc/dracut.conf.d/90-snapboot.conf
echo "Rebuilding initramfs for all kernels (takes a minute)..."
dracut -f --regenerate-all || fail+=("dracut")
lsinitrd "/boot/initramfs-$(uname -r).img" 2>/dev/null | grep -q snapboot-overlay \
  && echo "snapboot module is in the initramfs" || fail+=("snapboot missing from initramfs")

step "Configure grub-btrfs"
CFG=/etc/default/grub-btrfs/config
if [ -f "$CFG" ] && ! grep -q '# --- local settings ---' "$CFG"; then
  cat >> "$CFG" <<'EOF'

# --- local settings ---
GRUB_BTRFS_LIMIT="20"
GRUB_BTRFS_SHOW_SNAPSHOTS_FOUND="true"
GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"
GRUB_BTRFS_MKCONFIG=/usr/sbin/grub2-mkconfig
GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check
# SELinux permissive only when booted into a snapshot (recovery boots)
GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="enforcing=0"
EOF
fi
# Always show the GRUB menu (Fedora hides it by default)
grub2-editenv - unset menu_auto_hide

step "Baseline snapshot + regenerate GRUB menu"
snapper -c root create --cleanup-algorithm number --description "baseline (grub-btrfs setup)"
grub2-mkconfig -o /boot/grub2/grub.cfg || fail+=("grub2-mkconfig")
grep -q 'snapshots' /boot/grub2/grub-btrfs.cfg 2>/dev/null \
  && echo "Snapshot menu entries: $(grep -c '^ *menuentry' /boot/grub2/grub-btrfs.cfg)" \
  || fail+=("no grub-btrfs.cfg entries")
systemctl enable --now grub-btrfs.path 2>/dev/null || systemctl enable --now grub-btrfsd 2>/dev/null || fail+=("grub-btrfs auto-update unit")

# ---------------------------------------------------------------- 6. Sunshine
step "Install Sunshine"
dnf -y copr enable lizardbyte/stable || fail+=("copr sunshine")
dnf -y install Sunshine || fail+=("dnf Sunshine")
SUN=$(readlink -f "$(command -v sunshine)" 2>/dev/null)
[ -n "$SUN" ] && setcap cap_sys_admin+p "$SUN" || fail+=("setcap sunshine")

step "Firewall: allow Moonlight on LAN + Tailscale (web UI stays local-only)"
for p in 47984/tcp 47989/tcp 48010/tcp 47998/udp 47999/udp 48000/udp 48002/udp 48010/udp; do
  firewall-cmd -q --permanent --zone=public --add-port=$p
done
firewall-cmd -q --reload || fail+=("firewall")

echo
if ((${#fail[@]})); then echo -e "\033[1;31mProblems: ${fail[*]}\033[0m"; else echo -e "\033[1;32mAll done.\033[0m"; fi
