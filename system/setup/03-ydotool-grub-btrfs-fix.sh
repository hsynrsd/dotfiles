#!/usr/bin/env bash
# Part 3 root setup: ydotool (voice typing) + grub-btrfs auto-refresh fix.
# Run with: sudo bash setup-root-3.sh
set -u
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail=()

step "ydotool: virtual keyboard so voice typing can type into any app"
dnf -y install ydotool || fail+=("dnf ydotool")
mkdir -p /etc/systemd/system/ydotool.service.d
cat > /etc/systemd/system/ydotool.service.d/user-socket.conf <<'EOF'
# Socket owned by hsynrsd only, so only this user can send keystrokes.
[Service]
RuntimeDirectory=ydotoold
ExecStart=
ExecStart=/usr/bin/ydotoold --socket-path=/run/ydotoold/socket --socket-own=1000:1000
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now ydotool.service || fail+=("ydotool service")
sleep 1; ls -l /run/ydotoold/socket || fail+=("ydotool socket")

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
echo "dnf pre/post snapshots (Sunshine/ydotool installs should appear):"
snapper -c root list | grep -E '\| (pre|post) ' | tail -4

echo
if ((${#fail[@]})); then echo -e "\033[1;31mProblems: ${fail[*]}\033[0m"; else echo -e "\033[1;32mAll done.\033[0m"; fi
