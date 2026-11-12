#!/usr/bin/env bash
# Catppuccin Mocha everywhere (Plasma, Konsole, fish, starship, bat, eza, fzf).
# Run as your user, no sudo:  ./theme/apply.sh     Safe to re-run.
set -eu
cd "$(dirname "$0")"
A=$PWD/assets
WP=~/Pictures/Wallpapers
WALLS="blue-landscape.png city-horizon.jpg cabin.png black-hole.png cottages-river.png cloud-coffee.jpg"
DEFAULT_WALL=cottages-river.png

# ── Plasma ────────────────────────────────────────────
mkdir -p ~/.local/share/color-schemes ~/.icons
cp $A/color-schemes/CatppuccinMochaSteel.colors ~/.local/share/color-schemes/
plasma-apply-colorscheme CatppuccinMochaSteel
plasma-apply-desktoptheme breeze-dark
/usr/libexec/plasma-changeicons Papirus-Dark

# Wallpapers (desktop + lock screen)
mkdir -p $WP
for f in $WALLS; do
  [ -f $WP/$f ] || curl -fsSL -o $WP/$f https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master/$f
done
plasma-apply-wallpaperimage $WP/$DEFAULT_WALL
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$WP/$DEFAULT_WALL"

# KWin: stronger blur, smooth animations, centered new windows
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig6 --file kwinrc --group Effect-blur --key BlurStrength 10
kwriteconfig6 --file kwinrc --group Effect-blur --key NoiseStrength 3
kwriteconfig6 --file kwinrc --group Plugins --key magiclampEnabled false
kwriteconfig6 --file kwinrc --group Plugins --key squashEnabled true
kwriteconfig6 --file kwinrc --group Windows --key Placement Centered
# Breeze title bars: no outline, slightly bigger buttons
kwriteconfig6 --file breezerc --group Common --key OutlineIntensity OutlineOff
kwriteconfig6 --file breezerc --group Windeco --key ButtonSize ButtonLarge
qdbus-qt6 org.kde.KWin /KWin reconfigure 2>/dev/null || true

# Panels: thin top bar + centered floating dock
# (panels.js rebuilds the top bar each run)
qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$(cat panels.js)"

# ── Konsole ───────────────────────────────────────────
K=~/.local/share/konsole
mkdir -p $K
cp $A/konsole/steel.colorscheme $K/
P=$K/Fedora.profile
[ -f $P ] || printf '[General]\nName=Fedora\nCommand=/usr/bin/fish\nParent=FALLBACK/\n' > $P
kwriteconfig6 --file $P --group Appearance --key ColorScheme steel
kwriteconfig6 --file $P --group Appearance --key Font "JetBrainsMono Nerd Font,10,-1,5,300,0,0,0,0,0,0,0,0,0,0,1,Light"
kwriteconfig6 --file $P --group Appearance --key LineSpacing 0
kwriteconfig6 --file $P --group General --key TerminalMargin 14
kwriteconfig6 --file $P --group General --key TerminalCenter true
kwriteconfig6 --file $P --group Scrolling --key ScrollBarPosition 2
kwriteconfig6 --file $P --group "Cursor Options" --key CursorShape 1
kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile Fedora.profile
# No toolbars: launcher override (dock icon, menu and Ctrl+Alt+T all use it)
mkdir -p ~/.local/share/applications
sed 's/^Exec=konsole/Exec=konsole --hide-toolbars/' /usr/share/applications/org.kde.konsole.desktop > ~/.local/share/applications/org.kde.konsole.desktop
update-desktop-database -q ~/.local/share/applications 2>/dev/null || true

# ── CLI tools ─────────────────────────────────────────
mkdir -p ~/.config/bat/themes ~/.config/eza
cp "$A/bat/Catppuccin Mocha.tmTheme" ~/.config/bat/themes/
echo '--theme="Catppuccin Mocha"' > ~/.config/bat/config
bat cache --build >/dev/null
cp $A/eza/theme.yml ~/.config/eza/theme.yml
mkdir -p ~/.config/btop/themes ~/.config/fastfetch
cp $A/btop/steel.theme ~/.config/btop/themes/
if [ -f ~/.config/btop/btop.conf ]; then
  sed -i 's/^color_theme = .*/color_theme = "steel"/; s/^theme_background = .*/theme_background = False/' ~/.config/btop/btop.conf
else
  printf 'color_theme = "steel"\ntheme_background = False\nrounded_corners = True\n' > ~/.config/btop/btop.conf
fi
cp $A/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
mkdir -p ~/.local/share/brave-steel-theme && cp $A/brave-steel/manifest.json ~/.local/share/brave-steel-theme/

# ── Rounded corners (effect installed by system/setup/04-looks.sh) ──
R="--file kwinrc --group Round-Corners"
kwriteconfig6 $R --key Size 12
kwriteconfig6 $R --key InactiveCornerRadius 12
kwriteconfig6 $R --key OutlineThickness 1
kwriteconfig6 $R --key InactiveOutlineThickness 1
kwriteconfig6 $R --key OutlineColor "59,66,97"
kwriteconfig6 $R --key InactiveOutlineColor "38,43,63"
kwriteconfig6 $R --key SecondOutlineThickness 0
kwriteconfig6 $R --key InactiveSecondOutlineThickness 0
kwriteconfig6 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled true
qdbus-qt6 org.kde.KWin /KWin reconfigure 2>/dev/null || true

# ── Desktop widgets (clock, CPU/GPU/RAM, network); plasmashell restart loads them ──
qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$(cat desktop-widgets.js)"

./extras.sh
kwriteconfig6 --file kdeglobals --group Sounds --key Theme ocean   # steel sounds (sounds/build.sh) dropped: too synthetic
systemctl --user restart plasma-plasmashell
echo "✓ Theme applied. Open a new Konsole window; log out/in once so every app picks up the fonts."
