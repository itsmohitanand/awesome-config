#!/usr/bin/env bash
# switch-theme <name>
# Switches every themed surface in one command:
#   shell      — noctalia (bar, launcher, notifications, lock, OSD)
#   terminal   — kitty          via noctalia template
#   prompt     — starship       here, template would clobber the tracked config
#   compositor — niri           via noctalia template
#   toolkit    — GTK / Qt       via noctalia template + gsettings
#   editor     — neovim         here, no upstream template
#   multiplex  — zellij         here, no upstream template
#   desktop    — wallpaper      via noctalia IPC
#
# Available themes: poimandres | cyberdream | everblush
#
# Most of this script used to be sed and inline Python rewriting each config in
# place. noctalia owns the palette now: one IPC call switches its custom palette,
# and its template engine regenerates kitty/niri/GTK/Qt from that palette.
# What's left here is the three surfaces it can't own, plus the desktop-wide
# toolkit settings that aren't palette-driven.
#
# The palettes themselves live in noctalia/palettes/<name>.json, generated from
# kitty/themes/<name>.conf by noctalia/make-palette.py.

set -euo pipefail

THEME="${1:?Usage: switch-theme <poimandres|cyberdream|everblush>}"

DOTFILES="$(cd "$(dirname "$(realpath "$0")")" && pwd)"

STARSHIP_CONF="$HOME/.config/starship.toml"
NVIM_INIT="$HOME/.config/nvim/init.lua"
ZELLIJ_CONF="$HOME/.config/zellij/config.kdl"
NOCTALIA="$HOME/.local/bin/noctalia"
WALLPAPER="$HOME/.config/wallpapers/${THEME}.png"

case "$THEME" in
poimandres | cyberdream | everblush) ;;
*)
    echo "Error: unknown theme '$THEME' (want poimandres, cyberdream or everblush)" >&2
    exit 1
    ;;
esac

if [[ ! -f "$DOTFILES/noctalia/palettes/${THEME}.json" ]]; then
    echo "Error: no noctalia palette for '$THEME'." >&2
    echo "       Generate it with ./noctalia/make-palette.py $THEME" >&2
    exit 1
fi

# Only touch a surface if it's actually installed. Lets this script stay useful
# on a machine that has nvim but not the full niri desktop.
edit() { [[ -f "$1" ]]; }

# ── Prompt, editor and multiplexer ──────────────────────────────────────────
# nvim and zellij have no noctalia template. starship has one, but it rewrites
# ~/.config/starship.toml — a symlink into this repo — replacing the tracked
# palette line with a generated block on every switch. starship.toml already
# carries all three palettes, so flipping one line is both cleaner and cheaper.
# --follow-symlinks matters: without it sed replaces the symlink with a regular
# file and the config silently detaches from this repo.

edit "$STARSHIP_CONF" && sed --follow-symlinks -i "s|^palette = '.*'|palette = '${THEME}'|" "$STARSHIP_CONF"
edit "$NVIM_INIT"   && sed --follow-symlinks -i "s|^local theme = '.*'|local theme = '${THEME}'|" "$NVIM_INIT"
edit "$ZELLIJ_CONF" && sed --follow-symlinks -i "s|^theme \".*\"|theme \"${THEME}\"|" "$ZELLIJ_CONF"

# ── Everything noctalia owns ────────────────────────────────────────────────
# One call. noctalia writes the selection to ~/.local/state/noctalia/settings.toml
# (not to noctalia/config.toml, which stays repo-clean), repaints its own shell,
# then runs every enabled template: kitty, niri, gtk3/4, qt, btop.
#
# This is IPC, so it needs the daemon running — i.e. a live niri session. From a
# TTY or the GNOME fallback session there's nothing to talk to; the theme then
# applies at the next login from config.toml's [theme] default.

if [[ -x "$NOCTALIA" ]] && "$NOCTALIA" msg color-scheme-set custom "$THEME" >/dev/null 2>&1; then
    noctalia_ok=1
else
    noctalia_ok=0
    echo "  warning: noctalia not running — kitty/niri/GTK keep the old palette" >&2
    echo "           re-run this inside a niri session, or log in again" >&2
fi

# ── Wallpaper ───────────────────────────────────────────────────────────────
# noctalia has no hook tying the wallpaper to the palette, so pair them here.

if [[ "$noctalia_ok" == 1 && -f "$WALLPAPER" ]]; then
    "$NOCTALIA" msg wallpaper-set "$WALLPAPER" >/dev/null 2>&1 || true
fi

# ── Toolkit: GTK and Qt ─────────────────────────────────────────────────────
# noctalia's gtk3/gtk4/qt templates write the colour palette, but the theme,
# icon, cursor and font choices below aren't palette-driven and gsettings is
# still the only thing that sets them. All three themes are dark; without this,
# GTK file dialogs and Qt apps stay light and break the illusion immediately.

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

# ── Persist ─────────────────────────────────────────────────────────────────
# Kept for anything that reads the current theme name; noctalia tracks its own
# selection separately in settings.toml.

echo "$THEME" > "$HOME/.config/current-theme"

echo "Switched to theme: ${THEME}"
echo "  zellij   — requires session restart"
echo "  nvim     — restart or :source"
echo "  starship — takes effect in new shells"
if [[ "$noctalia_ok" == 1 ]]; then
    echo "  kitty    — live (noctalia signals running instances)"
    echo "  noctalia / niri / GTK / Qt — live"
fi
