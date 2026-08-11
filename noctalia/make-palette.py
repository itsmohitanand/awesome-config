#!/usr/bin/env python3
"""make-palette.py — derive noctalia palettes from the kitty theme files.

    ./noctalia/make-palette.py              # regenerate all three
    ./noctalia/make-palette.py everblush    # just one

Noctalia reads custom palettes from ~/.config/noctalia/palettes/<name>.json
(install.sh symlinks noctalia/palettes/ there) and switches with

    noctalia theme --custom <name>

kitty/themes/<name>.conf stays the single source of truth for the ANSI 16 and
the fg/bg/cursor/selection quartet, because kitty is the one surface where those
are all named explicitly. Only the four values kitty has no slot for live in
ACCENTS below.

Material 3 wants role names rather than "accent 1/2", so the mapping is:

    primary          ACCENT      the focus ring, active bar widgets
    secondary        ACCENT2     the other half of the old niri gradient
    tertiary         color5      third accent, used for sparse highlights
    error            color1      urgent windows, failed states
    surface          background  panel and popup ground
    surfaceVariant   selection_background   cards inside a panel
    outline          FG_DIM      borders, dividers
    hover            BG_ALT      the lift under a hovered widget

on<Role> is the text drawn on top of that role. Every dark theme here puts the
background under its accents, so on{Primary,Secondary,Tertiary,Error} are all
the background; onSurface/onHover are the foreground; onSurfaceVariant is dimmed
because it sits on a lighter card and would otherwise glare.
"""

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
KITTY = REPO / "kitty" / "themes"
OUT = Path(__file__).resolve().parent / "palettes"

# The four values kitty's format has nowhere to put. Keep in sync with the
# palette table in switch-theme.sh — that table is what themes/<name>.css and
# the niri focus ring were built from.
ACCENTS = {
    "poimandres": {"accent": "#5DE4C7", "accent2": "#ADD7FF",
                   "dim": "#767C9D", "bg_alt": "#171922"},
    "cyberdream": {"accent": "#ffbd5e", "accent2": "#5ea1ff",
                   "dim": "#7b8496", "bg_alt": "#1e2124"},
    "everblush":  {"accent": "#6cbfbf", "accent2": "#67b0e8",
                   "dim": "#8a9291", "bg_alt": "#232a2d"},
}

ANSI = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]


def read_kitty(theme):
    """Pull the colour keys out of a kitty conf. Ignores everything else."""
    conf = {}
    for line in (KITTY / f"{theme}.conf").read_text().splitlines():
        m = re.match(r"^(\w+)\s+(#[0-9a-fA-F]{6})\s*$", line)
        if m:
            conf[m.group(1)] = m.group(2)
    return conf


def palette(theme):
    k = read_kitty(theme)
    a = ACCENTS[theme]
    bg, fg = k["background"], k["foreground"]

    return {
        "dark": {
            "primary": a["accent"],           "onPrimary": bg,
            "secondary": a["accent2"],        "onSecondary": bg,
            "tertiary": k["color5"],          "onTertiary": bg,
            "error": k["color1"],             "onError": bg,
            "surface": bg,                    "onSurface": fg,
            "surfaceVariant": k["selection_background"],
            "onSurfaceVariant": a["dim"],
            "outline": a["dim"],
            "shadow": "#000000",
            "hover": a["bg_alt"],             "onHover": fg,
            "terminal": {
                "normal": {n: k[f"color{i}"] for i, n in enumerate(ANSI)},
                "bright": {n: k[f"color{i + 8}"] for i, n in enumerate(ANSI)},
                "foreground": fg,
                "background": bg,
                "cursor": k["cursor"],
                "cursorText": k["cursor_text_color"],
                "selectionFg": k["selection_foreground"],
                "selectionBg": k["selection_background"],
            },
        }
    }


def main():
    themes = sys.argv[1:] or sorted(ACCENTS)
    unknown = [t for t in themes if t not in ACCENTS]
    if unknown:
        sys.exit(f"unknown theme(s): {', '.join(unknown)}")

    OUT.mkdir(exist_ok=True)
    for theme in themes:
        path = OUT / f"{theme}.json"
        path.write_text(json.dumps(palette(theme), indent=2) + "\n")
        print(f"wrote {path.relative_to(REPO)}")


if __name__ == "__main__":
    main()
