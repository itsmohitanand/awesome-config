#!/usr/bin/env python3
"""Wallpaper from a chaotic dynamical system, themed to the palette.

    ./niri/make-wallpaper-chaos.py everblush [outfile] [--system clifford]

Renders the invariant measure of a 2-D chaotic map: iterate the map tens of
millions of times and histogram where the orbit spends its time. The strange
attractor emerges as a density field — which is the honest picture of a chaotic
system, since individual trajectories are unpredictable but the distribution
over them is stable. That is also the thing that makes it a good wallpaper:
structure everywhere, detail at every scale, no focal point competing with
your windows.

Systems:
  clifford  x' = sin(a y) + c cos(a x),  y' = sin(b x) + d cos(b y)
  dejong    x' = sin(a y) - cos(b x),    y' = sin(c x) - cos(d y)
  ikeda     optical ring cavity; tighter spiral, more negative space

Density is log-compressed (orbits concentrate hard on the attractor, so linear
scaling shows a white core and nothing else) and mapped through a ramp built
from the theme's own colours.
"""

import argparse
import sys

import numpy as np
from PIL import Image, ImageFilter

# bg, accent, accent2 — kept in sync with themes/<name>.css
PALETTES = {
    "everblush":  ("#141b1e", "#6cbfbf", "#67b0e8"),
    "poimandres": ("#1B1E28", "#5DE4C7", "#ADD7FF"),
    "cyberdream": ("#16181a", "#ffbd5e", "#5ea1ff"),
}

SYSTEMS = {
    # Parameters chosen for a wide, screen-filling attractor rather than a
    # tight knot — a 16:9 canvas wants something that spreads horizontally.
    "clifford": dict(a=-1.4, b=1.6, c=1.0, d=0.7),
    "dejong":   dict(a=-2.7, b=-0.09, c=-0.86, d=-2.2),
    "ikeda":    dict(u=0.918),
}

OUT_W, OUT_H = 3840, 2160


def hex_rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=float)


def step(system, cx, cy):
    """One step of the map, applied elementwise to a whole ensemble."""
    p = SYSTEMS[system]
    if system == "clifford":
        a, b, c, d = p["a"], p["b"], p["c"], p["d"]
        return (np.sin(a * cy) + c * np.cos(a * cx),
                np.sin(b * cx) + d * np.cos(b * cy))
    if system == "dejong":
        a, b, c, d = p["a"], p["b"], p["c"], p["d"]
        return (np.sin(a * cy) - np.cos(b * cx),
                np.sin(c * cx) - np.cos(d * cy))
    if system == "ikeda":
        u = p["u"]
        t = 0.4 - 6.0 / (1.0 + cx * cx + cy * cy)
        return (1.0 + u * (cx * np.cos(t) - cy * np.sin(t)),
                u * (cx * np.sin(t) + cy * np.cos(t)))
    sys.exit(f"unknown system {system!r}")


def ensemble(system, n_orbits=200_000, seed=1):
    """Seed an ensemble of orbits and burn off the transient.

    A single orbit has to be iterated sequentially, which in Python costs
    microseconds per point and caps you at a few hundred thousand points a
    second. But the attractor is the invariant measure of the *whole* basin,
    so running many independent orbits in parallel samples exactly the same
    distribution — and vectorises across the ensemble, which is ~100x faster.

    Fittingly, that is also how you'd actually forecast a chaotic system:
    propagate an ensemble, not a point estimate.
    """
    rng = np.random.default_rng(seed)
    cx = rng.uniform(-1.0, 1.0, n_orbits)
    cy = rng.uniform(-1.0, 1.0, n_orbits)
    for _ in range(200):          # burn-in onto the attractor
        cx, cy = step(system, cx, cy)
    return cx, cy


def frame(system, cx, cy, w, h, zoom, offset, probe_steps=60):
    """Work out the histogram window from a short probe run."""
    xs, ys = [], []
    px, py = cx.copy(), cy.copy()
    for _ in range(probe_steps):
        px, py = step(system, px, py)
        xs.append(px[::37])       # thin the sample; we only need percentiles
        ys.append(py[::37])
    x = np.concatenate(xs)
    y = np.concatenate(ys)

    lo_x, hi_x = np.percentile(x, [0.05, 99.95])
    lo_y, hi_y = np.percentile(y, [0.05, 99.95])

    # Match the window's aspect to the canvas so the attractor isn't stretched.
    mx, my = (lo_x + hi_x) / 2, (lo_y + hi_y) / 2
    span_y = (hi_y - lo_y) * zoom
    span_x = span_y * (w / h)
    if span_x < (hi_x - lo_x) * zoom:
        span_x = (hi_x - lo_x) * zoom
        span_y = span_x * (h / w)

    mx -= offset[0] * span_x
    my -= offset[1] * span_y
    return (my - span_y / 2, my + span_y / 2,
            mx - span_x / 2, mx + span_x / 2)


