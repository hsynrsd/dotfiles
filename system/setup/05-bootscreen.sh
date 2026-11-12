#!/usr/bin/env bash
# "Steel Net" boot screen (Plymouth). Run with: sudo bash 05-bootscreen.sh
# Undo: sudo plymouth-set-default-theme bgrt -R
# At boot, press Esc to see the plain text log at any time.
set -eu
SRC="$(cd "$(dirname "$0")/../../theme/plymouth/steel-net" && pwd)"
dnf -y install plymouth-plugin-script
rm -rf /usr/share/plymouth/themes/steel-net
cp -r "$SRC" /usr/share/plymouth/themes/steel-net
chmod -R a+rX /usr/share/plymouth/themes/steel-net
echo "==> rebuilding boot image (takes a minute)..."
plymouth-set-default-theme steel-net -R
echo "✓ boot screen set to: $(plymouth-set-default-theme)"
