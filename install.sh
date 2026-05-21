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

# Modern shell config (source this from ~/.zshrc or ~/.bashrc yourself)
link .modern_shell_config              "$HOME/.modern_shell_config"

# Theme switcher
link switch-theme.sh                   "$HOME/.local/bin/switch-theme"
chmod +x "$DOTFILES/switch-theme.sh"

echo
echo "Done. This script did NOT touch ~/.zshrc or ~/.bashrc."
echo "If you haven't already, add this line to your shell rc:"
echo "    source ~/.modern_shell_config"
echo
echo "Switch themes with:  switch-theme poimandres | cyberdream | everblush"
