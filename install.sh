#!/usr/bin/env bash
# Rebuild this setup on a fresh Fedora KDE install.  Usage: ./install.sh
# Secrets are NOT in this repo: restore ~/.config/restic/{password,r2.env} from Bitwarden first.
set -eu
cd "$(dirname "$0")"
PKGS="fish starship backup copy just wallrot yazi espanso"

command -v stow >/dev/null || sudo dnf -y install stow
stow -t ~ $PKGS
echo "✓ linked: $PKGS"

# Root setup (tools, snapper, keyd, grub-btrfs, sunshine) — review before running
echo "→ Next, run as root (in order):"; ls system/setup/*.sh | sed 's/^/    sudo bash /'

kbuildsycoca6 >/dev/null 2>&1 || true

# Krohnkite tiling
if [ ! -d ~/.local/share/kwin/scripts/krohnkite ]; then
  tmp=$(mktemp -d); gh release download -R anametologin/krohnkite -p krohnkite.kwinscript -D "$tmp"
  kpackagetool6 --type=KWin/Script -i "$tmp/krohnkite.kwinscript"; rm -rf "$tmp"
fi
kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled true
kwriteconfig6 --file kwinrc --group Script-krohnkite --key tiledWindowsLayer 1  # normal layer, not keep-below (fullscreen/taskbar fix)
echo "✓ krohnkite"

# Look: Catppuccin Mocha everywhere
./theme/apply.sh

systemctl --user daemon-reload
systemctl --user enable --now backup.timer
echo "✓ backup timer (needs ~/.config/restic/password + r2.env)"

# Wallpaper Engine: Steel playlist (dark/cool/muted wallpapers), Meta+Alt+W next, Meta+Alt+Shift+W ban
kbuildsycoca6 >/dev/null 2>&1 || true
kwriteconfig6 --file kglobalshortcutsrc --group services --group net.local.wallrot-next.desktop --key _launch "Meta+Alt+W"
kwriteconfig6 --file kglobalshortcutsrc --group services --group net.local.wallrot-ban.desktop --key _launch "Meta+Alt+Shift+W"
~/.local/bin/wallrot scan || echo "wallrot: run 'wallrot scan' once Wallpaper Engine wallpapers are installed"

# VS Code: Steel color theme
./vscode-theme/install.sh
