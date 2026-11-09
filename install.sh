#!/usr/bin/env bash
# Rebuild this setup on a fresh Fedora KDE install.  Usage: ./install.sh
# Secrets are NOT in this repo: restore ~/.config/restic/{password,r2.env} from Bitwarden first.
set -eu
cd "$(dirname "$0")"
PKGS="fish starship backup copy voicetype just"

command -v stow >/dev/null || sudo dnf -y install stow
stow -t ~ $PKGS
echo "✓ linked: $PKGS"

# Root setup (tools, snapper, keyd, grub-btrfs, sunshine, ydotool) — review before running
echo "→ Next, run as root (in order):"; ls system/setup/*.sh | sed 's/^/    sudo bash /'

# Voice typing: Python env with faster-whisper + CUDA libs
if [ ! -x ~/.local/share/voicetype/venv/bin/python ]; then
  uv venv -q --python 3.12 ~/.local/share/voicetype/venv
  VIRTUAL_ENV=~/.local/share/voicetype/venv uv pip install -q faster-whisper nvidia-cublas-cu12 'nvidia-cudnn-cu12==9.*'
fi
kbuildsycoca6 >/dev/null 2>&1 || true
kwriteconfig6 --file kglobalshortcutsrc --group services --group net.local.voicetype.desktop --key _launch "Meta+Z"
echo "✓ voice typing (Meta+Z, active after re-login)"

# Krohnkite tiling
if [ ! -d ~/.local/share/kwin/scripts/krohnkite ]; then
  tmp=$(mktemp -d); gh release download -R anametologin/krohnkite -p krohnkite.kwinscript -D "$tmp"
  kpackagetool6 --type=KWin/Script -i "$tmp/krohnkite.kwinscript"; rm -rf "$tmp"
fi
kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled true
echo "✓ krohnkite"

systemctl --user daemon-reload
systemctl --user enable --now backup.timer
echo "✓ backup timer (needs ~/.config/restic/password + r2.env)"
