# awesome-config

Desktop and terminal configuration: a [niri](https://github.com/YaLTeR/niri) Wayland
session on Ubuntu, with kitty, zellij, starship and neovim inside it.

## Tools

| Tool | Purpose |
|------|---------|
| [niri](https://github.com/YaLTeR/niri) | Scrollable-tiling Wayland compositor |
| [waybar](https://github.com/Alexays/Waybar) | Top panel |
| [fuzzel](https://codeberg.org/dnkl/fuzzel) | Application launcher (`Super+Space`) |
| [swaync](https://github.com/ErikReider/SwayNotificationCenter) | Notifications + control centre (`Super+N`) |
| [kitty](https://sw.kovidgoyal.net/kitty/) | GPU-accelerated terminal emulator |
| [starship](https://starship.rs/) | Cross-shell prompt |
| [zellij](https://zellij.dev/) | Terminal multiplexer |
| [neovim](https://neovim.io/) | Text editor |
| [ulauncher](https://ulauncher.io/) | Launcher for the fallback GNOME session (`Ctrl+Space`) |

## Install

```bash
git clone https://github.com/itsmohitanand/awesome-config.git
cd awesome-config
./niri/install-deps.sh      # apt packages + build niri (see notes below)
bash install.sh             # symlink configs, apply current theme
```

`install.sh` creates symlinks from `~/.config/` back to the repo, so any edits in
the repo are live immediately.

Then log out and pick **niri** in the GDM session list. The GNOME session stays
installed as a fallback.

### About the niri install

niri is not in the Ubuntu 26.04 archive. `install-deps.sh` defaults to building
the newest tagged release from source with cargo, which is what upstream
documents and avoids adding an unaudited apt source. If you'd rather have a
packaged binary, `./niri/install-deps.sh --ppa` pulls from
`ppa:avengemedia/danklinux` — a community PPA, so decide for yourself.

Two things are genuinely optional and not packaged for Ubuntu:

- **`swww`** (`cargo install swww`) — animated wallpaper crossfades.
  `set-wallpaper` falls back to `swaybg` without it.
- **`xwayland-satellite`** — needed for X11 apps (Slack, Discord). niri only
  spawns it if it's on `PATH`.

## Design notes

**niri has no blur.** Unlike Hyprland it doesn't blur behind layer surfaces, so a
translucent panel shows raw wallpaper rather than frosted glass. Everything here
is therefore deliberately **opaque and typographic** — the polish comes from the
focus-ring gradient, rounded window geometry, shadows, spring animations, and
consistent spacing.

If you do want the frosted look, pre-blur the wallpaper once instead of asking
the compositor to do it every frame:

```bash
magick wallpaper.png -blur 0x24 -modulate 92 ~/.config/wallpapers/everblush.png
```

**Keybind policy:** every niri binding is `Super`-based. Nothing binds a bare
`Ctrl+key`, so zellij's `Ctrl+G/P/T/N/H/S/O/Q` keep working inside any terminal.
Don't add plain-Ctrl bindings to `niri/config.kdl`.

Press `Super+Shift+/` for the full keybind overlay.

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
source ~/.modern_shell_config
```

## Theming

Every surface — terminal, editor, panel, launcher, notifications, window
borders, GTK/Qt dialogs, wallpaper — switches from one command:

```bash
switch-theme everblush    # default
switch-theme poimandres
switch-theme cyberdream
```

| Surface | How theme is applied |
|---------|---------------------|
| kitty | `include themes/<name>.conf` in `kitty.conf` — reload with `ctrl+shift+F5` |
| starship | `palette = '<name>'` in `starship.toml` — takes effect in new shells |
| zellij | `theme "<name>"` in `config.kdl` — requires session restart |
| neovim | `local theme = '<name>'` in `init.lua` — restart or `:source` |
| niri | focus-ring gradient rewritten in `config.kdl` — live |
| waybar | `~/.config/waybar/theme.css` symlink repointed — live (`SIGUSR2`) |
| swaync | `~/.config/swaync/theme.css` symlink repointed — live |
| fuzzel | `[colors]` block between the `THEME:START/END` markers — live |
| GTK / Qt | `gsettings` colour-scheme, theme, cursor and fonts |
| wallpaper | `~/.config/wallpapers/<name>.png` via `swww`, else `swaybg` |

The active theme is recorded in `~/.config/current-theme`.

### Wallpapers

One pre-rendered 4K wallpaper per theme ships in `niri/wallpapers/`, symlinked
into `~/.config/wallpapers/` by `install.sh` — a fresh clone is themed with no
render step. They cost ~13MB of repo, which is the deal for not waiting on a
400M-point render per machine.

`niri/make-wallpaper-chaos.py <theme>` is what generated them: the invariant
measure of a 2-D chaotic map — Clifford by default, or `--system dejong|ikeda` —
coloured from the theme's own palette. Re-roll one in place and the symlink picks
it up on the next `switch-theme`, no re-install:

```bash
./niri/make-wallpaper-chaos.py cyberdream niri/wallpapers/cyberdream.png
```

`niri/make-wallpaper.py` is the cheap alternative: gradient, two accent glows,
grain. Seconds instead of a minute, no numpy.

Output is 3840x2160 by default, which downscales cleanly onto any 16:9 panel.
`swww` crop-to-fills, though, so a screen of a different aspect — a rotated
portrait panel especially — gets a slice of the middle rather than the whole
attractor. Render at that panel's own resolution instead:

```bash
./niri/make-wallpaper-chaos.py everblush wall.png --size 1440x2560 --zoom 0.95
```

`--zoom` <1 crops into the filaments, `--offset` shifts it clear of where you
keep windows. Applying different images per output needs `swww img --outputs`;
`set-wallpaper` sets one image for all of them.

Waybar and swaync share one palette file (`themes/<name>.css`) because both use
GTK CSS — the `@define-color` names are the single source of truth for the
desktop chrome. `switch-theme.sh` carries a matching palette table for the
surfaces that can't `@import`.

### Adding a new theme

1. Add `kitty/themes/<name>.conf` with color definitions
2. Add `themes/<name>.css` with the ten `@define-color` names
3. Add a matching `<name>)` case to the palette table in `switch-theme.sh`
4. Add a `[palettes.<name>]` block to `starship/starship.toml`
5. Add a `<name> { ... }` block inside `themes {}` in `zellij/config.kdl`
6. Ensure the neovim colorscheme plugin for `<name>` is in `init.lua`
7. Optionally drop `~/.config/wallpapers/<name>.png`
8. Run `switch-theme <name>`

## Structure

```
awesome-config/
├── install.sh              # Symlinks everything into ~/.config/
├── switch-theme.sh         # Switches active theme across all surfaces
├── .modern_shell_config    # Shared aliases and functions (bash + zsh)
├── themes/                 # Shared GTK palettes (waybar + swaync)
│   ├── poimandres.css
│   ├── cyberdream.css
│   └── everblush.css
├── niri/
│   ├── config.kdl          # → ~/.config/niri/config.kdl
│   ├── install-deps.sh     # apt packages + niri build (not symlinked)
│   ├── set-wallpaper.sh    # → ~/.local/bin/set-wallpaper
│   ├── make-wallpaper-chaos.py  # strange-attractor renderer (numpy + pillow)
│   └── wallpapers/         # pre-rendered 4K, one per theme
│       └── <theme>.png     # → ~/.config/wallpapers/<theme>.png
├── waybar/
│   ├── config.jsonc        # → ~/.config/waybar/config.jsonc
│   └── style.css           # → ~/.config/waybar/style.css
├── fuzzel/
│   └── fuzzel.ini          # → ~/.config/fuzzel/fuzzel.ini
├── swaync/
│   ├── config.json         # → ~/.config/swaync/config.json
│   └── style.css           # → ~/.config/swaync/style.css
├── kitty/
│   ├── kitty.conf
│   └── themes/
│       ├── poimandres.conf
│       ├── cyberdream.conf
│       └── everblush.conf
├── nvim/
│   ├── init.lua            # Entry point; local theme = 'X' to select
│   └── lua/
│       ├── core/
│       │   └── options.lua
│       ├── keymaps.lua
│       └── plugins/        # Modular plugin configs (LSP, DAP, REPL, etc.)
├── starship/
│   └── starship.toml       # All palettes defined; palette = 'X' to select
├── ulauncher/
│   ├── settings.json       # → ~/.config/ulauncher/settings.json
│   ├── shortcuts.json      # → ~/.config/ulauncher/shortcuts.json
│   ├── ulauncher.desktop   # → ~/.config/autostart/ulauncher.desktop
│   └── gnome-keybinding.sh # Ctrl+Space hotkey (dconf, can't be symlinked)
└── zellij/
    ├── config.kdl           # All themes defined; theme "X" to select
    └── layouts/
        └── python-dev.kdl
```

## Ulauncher (GNOME fallback session only)

Under niri the launcher is **fuzzel**, bound to `Super+Space` in
`niri/config.kdl`. Ulauncher is kept for the GNOME session that remains
installed as a fallback.

`Ctrl+Space` opens the launcher; it autostarts on login.

Under Wayland an application cannot grab a global hotkey for itself, so
Ulauncher's own hotkey preference has no effect on GNOME/Wayland. The bind is a
GNOME custom shortcut instead, which lives in dconf rather than a file — so it
can't be symlinked and `install.sh` applies it by running
`ulauncher/gnome-keybinding.sh`. That script is idempotent and leaves your other
custom shortcuts alone. To use a different key:

```bash
./ulauncher/gnome-keybinding.sh '<Super>r'
```

Ulauncher rewrites `settings.json`/`shortcuts.json` in place, so changes made in
its preferences window land in the repo and show up as a git diff.

## Shell config (`.modern_shell_config`)

Sourced from your shell rc. Provides:

- Modern tool replacements: `eza` → `ls`, `bat` → `cat`, `zoxide` → `cd`
- Navigation aliases (`..`, `...`)
- Git aliases (`gs`, `ga`, `gc`, `gp`, `gl`, ...)
- Docker aliases (`d`, `dc`, `dps`, ...)
- Utility functions: `mkcd`, `extract`, `topcmds`, `hr`
- Starship prompt initialisation
- dstask aliases and completion (see below)

## Tasks (`dstask`)

Taskwarrior-like CLI with no sync server: the store is a git repo holding one
YAML file per task, and every add/modify auto-commits. `dstask sync` is pull then
push with an automatic merge commit.

Three separate git repos, deliberately — config here, notes in
`~/Documents/notes`, tasks in `~/Documents/tasks`
([itsmohitanand/tasks](https://github.com/itsmohitanand/tasks)). dstask expects to
own its repo and commits on its own schedule, so sharing a branch with anything
else invites conflicts.

Install needs no sudo. Ubuntu 24.04 ships Go 1.22 and dstask needs 1.23.4, so
take the toolchain from go.dev:

```bash
curl -sSL -o /tmp/go.tar.gz https://go.dev/dl/go1.26.5.linux-amd64.tar.gz
# verify against the sha256 published at https://go.dev/dl/
tar -C ~/.local -xzf /tmp/go.tar.gz
PATH="$HOME/.local/go/bin:$PATH" GOBIN="$HOME/.local/bin" \
    go install github.com/naggie/dstask/cmd/dstask@v1.0.1
```

Build from source rather than the release binary: v1.0.1's `checksums.sha256`
lists filenames that match none of the attached assets, so the prebuilt binaries
have no usable checksum. `go install` verifies through `sum.golang.org`.

New machine:

```bash
git clone https://github.com/itsmohitanand/tasks.git ~/Documents/tasks
```

| Alias | Command |
| ----- | ------- |
| `t`   | `dstask` |
| `tn`  | `dstask next` — pending, filtered by context |
| `ta`  | `dstask add` |
| `ts`  | `dstask sync` |

`DSTASK_GIT_REPO` points at `~/Documents/tasks`; bash/zsh completion is sourced
from `dstask {bash,zsh}-completion` when the binary is on `PATH`. Context is
per-machine and *not* synced — set it with `dstask context +work` and it applies
automatically to new tasks.
