#!/usr/bin/env bash
# lock-session — lock the screen, themed to match the active theme.
#
# Prefers hyprlock (nicer, but not always installable on Ubuntu) and falls back
# to swaylock, which install-deps.sh always installs. Bound to Mod+Escape in
# niri/config.kdl and used by swayidle for idle/suspend locking.

set -euo pipefail

# Never stack two lockers on top of each other (swayidle + manual keypress).
pgrep -x hyprlock >/dev/null && exit 0
pgrep -x swaylock >/dev/null && exit 0

THEME="$(cat "$HOME/.config/current-theme" 2>/dev/null || echo everblush)"

case "$THEME" in
poimandres) BG=1B1E28; INSIDE=171922; RING=5DE4C7; RING2=ADD7FF; TEXT=A6ACCD; WRONG=D0679D ;;
cyberdream) BG=16181a; INSIDE=1e2124; RING=ffbd5e; RING2=5ea1ff; TEXT=ffffff; WRONG=ff6e5e ;;
*)          BG=141b1e; INSIDE=232a2d; RING=6cbfbf; RING2=67b0e8; TEXT=dadada; WRONG=e57474 ;;
esac

if command -v hyprlock >/dev/null; then
    exec hyprlock
fi

exec swaylock \
    --daemonize \
    --ignore-empty-password \
    --show-failed-attempts \
    --indicator-radius 90 \
    --indicator-thickness 6 \
    --color "$BG" \
    --inside-color "$INSIDE" \
    --inside-clear-color "$INSIDE" \
    --inside-ver-color "$INSIDE" \
    --inside-wrong-color "$INSIDE" \
    --ring-color "$RING" \
    --ring-clear-color "$RING2" \
    --ring-ver-color "$RING2" \
    --ring-wrong-color "$WRONG" \
    --key-hl-color "$RING2" \
    --bs-hl-color "$WRONG" \
    --text-color "$TEXT" \
    --text-clear-color "$TEXT" \
    --text-ver-color "$TEXT" \
    --text-wrong-color "$WRONG" \
    --separator-color 00000000 \
    --line-color 00000000 \
    --line-clear-color 00000000 \
    --line-ver-color 00000000 \
    --line-wrong-color 00000000
