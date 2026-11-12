#!/usr/bin/env bash
# Extras on top of apply.sh: tiling gaps, focus borders, fonts, menu, notifications,
# Alt+Tab, KRunner, lazygit. Called by apply.sh; safe to run alone.
set -eu
cd "$(dirname "$0")"
A=$PWD/assets
k() { kwriteconfig6 "$@"; }

# ── Krohnkite: gaps around and between tiled windows ──
for s in Left Right Top Bottom; do k --file kwinrc --group Script-krohnkite --key screenGap$s 8; done
k --file kwinrc --group Script-krohnkite --key screenGapBetween 8
k --file kwinrc --group Script-krohnkite --key soleWindowNoGaps false
k --file kwinrc --group Script-krohnkite --key noTileBorder false

# ── Window borders: focused window = steel blue outline, others = faint ──
k --file kwinrc --group Round-Corners --key OutlineThickness 2
k --file kwinrc --group Round-Corners --key OutlineColor "122,162,247"
k --file kwinrc --group Round-Corners --key ActiveOutlineAlpha 200
k --file kwinrc --group Round-Corners --key InactiveOutlineThickness 1
k --file kwinrc --group Round-Corners --key InactiveOutlineColor "49,50,68"

# ── Alt+Tab: thumbnail grid ──
k --file kwinrc --group TabBox --key LayoutName thumbnail_grid

# ── Fonts: JetBrains Mono Nerd Font everywhere ──
UI="JetBrainsMono Nerd Font Propo,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
k --file kdeglobals --group General --key font "$UI"
k --file kdeglobals --group General --key menuFont "$UI"
k --file kdeglobals --group General --key toolBarFont "$UI"
k --file kdeglobals --group General --key smallestReadableFont "JetBrainsMono Nerd Font Propo,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
k --file kdeglobals --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
k --file kdeglobals --group WM --key activeFont "JetBrainsMono Nerd Font Propo,10,-1,5,600,0,0,0,0,0,0,0,0,0,0,1,SemiBold"
gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font Propo 10'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
gsettings set org.gnome.desktop.interface document-font-name 'JetBrainsMono Nerd Font Propo 10'
k --file kdeglobals --group General --key XftAntialias true
k --file kdeglobals --group General --key XftHintStyle hintslight
k --file kdeglobals --group General --key XftSubPixel rgb

# ── Notifications: top right, under the bar ──
k --file plasmanotifyrc --group Notifications --key PopupPosition TopRight
k --file plasmanotifyrc --group Notifications --key PopupTimeout 5000

# ── KRunner (Alt+Space): centered search box ──
k --file krunnerrc --group General --key FreeFloating true
k --file krunnerrc --group General --key ActivateWhenTypingOnDesktop true
k --file krunnerrc --group General --key historyBehavior CompletionSuggestion
k --file krunnerrc --group Plugins --key calculatorEnabled true
k --file krunnerrc --group Plugins --key unitconverterEnabled true
k --file krunnerrc --group Plugins --key baloosearchEnabled true

# ── App menu (Fedora logo): compact grid ──
qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript '
panels().forEach(function (p) { p.widgets("org.kde.plasma.kickoff").forEach(function (w) {
  w.currentConfigGroup = ["General"];
  w.writeConfig("icon", "fedora-logo-icon");
  w.writeConfig("favoritesDisplay", 0);
  w.writeConfig("applicationsDisplay", 0);
  w.writeConfig("compactMode", true);
  w.writeConfig("switchCategoryOnHover", true);
  w.writeConfig("showActionButtonCaptions", false);
  w.writeConfig("highlightNewlyInstalledApps", true);
}); });'

# ── lazygit colors ──
mkdir -p ~/.config/lazygit && cp $A/lazygit/config.yml ~/.config/lazygit/config.yml

# reload KWin + tiling script
qdbus-qt6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript krohnkite >/dev/null 2>&1 || true
qdbus-qt6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
echo "✓ extras applied"
