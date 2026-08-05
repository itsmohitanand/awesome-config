#!/usr/bin/env bash
# set-wallpaper — apply the wallpaper matching the current theme.
#
# Looks for ~/.config/wallpapers/<theme>.{png,jpg,jpeg} and falls back to
# ~/.config/wallpapers/default.*. Prefers swww (animated crossfade) and falls
# back to swaybg (instant, but packaged in Ubuntu).
#
# Tip: niri has no blur, so a busy wallpaper fights the panel. Pre-blur it once:
#   magick wallpaper.png -blur 0x24 -modulate 92 ~/.config/wallpapers/<theme>.png

set -euo pipefail

THEME="$(cat "$HOME/.config/current-theme" 2>/dev/null || echo default)"
DIR="$HOME/.config/wallpapers"

WALL=""
for name in "$THEME" default; do
    for ext in png jpg jpeg; do
        if [[ -f "$DIR/$name.$ext" ]]; then
            WALL="$DIR/$name.$ext"
            break 2
        fi
    done
done

if [[ -z "$WALL" ]]; then
    echo "set-wallpaper: no image found in $DIR (looked for $THEME.* and default.*)" >&2
    exit 0
fi

if command -v swww >/dev/null; then
    swww query >/dev/null 2>&1 || swww-daemon &
    sleep 0.2
    swww img "$WALL" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-duration 1.2 \
        --transition-fps 60
elif command -v swaybg >/dev/null; then
    pkill -x swaybg || true
    swaybg -i "$WALL" -m fill &
else
    echo "set-wallpaper: neither swww nor swaybg installed" >&2
    exit 0
fi
