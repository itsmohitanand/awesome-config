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
is awkward to hold. `Alt+Shift+Slash` lists all 69 of them, searchable, which is
the only one worth memorising.

| Key | Action |
| --- | ------ |
| `Alt+Return` | terminal (kitty) |
| `Alt+Space` | launcher (fuzzel) |
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
| `Alt+Escape` | lock (swaylock — hyprlock isn't packaged on 24.04) |
| `Alt+Shift+E` | **quit niri** |
| `Print` / `Alt+Print` / `Ctrl+Print` | screenshot region / window / screen |
| `Alt+S` / `Alt+Shift+S` / `Alt+Ctrl+S` | same, for keyboards with no Print key |

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

1. **waybar** appears at the top. This is the one config that could not be
   validated offline — waybar exits with "Bar need to run under Wayland" before
   parsing its JSONC. If the bar is missing, run `waybar` in a terminal to see
   the parse error. Note `waybar.service` is deliberately masked so systemd
   doesn't start a second bar on top of the one niri spawns.
2. **Wallpaper** crossfades in via `swww`. `switch-theme cyberdream` tests a live
   theme swap across niri, waybar, swaync, fuzzel, GTK/Qt and wallpaper.
3. **`Alt+N`** opens swaync.
4. **DBeaver** launches. This is the XWayland test — see "known unknown" below.
   Thunderbird is native Wayland (`MOZ_ENABLE_WAYLAND=1` is set) and should be
   fine.
5. **Volume / brightness keys** — they shell out to `wpctl` and `brightnessctl`.

## Known unknown

`config.kdl` points `xwayland-satellite` at `~/.cargo/bin/xwayland-satellite`
rather than a hardcoded `/home/<user>/...`. The config **validates** and the
binary **is** at that path, but whether niri expands `~` at spawn time is
untested. If X11 apps (DBeaver, Slack, Discord) fail to launch, that line is the
first suspect — replace the tilde with the literal path to confirm.

## What's verified

- `niri validate` passes, both on the repo file and the symlinked config.
- niri **starts**: ran nested for 15s with a minimal config, no errors. So a
  failure to reach the session is a GDM selection problem, not a niri one.
- `bash -n` clean on all eight shell scripts; `jq` parses swaync + both ulauncher
  configs; both wallpaper scripts compile.
- `niri-keys` parses the live config and renders all 69 binds.
- `swww` + `swww-daemon` 0.11.2, `xwayland-satellite` present at the config path.
- Post-install symlinks: `theme.css` (waybar + swaync), three wallpapers, and all
  four `~/.local/bin` scripts resolve and are executable.

## Build gotchas already fixed in `install-deps.sh`

Three apt packages were missing from the original list, each fatal rather than
degrading:

| Package | Without it |
| ------- | ---------- |
| `libclang-dev` | `xwayland-satellite` fails — bindgen finds only versioned `libclang-NN.so.1`, not the `libclang.so` it searches for |
| `liblz4-dev` | swww's `common/build.rs` panics on the `liblz4` pkg-config probe |
| `wayland-protocols` | `swww-daemon` fails — probed by its `waybackend-scanner` dep, not visible in swww's own `build.rs` |

swww is also a cargo **workspace**, so both packages must be named:
`cargo install --git https://github.com/LGFae/swww --locked swww swww-daemon`.

## GPU note

Two GPUs: RTX 5090 at `01:00.0`, AMD iGPU at `74:00.0`. Do **not** identify them
by `renderD` number — on this box the iGPU enumerates *first* (`renderD128` =
iGPU, `renderD129` = NVIDIA), the reverse of what you'd assume. `config.kdl` pins
the render device by PCI path, which is stable, so niri can't fall back to the
iGPU and render slowly or come up dark.
