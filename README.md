# awesome-config

Terminal configuration for kitty, starship, zellij, and shell.

## Tools

| Tool | Purpose |
|------|---------|
| [kitty](https://sw.kovidgoyal.net/kitty/) | GPU-accelerated terminal emulator |
| [starship](https://starship.rs/) | Cross-shell prompt |
| [zellij](https://zellij.dev/) | Terminal multiplexer |
| [neovim](https://neovim.io/) | Text editor |

## Install

```bash
git clone https://github.com/itsmohitanand/awesome-config.git
cd awesome-config
bash install.sh
```

This creates symlinks from `~/.config/` back to the repo, so any edits in the repo are live immediately.

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
source ~/.modern_shell_config
```

## Theming

All four apps share a unified theme system. Switch everything at once:

```bash
switch-theme cyberdream   # default
switch-theme everblush
```

| App | How theme is applied |
|-----|---------------------|
| kitty | `include themes/<name>.conf` in `kitty.conf` — reload with `ctrl+shift+F5` |
| starship | `palette = '<name>'` in `starship.toml` — takes effect in new shells |
| zellij | `theme "<name>"` in `config.kdl` — requires session restart |
| neovim | `local theme = '<name>'` in `init.lua` — restart or `:source` |

### Adding a new theme

1. Add `kitty/themes/<name>.conf` with color definitions
2. Add a `[palettes.<name>]` block to `starship/starship.toml`
3. Add a `<name> { ... }` block inside `themes {}` in `zellij/config.kdl`
4. Ensure the neovim colorscheme plugin for `<name>` is in `init.lua`
5. Run `switch-theme <name>`

## Structure

```
awesome-config/
├── install.sh              # Symlinks everything into ~/.config/
├── switch-theme.sh         # Switches active theme across all apps
├── .modern_shell_config    # Shared aliases and functions (bash + zsh)
├── kitty/
│   ├── kitty.conf
│   └── themes/
│       ├── cyberdream.conf
│       └── everblush.conf
├── starship/
│   └── starship.toml       # All palettes defined; palette = 'X' to select
└── zellij/
    ├── config.kdl           # All themes defined; theme "X" to select
    └── layouts/
        └── python-dev.kdl
```

## Shell config (`.modern_shell_config`)

Sourced from your shell rc. Provides:

- Modern tool replacements: `eza` → `ls`, `bat` → `cat`, `zoxide` → `cd`
- Navigation aliases (`..`, `...`)
- Git aliases (`gs`, `ga`, `gc`, `gp`, `gl`, ...)
- Docker aliases (`d`, `dc`, `dps`, ...)
- Utility functions: `mkcd`, `extract`, `topcmds`, `hr`
- Starship prompt initialisation
