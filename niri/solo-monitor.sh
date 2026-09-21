#!/usr/bin/env bash
# niri-solo-monitor — toggle "only the focused monitor is on".
#
# For games: with a second screen live, the cursor slides off the game window
# onto it. First press turns off every output except the focused one; next
# press (any output off) turns them all back on. Works off whatever is plugged
# in, so the office three-panel desk needs no change.
#
# Bound to Alt+Ctrl+M in niri/config.kdl.

set -euo pipefail

outputs="$(niri msg --json outputs)"
# A disabled output reports current_mode null.
off="$(jq -r 'to_entries[] | select(.value.current_mode == null) | .key' <<<"$outputs")"

if [[ -n "$off" ]]; then
    while read -r name; do niri msg output "$name" on; done <<<"$off"
else
    focused="$(niri msg --json focused-output | jq -r .name)"
    jq -r 'keys[]' <<<"$outputs" | while read -r name; do
        [[ "$name" == "$focused" ]] || niri msg output "$name" off
    done
fi
