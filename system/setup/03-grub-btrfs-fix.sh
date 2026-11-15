#!/usr/bin/env bash
# Part 3 root setup: grub-btrfs auto-refresh fix. (ydotool/voice typing removed 2026-11-15)
# Run with: sudo bash setup-root-3.sh
set -u
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail=()

step "grub-btrfs: refresh boot menu when snapshots change (Fedora fix)"
systemctl disable grub-btrfs.path 2>/dev/null
cat > /etc/systemd/system/grub-btrfs-snapshots.path <<'EOF'
[Unit]
Description=Refresh GRUB snapshot menu when snapper snapshots change

[Path]
PathModified=/.snapshots
Unit=grub-btrfs.service

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now grub-btrfs-snapshots.path || fail+=("grub-btrfs path")
echo "dnf pre/post snapshots (Sunshine install should appear):"
snapper -c root list | grep -E '\| (pre|post) ' | tail -4

echo
if ((${#fail[@]})); then echo -e "\033[1;31mProblems: ${fail[*]}\033[0m"; else echo -e "\033[1;32mAll done.\033[0m"; fi
