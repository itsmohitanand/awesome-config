#!/usr/bin/env bash
# Bind Ctrl+Space to `ulauncher-toggle` as a GNOME custom shortcut.
#
# Why this exists: under Wayland an app can't grab a global hotkey itself, so
# Ulauncher's own "hotkey" preference does nothing on GNOME/Wayland. The bind
# has to be a GNOME custom shortcut instead. That lives in dconf, not in a
# file, so it can't be symlinked like the rest of this repo — hence a script.
#
# Idempotent: reuses the existing Ulauncher slot if there is one, otherwise
# appends a new slot without clobbering your other custom shortcuts.

set -euo pipefail

BINDING="${1:-<Primary>space}"
COMMAND='ulauncher-toggle'
NAME='Ulauncher'

MEDIA_KEYS='org.gnome.settings-daemon.plugins.media-keys'
CUSTOM_SCHEMA="$MEDIA_KEYS.custom-keybinding"
CUSTOM_BASE='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings'

if ! command -v gsettings >/dev/null 2>&1; then
    echo "  skip (no gsettings — not a GNOME session): ulauncher hotkey" >&2
    exit 0
fi

# Existing custom-keybinding paths, one per line. An empty list reads back as
# the typed literal "@as []", so drop that prefix with sed before stripping
# punctuation — `tr -d` would eat the a/s out of the paths themselves.
mapfile -t paths < <(
    gsettings get "$MEDIA_KEYS" custom-keybindings \
        | sed 's/^@as //' | tr -d "[]' " | tr ',' '\n' | grep -v '^$' || true
)

# Reuse the slot that already runs ulauncher-toggle, if any.
target=''
for p in "${paths[@]:-}"; do
    [[ -n "$p" ]] || continue
    cmd="$(gsettings get "$CUSTOM_SCHEMA:$p" command 2>/dev/null | tr -d "'" || true)"
    if [[ "$cmd" == "$COMMAND" ]]; then
        target="$p"
        break
    fi
done

# Otherwise claim the first unused customN slot and append it to the list.
if [[ -z "$target" ]]; then
    for i in $(seq 0 50); do
        candidate="$CUSTOM_BASE/custom$i/"
        if [[ ! " ${paths[*]:-} " == *" $candidate "* ]]; then
            target="$candidate"
            break
        fi
    done
    paths+=("$target")

    list=''
    for p in "${paths[@]}"; do
        [[ -n "$p" ]] || continue
        list+="${list:+, }'$p'"
    done
    gsettings set "$MEDIA_KEYS" custom-keybindings "[$list]"
fi

gsettings set "$CUSTOM_SCHEMA:$target" name    "$NAME"
gsettings set "$CUSTOM_SCHEMA:$target" command "$COMMAND"
gsettings set "$CUSTOM_SCHEMA:$target" binding "$BINDING"

printf '  bind: %s -> %s (%s)\n' "$BINDING" "$COMMAND" "$target"
