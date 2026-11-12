#!/usr/bin/env bash
# Build + install the Steel sound theme and make it the system sound theme.
set -eu
cd "$(dirname "$0")"
T=~/.local/share/sounds/steel; tmp=$(mktemp -d)
python3 -I gen.py "$tmp" >/dev/null
mkdir -p $T/stereo
for f in "$tmp"/*.wav; do
  ffmpeg -loglevel error -y -i "$f" -c:a libvorbis -q:a 5 "$T/stereo/$(basename "${f%.wav}").oga"
done
rm -rf "$tmp"
cat > $T/index.theme <<'IDX'
[Sound Theme]
Name=Steel
Comment=Soft glassy chimes to match the steel desktop
Inherits=ocean,freedesktop
Directories=stereo

[stereo]
OutputProfile=stereo
IDX
kwriteconfig6 --file kdeglobals --group Sounds --key Theme steel
gsettings set org.gnome.desktop.sound theme-name steel 2>/dev/null || true
echo "✓ steel sounds ($(ls $T/stereo | wc -l) files)"
