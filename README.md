# dotfiles

My Linux setup (Fedora KDE, Wayland), managed with [GNU stow](https://www.gnu.org/software/stow/).

## Install
```sh
sudo dnf install fish starship fzf zoxide bat stow
git clone git@github.com:hsynrsd/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh        # or just: stow fish starship
```

## What's in here
| Package | What |
|---|---|
| `fish`, `starship` | Shell + prompt (incl. `copy` function) |
| `backup` | `backup` — restic to `/mnt/innovation` + Cloudflare R2, daily systemd timer |
| `copy` | `termcopy` — `copy` copies last command output / piped input / `-c` last command / `-r` re-run |
| `voicetype` | Meta+Z voice typing: faster-whisper (large-v3-turbo) on GPU, typed via ydotool |
| `just` | `~/justfile`: `just update`, `just clean`, `just snapshots`, `just backup-status`, … |
| `wallrot` | Wallpaper Engine "Steel" playlist: scores previews (dark/cool/muted), Meta+Alt+W next, Meta+Alt+Shift+W ban, `wallrot keep`/`status`/`scan` |
| `vscode-theme/` | Steel VS Code color theme, packaged + installed by `vscode-theme/install.sh` |
| `theme/` | Plasma look (`apply.sh`); `gtk.sh` gives libadwaita + Flatpak apps the Steel colors |
| `system/` | Root setup scripts, keyd config, `95snapboot` dracut module (boot read-only btrfs snapshots from GRUB via tmpfs overlay), `07-nvidia-initramfs.sh` (auto-rebuild initramfs + notify after NVIDIA/kernel updates) |

**Secrets are never committed** (public repo): `~/.config/restic/password` and `r2.env` live in Bitwarden.
