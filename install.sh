#!/bin/bash
set -e
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.config/kitty ~/.config/zellij/layouts

ln -sf "$DOTFILES/kitty/kitty.conf"                   ~/.config/kitty/kitty.conf
ln -sf "$DOTFILES/zellij/config.kdl"                  ~/.config/zellij/config.kdl
ln -sf "$DOTFILES/zellij/layouts/python-dev.kdl"      ~/.config/zellij/layouts/python-dev.kdl
ln -sf "$DOTFILES/starship/starship.toml"              ~/.config/starship.toml

echo "Dotfiles installed."
