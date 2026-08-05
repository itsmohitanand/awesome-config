#!/usr/bin/env python3
"""Generate a wallpaper matched to a theme's palette.

    ./niri/make-wallpaper.py everblush [outfile]

niri has no layer-shell blur, so the wallpaper sits directly behind an opaque
waybar. A photograph fights that seam; a dark tonal gradient hides it. The
design rules encoded here:

  - darkest region at the top, so waybar melts into the background
  - two soft off-centre glows in the theme's accent colours, well below the bar
  - a faint vignette to keep focus central
  - film grain, because smooth gradients band badly on 8-bit panels

Rendered small and upscaled with LANCZOS: gradients survive that perfectly and
it avoids a per-pixel loop over 8.3 million pixels.
"""

import sys
from PIL import Image, ImageFilter
import random
import math

# bg, accent, accent2 — kept in sync with themes/<name>.css
PALETTES = {
    "everblush":  ("#141b1e", "#6cbfbf", "#67b0e8"),
    "poimandres": ("#1B1E28", "#5DE4C7", "#ADD7FF"),
    "cyberdream": ("#16181a", "#ffbd5e", "#5ea1ff"),
}

W, H = 480, 270           # render size; upscaled 8x at the end
OUT_W, OUT_H = 3840, 2160


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def build(theme):
    bg, accent, accent2 = (hex_rgb(c) for c in PALETTES[theme])

    img = Image.new("RGB", (W, H))
    px = img.load()

    # Glow sources. Pushed low and made very large so they overlap into a
    # single ambient wash rather than reading as separate circles — the giveaway
    # of a generated gradient is a visible falloff edge.
    # (x, y, radius, colour, strength) in normalised coordinates.
    glows = [
        (0.18, 1.16, 1.15, accent,  0.50),
        (0.82, 1.05, 0.95, accent2, 0.30),
        (0.50, 1.30, 1.40, accent,  0.22),
    ]

    for y in range(H):
        ny = y / H
        for x in range(W):
            nx = x / W
            r, g, b = bg

            for gx, gy, rad, col, strength in glows:
                # Aspect-corrected distance so glows stay circular on 16:9.
                dx = (nx - gx) * (W / H)
                dy = ny - gy
                d = math.hypot(dx, dy) / rad
                if d < 1.0:
                    # smoothstep falloff — no hard edge
                    f = (1.0 - d * d)
                    f = f * f * strength
                    r += (col[0] - bg[0]) * f
                    g += (col[1] - bg[1]) * f
                    b += (col[2] - bg[2]) * f

            # Vertical falloff: hold the top third near-black so waybar has a
            # clean, uniform field to sit on, then ease into the glow below.
            v = 1.0 - 0.34 * max(0.0, (0.55 - ny) / 0.55) ** 0.8
            px[x, y] = (
                max(0, min(255, int(r * v))),
                max(0, min(255, int(g * v))),
                max(0, min(255, int(b * v))),
            )

    img = img.filter(ImageFilter.GaussianBlur(2))
    img = img.resize((OUT_W, OUT_H), Image.LANCZOS)

    # Grain: essential at this size, 8-bit gradients band visibly without it.
    grain = Image.new("L", (OUT_W // 2, OUT_H // 2))
    gpx = grain.load()
    rnd = random.Random(7)
    for y in range(grain.height):
        for x in range(grain.width):
            gpx[x, y] = 128 + rnd.randint(-5, 5)
    grain = grain.resize((OUT_W, OUT_H), Image.BILINEAR).convert("RGB")

    return Image.blend(img, Image.blend(img, grain, 0.5), 0.06)


if __name__ == "__main__":
    theme = sys.argv[1] if len(sys.argv) > 1 else "everblush"
    if theme not in PALETTES:
        sys.exit(f"unknown theme {theme!r}; want one of {', '.join(PALETTES)}")
    out = sys.argv[2] if len(sys.argv) > 2 else f"{theme}.png"
    build(theme).save(out, optimize=True)
    print(f"wrote {out}")
