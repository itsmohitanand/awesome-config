#!/usr/bin/env bash
# niri-keys — show EVERY niri keybind in a searchable fuzzel menu.
#
# niri's built-in overlay (show-hotkey-overlay) deliberately shows only a
# curated subset: a hardcoded list of ~17 "important" actions, plus binds
# carrying a hotkey-overlay-title, plus spawn binds whose modifier is Mod or
# Super. Our binds are Alt-based, so most of them never qualify.
#
# This parses the live config instead, so it is always complete and always
# current. Bound to Alt+Shift+Slash in niri/config.kdl.
#
# Selecting a line copies the key combo to the clipboard, which is handy when
# you want to paste it into notes.

set -euo pipefail

CONFIG="${NIRI_CONFIG:-$HOME/.config/niri/config.kdl}"
[[ -f "$CONFIG" ]] || { echo "niri-keys: no config at $CONFIG" >&2; exit 1; }

LIST="$(python3 - "$CONFIG" <<'PY'
import re, sys

src = open(sys.argv[1]).read()

# Isolate the binds { ... } block by brace depth, so window-rules and layout
# blocks that also contain braces can't leak in.
start = src.index("\nbinds {")
depth, i = 0, start + 1
while i < len(src):
    if src[i] == "{":
        depth += 1
    elif src[i] == "}":
        depth -= 1
        if depth == 0:
            break
    i += 1
block = src[start:i]

# Human labels for the actions worth renaming; anything else is derived from
# the action name itself.
PRETTY = {
    "focus-column-or-monitor-left":     "Focus left (crosses monitors)",
    "focus-column-or-monitor-right":    "Focus right (crosses monitors)",
    "focus-window-or-monitor-down":     "Focus down",
    "focus-window-or-monitor-up":       "Focus up",
    "move-column-left-or-to-monitor-left":   "Move window left (crosses monitors)",
    "move-column-right-or-to-monitor-right": "Move window right (crosses monitors)",
    "consume-or-expel-window-left":     "Pull window into column / push out",
    "consume-or-expel-window-right":    "Pull window into column / push out",
    "switch-preset-column-width":       "Cycle column width",
    "switch-preset-window-height":      "Cycle window height",
    "toggle-overview":                  "Overview",
    "toggle-window-floating":           "Toggle floating",
    "show-hotkey-overlay":              "This list",
    "power-off-monitors":               "Screens off",
}

rows = []
for line in block.splitlines():
    line = line.strip()
    if not line or line.startswith("//"):
        continue
    m = re.match(r'^([A-Za-z0-9+_]+)\s*(.*?)\{\s*(.*?)\s*;?\s*\}$', line)
    if not m:
        continue
    key, attrs, action = m.group(1), m.group(2), m.group(3).rstrip(";").strip()

    # A custom title in the config wins over anything derived.
    t = re.search(r'hotkey-overlay-title="([^"]*)"', attrs)
    if t and t.group(1):
        label = t.group(1)
    elif action.startswith("spawn"):
        args = re.findall(r'"([^"]*)"', action)
        # spawn "sh" "-c" "..." — show the payload, not the shell wrapper.
        if args[:2] == ["sh", "-c"] and len(args) > 2:
            label = args[2]
        else:
            label = " ".join(args)
        label = "Run: " + (label[:57] + "…" if len(label) > 58 else label)
    else:
        name = action.split()[0]
        label = PRETTY.get(name, name.replace("-", " ").capitalize())
        extra = action[len(name):].strip().strip('"')
        if extra:
            label += f" {extra}"

    rows.append((key, label))

# Group numeric workspace binds so 1-9 don't eat nine lines each.
seen_ws = set()
out = []
for key, label in rows:
    g = re.match(r'^(.*?)([1-9])$', key)
    if g and "workspace" in label.lower():
        stem = g.group(1)
        if stem in seen_ws:
            continue
        seen_ws.add(stem)
        key = f"{stem}1…9"
        label = re.sub(r'\s*\d+$', '', label) + " 1-9"
    out.append((key, label))

width = max(len(k) for k, _ in out) + 2
for key, label in out:
    print(f"{key:<{width}}  {label}")
PY
)"

if command -v fuzzel >/dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    choice="$(printf '%s\n' "$LIST" \
        | fuzzel --dmenu --prompt "keys  " --lines 24 --width 72 || true)"
    [[ -n "$choice" ]] && printf '%s' "${choice%% *}" | wl-copy || true
else
    printf '%s\n' "$LIST"
fi
