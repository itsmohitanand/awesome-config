#!/usr/bin/env bash
# switch-theme <name>
# Switches kitty, starship, neovim, and zellij to the named theme in one command.
# Available themes: poimandres | cyberdream | everblush

set -e

THEME="${1:?Usage: switch-theme <theme-name>}"

KITTY_CONF="$HOME/.config/kitty/kitty.conf"
KITTY_THEME="$HOME/.config/kitty/themes/${THEME}.conf"
STARSHIP_CONF="$HOME/.config/starship.toml"
NVIM_INIT="$HOME/.config/nvim/init.lua"
ZELLIJ_CONF="$HOME/.config/zellij/config.kdl"

# Validate theme file exists for kitty
if [[ ! -f "$KITTY_THEME" ]]; then
    echo "Error: No kitty theme file found at $KITTY_THEME" >&2
    exit 1
fi

# Kitty
sed -i "s|^include themes/.*\.conf|include themes/${THEME}.conf|" "$KITTY_CONF"

# Starship
sed -i "s|^palette = '.*'|palette = '${THEME}'|" "$STARSHIP_CONF"

# Neovim
sed -i "s|^local theme = '.*'|local theme = '${THEME}'|" "$NVIM_INIT"

# Zellij
sed -i "s|^theme \".*\"|theme \"${THEME}\"|" "$ZELLIJ_CONF"

echo "Switched to theme: ${THEME}"
echo "  kitty  — reload with ctrl+shift+F5"
echo "  zellij — requires session restart"
echo "  nvim   — restart or :source"
echo "  starship — takes effect in new shells"
