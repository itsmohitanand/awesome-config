# niri — first run

State of the niri setup on this machine, what's verified, and what to do next.
Written 2026-08-11 on Ubuntu 24.04, RTX 5090 + AMD iGPU, three 2560x1440 panels.

## Getting into the session

`Niri` appears in GDM's session list. **GDM remembers the last session and reuses
it silently**, so typing your password straight away logs you back into whatever
you used before — this is the usual reason "I picked niri but I'm still in GNOME".

1. Click your username at the login screen.
2. Click the **gear / cog icon at the bottom-right** — *before* typing anything.
3. Pick **Niri**.
4. Then type your password and log in.

Sessions installed here:

| Name | Type |
| ---- | ---- |
| Niri | Wayland |
| Ubuntu | Wayland |
| Ubuntu on Wayland | Wayland |
| Ubuntu | Xorg |
| Ubuntu on Xorg | Xorg |

GNOME stays installed and selectable, so this is reversible at every step.
`Alt+Shift+E` quits niri back to GDM.

## Survival keybinds

Every bind is **Alt**-based — Super sits on a home-row mod on the ZSA Voyager and
is awkward to hold. `Alt+Shift+Slash` lists all 75 of them, searchable, which is
the only one worth memorising.

| Key | Action |
| --- | ------ |
| `Alt+Return` | terminal (kitty) |
| `Alt+Space` | launcher (noctalia) |
| `Alt+Shift+Slash` | all keybinds, searchable |
| `Alt+H` / `Alt+L` | focus left / right, crosses monitors |
| `Alt+J` / `Alt+K` | focus down / up |
| `Alt+Shift+H` / `Alt+Shift+L` | move window left / right |
| `Alt+1`…`Alt+9` | workspace 1-9 |
| `Alt+R` | cycle column width (1/3, 1/2, 2/3) |
| `Alt+M` / `Alt+Shift+F` | maximise column / fullscreen window |
| `Alt+O` | overview |
| `Alt+W` | toggle floating |
| `Alt+Q` | close window |
| `Alt+Tab` | window switcher (noctalia) |
| `Alt+A` | caffeine — inhibit the 10-minute idle lock |
| `Alt+Shift+Q` | session menu (lock/suspend/logout/reboot) |
| `Alt+Escape` | lock (noctalia's lock screen, PAM) |
| `Alt+Shift+E` | **quit niri** |
| `Print` / `Alt+Print` / `Ctrl+Print` | screenshot region / window / screen |

Cost of the Alt scheme: the compositor swallows Alt+key before the terminal sees
it, so some readline word-operations are gone. Binds were chosen to avoid the
ones worth keeping — hence `Alt+Shift+B` for browser rather than `Alt+B`.

## First thing after logging in

The three output blocks in `config.kdl` are **commented out** because the DRM
names have to be confirmed from inside a niri session:

```bash
niri msg outputs
```

Then uncomment the block in `~/.config/niri/config.kdl` (a symlink into this
repo) and fill in the real values. **niri hot-reloads on save** — no restart. Keep
a terminal open while editing: an invalid config is rejected and the previous one
stays live, so you can't lock yourself out.

Two traps:

- X11's `HDMI-0` is a different name on the DRM side, usually `HDMI-A-1`.
- All three panels do **74.98 Hz** but advertise 59.95 as "preferred". Pin the
  higher one or you silently run at the lower rate.

`niri validate` checks the file before you trust it.

## Verify these, in order

1. **The noctalia bar** appears at the top. If it's missing, run
   `noctalia --daemon` in a terminal to see why — it logs to stderr and to
   `~/.cache/noctalia/`. Note `waybar.service` is deliberately masked; Ubuntu
   ships it globally enabled and it would start a second bar over noctalia's.
2. **Wallpaper** crossfades in. `switch-theme cyberdream` tests a live swap
   across noctalia, niri, kitty, GTK/Qt and the wallpaper in one go.
3. **`Alt+N`** opens the control centre on its notifications tab, `Alt+V` the
   clipboard, `Alt+Space` the launcher. All three are noctalia panels driven over
   its IPC socket, so if one does nothing, the daemon isn't running.
4. **DBeaver** launches. This is the XWayland test — see "known unknown" below.
   Thunderbird is native Wayland (`MOZ_ENABLE_WAYLAND=1` is set) and should be
   fine.
5. **Volume / brightness keys** — they shell out to `wpctl` and `brightnessctl`.

## Known unknown

~~Whether niri expands `~` in the `xwayland-satellite` path.~~ Resolved: it does.
`src/utils/xwayland/satellite.rs` calls `expand_home()` on that path in both the
spawn and the on-demand-test path, so the tilde is safe.

What's actually unverified now is **noctalia**, which is beta and was swapped in
for waybar + swaync + fuzzel + swayidle + swaylock + swww all at once. If the
session comes up bare, everything in this repo except the bar still works — niri
itself is unaffected — and `waybar`/`fuzzel` are still installable from apt as a
fallback.

## What's verified

- `niri validate` passes, both on the repo file and the symlinked config.
- niri **starts**: ran nested for 15s with a minimal config, no errors. So a
  failure to reach the session is a GDM selection problem, not a niri one.
- `bash -n` clean on every shell script; `jq` parses both ulauncher configs; both
  wallpaper scripts compile.
- `niri-keys` parses the live config and renders all 75 binds, through
  `noctalia dmenu` now that fuzzel is gone.
- `xwayland-satellite` present at the config path.
- Post-install symlinks: noctalia's `config.toml` and `palettes/`, three
  wallpapers, and the `~/.local/bin` scripts resolve and are executable.

## Build gotchas already fixed in `install-deps.sh`

Packages missing from the original list, each fatal rather than degrading:

| Package | Without it |
| ------- | ---------- |
| `libclang-dev` | `xwayland-satellite` fails — bindgen finds only versioned `libclang-NN.so.1`, not the `libclang.so` it searches for |
| `libstb-dev` | noctalia's meson configure fails — it needs `stb/stb_image_resize2.h` specifically; older stb packages ship only `stb_image_resize` |
| `libwireplumber-0.5-dev` | noctalia's meson configure fails — 0.4 is explicitly not enough |

noctalia needs **GCC 13+** for C++23. Ubuntu 24.04 ships 13 and 26.04 ships 15,
so both desks build as-is; Debian 12 would need `CXX=g++-13`.

## GPU note

Two GPUs: RTX 5090 at `01:00.0`, AMD iGPU at `74:00.0`. Do **not** identify them
by `renderD` number — on this box the iGPU enumerates *first* (`renderD128` =
iGPU, `renderD129` = NVIDIA), the reverse of what you'd assume — and the reverse
of the home box, which has a 5070 Ti at the same `01:00.0`, its iGPU at
`73:00.0`, and `renderD128` = NVIDIA. Same slot, opposite numbering: that's the
whole argument. `config.kdl` pins the render device by PCI path, which is stable,
so niri can't fall back to the iGPU and render slowly or come up dark.
