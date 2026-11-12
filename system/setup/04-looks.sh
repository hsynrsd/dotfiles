#!/usr/bin/env bash
# Rounded window corners, btop, tldr, steel-blue Papirus folders.
# Run with: sudo bash 04-looks.sh   (theme settings themselves: theme/apply.sh as your user)
set -u
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail=()

step "Rounded corners effect (COPR, rebuilt for each Plasma release)"
dnf -y copr enable matinlotfali/KDE-Rounded-Corners || fail+=("copr rounded-corners")
dnf -y install kwin-effect-roundcorners           || fail+=("kwin-effect-roundcorners")

step "btop + tldr (tealdeer)"
dnf -y install btop tealdeer || fail+=("btop/tealdeer")

step "Papirus folders → muted steel blue (nordic)"
curl -fsSL -o /usr/local/bin/papirus-folders \
  https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders \
  && chmod +x /usr/local/bin/papirus-folders \
  && papirus-folders -C nordic --theme Papirus-Dark || fail+=("papirus-folders")

if [ ${#fail[@]} -eq 0 ]; then echo -e "\n✓ done"; else echo -e "\n✗ failed: ${fail[*]}"; exit 1; fi