def density(system, cx, cy, w, h, total_points, window):
    """Accumulate the orbit density into a fixed w*h histogram.

    Binned incrementally: at supersampled 4K the point count needed runs into
    the hundreds of millions, and materialising those coordinates would cost
    several GB.
    """
    y0, y1, x0, x1 = window
    hist = np.zeros((h, w), dtype=np.float32)

    n_orbits = cx.size
    steps = max(1, total_points // n_orbits)
    for i in range(steps):
        cx, cy = step(system, cx, cy)
        # np.histogram2d reallocates every call; bincount on precomputed bin
        # indices is markedly faster in a hot loop.
        iy = ((cy - y0) / (y1 - y0) * h).astype(np.int32)
        ix = ((cx - x0) / (x1 - x0) * w).astype(np.int32)
        ok = (iy >= 0) & (iy < h) & (ix >= 0) & (ix < w)
        flat = iy[ok].astype(np.int64) * w + ix[ok]
        hist += np.bincount(flat, minlength=w * h).reshape(h, w)
        if i % 200 == 0:
            print(f"  {i * n_orbits / 1e6:.0f}M / {total_points / 1e6:.0f}M",
                  end="\r", flush=True)
    print(" " * 40, end="\r")
    return hist


def colourise(hist, theme):
    bg, accent, accent2 = (hex_rgb(c) for c in PALETTES[theme])

    # Log compression: orbit density spans several orders of magnitude, so a
    # linear map shows a saturated core and empty space around it.
    d = np.log1p(hist)
    if (d > 0).any():
        d /= np.percentile(d[d > 0], 99.9)
    d = np.clip(d, 0, 1)
    # Gamma > 1 pushes the midtones down so only the genuinely dense filaments
    # light up. A lift (<1) fills the attractor into a bright solid mass, which
    # looks striking in isolation and terrible behind windows.
    d = d ** 1.55

    # Ramp: background dominates the low end, so most of the frame stays quiet.
    # Highlight is deliberately not white — blown highlights read as cheap
    # against a dark desktop, and they compete with window content.
    highlight = np.clip(accent2 * 0.72 + 255 * 0.28, 0, 255)
    stops = [(0.0, bg), (0.30, bg * 0.55 + accent * 0.45),
             (0.62, accent), (0.86, accent2), (1.0, highlight)]

    img = np.empty(d.shape + (3,), dtype=float)
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        m = (d >= t0) & (d <= t1)
        f = ((d[m] - t0) / (t1 - t0))[:, None]
        img[m] = c0 * (1 - f) + c1 * f

    return img


def apply_vignette(img):
    """Hold the top strip dark so waybar sits on a clean field."""
    h = img.shape[0]
    ny = np.linspace(0, 1, h)[:, None, None]
    v = 1.0 - 0.55 * np.clip((0.13 - ny) / 0.13, 0, 1) ** 0.7
    return img * v


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("theme", nargs="?", default="everblush", choices=list(PALETTES))
    ap.add_argument("outfile", nargs="?")
    ap.add_argument("--system", default="clifford", choices=list(SYSTEMS))
    ap.add_argument("--points", type=int, default=400_000_000)
    ap.add_argument("--zoom", type=float, default=1.12,
                    help="<1 crops into the attractor, >1 leaves margin")
    ap.add_argument("--offset", type=float, default=0.0,
                    help="shift right by this fraction of the frame")
    ap.add_argument("--supersample", type=int, default=2,
                    help="render at Nx then downscale; 1 disables")
    args = ap.parse_args()

    out = args.outfile or f"{args.theme}-{args.system}.png"

    # Render above native and downscale — this is what actually antialiases the
    # filaments. Binning *below* native and scaling up (as this script did
    # originally) throws away the fine structure and looks soft at 4K.
    ss = max(1, args.supersample)
    w, h = OUT_W * ss, OUT_H * ss

    print(f"{args.system}: {args.points:,} points into {w}x{h}", flush=True)
    cx, cy = ensemble(args.system)
    window = frame(args.system, cx, cy, w, h, args.zoom, (args.offset, 0.0))
    hist = density(args.system, cx, cy, w, h, args.points, window)

    print("colourising…", flush=True)
    img = apply_vignette(colourise(hist, args.theme))

    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    if ss > 1:
        im = im.resize((OUT_W, OUT_H), Image.LANCZOS)
    im.save(out, optimize=True)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
