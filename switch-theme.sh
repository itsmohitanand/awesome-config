#!/usr/bin/env bash
# switch-theme <name>
# Switches every themed surface in one command:
#   terminal   — kitty
#   shell      — starship
#   editor     — neovim
#   multiplex  — zellij
#   compositor — niri focus ring
#   panel      — waybar
#   launcher   — fuzzel
#   notifs     — swaync
#   toolkit    — GTK / Qt colour scheme
#   desktop    — wallpaper
#
# Available themes: poimandres | cyberdream | everblush
#
# Surfaces that support an include/import (kitty, waybar, swaync) get their
# include line or symlink repointed. Surfaces that don't (starship, nvim,
# zellij, niri, fuzzel) get rewritten in place with sed.

set -euo pipefail

THEME="${1:?Usage: switch-theme <poimandres|cyberdream|everblush>}"

DOTFILES="$(cd "$(dirname "$(realpath "$0")")" && pwd)"

KITTY_CONF="$HOME/.config/kitty/kitty.conf"
KITTY_THEME="$HOME/.config/kitty/themes/${THEME}.conf"
STARSHIP_CONF="$HOME/.config/starship.toml"
NVIM_INIT="$HOME/.config/nvim/init.lua"
ZELLIJ_CONF="$HOME/.config/zellij/config.kdl"
NIRI_CONF="$HOME/.config/niri/config.kdl"
FUZZEL_CONF="$HOME/.config/fuzzel/fuzzel.ini"
GTK_PALETTE="$DOTFILES/themes/${THEME}.css"

# ── Palette table ───────────────────────────────────────────────────────────
# Keep in sync with themes/<name>.css and kitty/themes/<name>.conf.
case "$THEME" in
poimandres)
    BG=1B1E28; BG_ALT=171922; SURFACE=303340
    FG=A6ACCD; FG_DIM=767C9D
    ACCENT=5DE4C7; ACCENT2=ADD7FF
    ;;
cyberdream)
    BG=16181a; BG_ALT=1e2124; SURFACE=3c4048
    FG=ffffff; FG_DIM=7b8496
    ACCENT=ffbd5e; ACCENT2=5ea1ff
    ;;
everblush)
    BG=141b1e; BG_ALT=232a2d; SURFACE=2d3437
    FG=dadada; FG_DIM=8a9291
    ACCENT=6cbfbf; ACCENT2=67b0e8
    ;;
*)
    echo "Error: unknown theme '$THEME' (want poimandres, cyberdream or everblush)" >&2
    exit 1
    ;;
esac

if [[ ! -f "$KITTY_THEME" ]]; then
    echo "Error: No kitty theme file found at $KITTY_THEME" >&2
    exit 1
fi

# Only touch a surface if it's actually installed. Lets this script stay useful
# on a machine that has kitty/nvim but not the full niri desktop.
edit() { [[ -f "$1" ]]; }

# ── Terminal, shell, editor, multiplexer ────────────────────────────────────

sed --follow-symlinks -i "s|^include themes/.*\.conf|include themes/${THEME}.conf|" "$KITTY_CONF"
edit "$STARSHIP_CONF" && sed --follow-symlinks -i "s|^palette = '.*'|palette = '${THEME}'|" "$STARSHIP_CONF"
edit "$NVIM_INIT"     && sed --follow-symlinks -i "s|^local theme = '.*'|local theme = '${THEME}'|" "$NVIM_INIT"
edit "$ZELLIJ_CONF"   && sed --follow-symlinks -i "s|^theme \".*\"|theme \"${THEME}\"|" "$ZELLIJ_CONF"

# ── Compositor: niri focus ring ─────────────────────────────────────────────

if edit "$NIRI_CONF"; then
    sed --follow-symlinks -i \
        -e "s|^\( *active-gradient \)from=\"#[0-9a-fA-F]*\" to=\"#[0-9a-fA-F]*\"|\1from=\"#${ACCENT}\" to=\"#${ACCENT2}\"|" \
        -e "s|^\( *inactive-color \)\"#[0-9a-fA-F]*\"|\1\"#${SURFACE}\"|" \
        "$NIRI_CONF"
fi

# ── Panel + notification centre: repoint the shared GTK palette ─────────────

for app in waybar swaync; do
    if [[ -d "$HOME/.config/$app" ]]; then
        ln -sfn "$GTK_PALETTE" "$HOME/.config/$app/theme.css"
    fi
done

# ── Launcher: rewrite the marked [colors] block ─────────────────────────────

if edit "$FUZZEL_CONF"; then
    python3 - "$FUZZEL_CONF" <<EOF
import re, sys
path = sys.argv[1]
block = """background=${BG}ff
text=${FG}ff
prompt=${FG_DIM}ff
placeholder=${FG_DIM}ff
input=${FG}ff
match=${ACCENT}ff
selection=${SURFACE}ff
selection-text=${FG}ff
selection-match=${ACCENT}ff
counter=${FG_DIM}ff
border=${SURFACE}ff"""
src = open(path).read()
new, n = re.subn(
    r"(# THEME:START.*?\n).*?(\n# THEME:END)",
    lambda m: m.group(1) + block + m.group(2),
    src, flags=re.S)
if n != 1:
    sys.exit("fuzzel.ini: expected exactly one THEME:START/END block, found %d" % n)
open(path, "w").write(new)
EOF
fi

# ── Toolkit: GTK and Qt ─────────────────────────────────────────────────────
# All three themes are dark. Without this, GTK file dialogs and Qt apps stay
# light and break the illusion immediately.

if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    if [[ -d /usr/share/themes/adw-gtk3-dark || -d "$HOME/.themes/adw-gtk3-dark" ]]; then
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    else
        gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
    fi
    gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
    gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface font-name 'Inter 11'
    gsettings set org.gnome.desktop.interface document-font-name 'Inter 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'Iosevka Nerd Font Mono 11'
fi

# ── Persist + wallpaper ─────────────────────────────────────────────────────

echo "$THEME" > "$HOME/.config/current-theme"
[[ -x "$HOME/.local/bin/set-wallpaper" ]] && "$HOME/.local/bin/set-wallpaper" || true

# ── Live reload ─────────────────────────────────────────────────────────────

pgrep -x waybar >/dev/null && pkill -SIGUSR2 waybar || true
pgrep -x swaync >/dev/null && swaync-client --reload-css >/dev/null 2>&1 || true
pgrep -x niri   >/dev/null && echo "  niri   — config reloaded automatically" || true

echo "Switched to theme: ${THEME}"
echo "  kitty    — reload with ctrl+shift+F5"
echo "  zellij   — requires session restart"
echo "  nvim     — restart or :source"
echo "  starship — takes effect in new shells"
echo "  waybar / swaync / fuzzel / niri — live"
