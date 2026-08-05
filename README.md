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
│   └── set-wallpaper.sh    # → ~/.local/bin/set-wallpaper
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
