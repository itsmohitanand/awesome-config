#!/bin/bash
set -e
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.config/kitty/themes ~/.config/zellij/layouts

# Kitty
ln -sf "$DOTFILES/kitty/kitty.conf"                   ~/.config/kitty/kitty.conf
ln -sf "$DOTFILES/kitty/themes/cyberdream.conf"       ~/.config/kitty/themes/cyberdream.conf
ln -sf "$DOTFILES/kitty/themes/everblush.conf"        ~/.config/kitty/themes/everblush.conf

# Zellij
ln -sf "$DOTFILES/zellij/config.kdl"                  ~/.config/zellij/config.kdl
ln -sf "$DOTFILES/zellij/layouts/python-dev.kdl"      ~/.config/zellij/layouts/python-dev.kdl

# Starship
ln -sf "$DOTFILES/starship/starship.toml"             ~/.config/starship.toml

# Shell config (source this from ~/.zshrc or ~/.bashrc)
ln -sf "$DOTFILES/.modern_shell_config"               ~/.modern_shell_config

# Theme switcher
ln -sf "$DOTFILES/switch-theme.sh"                    ~/.local/bin/switch-theme
chmod +x "$DOTFILES/switch-theme.sh"

echo "Dotfiles installed."
echo ""
echo "Add to your ~/.zshrc or ~/.bashrc:"
echo "  source ~/.modern_shell_config"
echo ""
echo "Switch themes with:  switch-theme cyberdream | everblush"
