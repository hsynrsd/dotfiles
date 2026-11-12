#!/usr/bin/env bash
# GTK apps follow the Plasma scheme:
#  - libadwaita apps get Steel colors: assets/gtk/steel-adwaita.css is appended to
#    ~/.config/gtk-4.0/gtk.css (KDE rewrites it on scheme changes; a path unit re-appends)
#  - Flatpak apps can read the GTK config + use the Breeze GTK3 theme
# Called by apply.sh; safe to run alone.
set -eu
cd "$(dirname "$0")"
A=$PWD/assets/gtk

ln -sf "$A/steel-adwaita.css" ~/.config/gtk-4.0/steel-adwaita.css
install -Dm755 "$A/gtk-steel-import" ~/.local/bin/gtk-steel-import
install -Dm644 "$A/gtk-steel-import.service" ~/.config/systemd/user/gtk-steel-import.service
install -Dm644 "$A/gtk-steel-import.path" ~/.config/systemd/user/gtk-steel-import.path
systemctl --user daemon-reload
systemctl --user enable --now gtk-steel-import.path
~/.local/bin/gtk-steel-import

# Flatpaks: GTK theme + read-only access to the generated colors
flatpak install -y --user --noninteractive flathub org.gtk.Gtk3theme.Breeze >/dev/null 2>&1 || true
flatpak override --user \
  --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro \
  --filesystem="$A":ro
echo "✓ GTK/libadwaita/Flatpak colors"
