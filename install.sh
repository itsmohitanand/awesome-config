#!/usr/bin/env bash
# install.sh — symlink awesome-config into ~/.config and friends.
# Idempotent: safe to run repeatedly. Detects parent-dir symlinks that would
# otherwise cause self-loops (e.g. when ~/.config/nvim is already a whole-dir
# symlink to this repo).
#
# This script never edits ~/.zshrc or ~/.bashrc. Source ~/.modern_shell_config
# from your shell rc file yourself — see the message printed at the end.

set -euo pipefail
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

link() {
    local rel="$1" dest="$2"
    local src="$DOTFILES/$rel"

    if [[ ! -e "$src" && ! -L "$src" ]]; then
        printf '  skip (missing in repo): %s\n' "$rel" >&2
        return
    fi

    # If dest already resolves to src (already linked, or reached via a parent
    # symlink), do nothing. Creating a symlink here would produce a self-loop.
    local src_real dest_real
    src_real="$(realpath "$src")"
    dest_real="$(realpath -m "$dest")"
    if [[ "$dest_real" == "$src_real" ]]; then
        printf '  ok:   %s\n' "$dest"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    printf '  link: %s -> %s\n' "$dest" "$src"
}

echo "Symlinking awesome-config from $DOTFILES"

# Kitty
link kitty/kitty.conf                  "$HOME/.config/kitty/kitty.conf"
link kitty/themes/poimandres.conf      "$HOME/.config/kitty/themes/poimandres.conf"
link kitty/themes/cyberdream.conf      "$HOME/.config/kitty/themes/cyberdream.conf"
link kitty/themes/everblush.conf       "$HOME/.config/kitty/themes/everblush.conf"

# Zellij
link zellij/config.kdl                 "$HOME/.config/zellij/config.kdl"
link zellij/layouts/python-dev.kdl     "$HOME/.config/zellij/layouts/python-dev.kdl"
link zellij/layouts/phd.kdl            "$HOME/.config/zellij/layouts/phd.kdl"
link zellij/layouts/latex-thesis.kdl   "$HOME/.config/zellij/layouts/latex-thesis.kdl"

# Starship
link starship/starship.toml            "$HOME/.config/starship.toml"

# Neovim
link nvim/init.lua                     "$HOME/.config/nvim/init.lua"
link nvim/lua                          "$HOME/.config/nvim/lua"

# niri (Wayland compositor) and its shell components.
link niri/config.kdl                   "$HOME/.config/niri/config.kdl"
link waybar/config.jsonc               "$HOME/.config/waybar/config.jsonc"
link waybar/style.css                  "$HOME/.config/waybar/style.css"
link fuzzel/fuzzel.ini                 "$HOME/.config/fuzzel/fuzzel.ini"
link swaync/config.json                "$HOME/.config/swaync/config.json"
link swaync/style.css                  "$HOME/.config/swaync/style.css"

link niri/set-wallpaper.sh             "$HOME/.local/bin/set-wallpaper"
link niri/lock.sh                      "$HOME/.local/bin/lock-session"
link niri/keys.sh                      "$HOME/.local/bin/niri-keys"
chmod +x "$DOTFILES/niri/set-wallpaper.sh" "$DOTFILES/niri/lock.sh" \
         "$DOTFILES/niri/keys.sh" "$DOTFILES/niri/install-deps.sh"
mkdir -p "$HOME/.config/wallpapers" "$HOME/Pictures/Screenshots"

# Ubuntu ships waybar.service globally enabled and WantedBy=graphical-session
# .target, which niri.service joins — so systemd starts a second bar on top of
# the one niri/config.kdl spawns. Mask it so the config stays authoritative.
if systemctl --user list-unit-files waybar.service >/dev/null 2>&1; then
    if [[ "$(systemctl --user is-enabled waybar.service 2>/dev/null)" != "masked" ]]; then
        systemctl --user mask waybar.service >/dev/null 2>&1 \
            && echo "  mask: waybar.service (prevents a duplicate top bar)"
    fi
fi

# Ulauncher — kept so the GNOME session still works as a fallback while you
# settle into niri. Under niri the launcher is fuzzel (Mod+Space).
# Link the single autostart entry, not all of ~/.config/autostart — other apps
# drop their own .desktop files in that directory.
link ulauncher/settings.json           "$HOME/.config/ulauncher/settings.json"
link ulauncher/shortcuts.json          "$HOME/.config/ulauncher/shortcuts.json"
link ulauncher/ulauncher.desktop       "$HOME/.config/autostart/ulauncher.desktop"
chmod +x "$DOTFILES/ulauncher/gnome-keybinding.sh"
"$DOTFILES/ulauncher/gnome-keybinding.sh"

# Modern shell config (source this from ~/.zshrc or ~/.bashrc yourself)
link .modern_shell_config              "$HOME/.modern_shell_config"

# Theme switcher
link switch-theme.sh                   "$HOME/.local/bin/switch-theme"
chmod +x "$DOTFILES/switch-theme.sh"

# Apply the current theme so waybar/swaync get their theme.css symlink and
# every surface starts in sync. Defaults to everblush on a fresh machine.
CURRENT_THEME="$(cat "$HOME/.config/current-theme" 2>/dev/null || echo everblush)"
echo
echo "Applying theme: $CURRENT_THEME"
"$DOTFILES/switch-theme.sh" "$CURRENT_THEME" || echo "  (theme switch failed — run switch-theme manually)"

echo
echo "Done. This script did NOT touch ~/.zshrc or ~/.bashrc."
echo "If you haven't already, add this line to your shell rc:"
echo "    source ~/.modern_shell_config"
echo
echo "Switch themes with:  switch-theme poimandres | cyberdream | everblush"
echo "Install the niri desktop stack with:  ./niri/install-deps.sh"
