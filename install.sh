#!/usr/bin/env bash
# install.sh — symlink awesome-config into ~/.config and friends.
# Idempotent: safe to run repeatedly. Detects parent-dir symlinks that would
# otherwise cause self-loops (e.g. when ~/.config/nvim is already a whole-dir
# symlink to this repo).
#
# This script never edits ~/.zshrc or ~/.bashrc. Source ~/.modern_shell_config
# from your shell rc file yourself — see the message printed at the end.

set -euo pipefail
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

link() {
    local rel="$1" dest="$2"
    local src="$DOTFILES/$rel"

    if [[ ! -e "$src" && ! -L "$src" ]]; then
        printf '  skip (missing in repo): %s\n' "$rel" >&2
        return
    fi

    # If dest already resolves to src (already linked, or reached via a parent
    # symlink), do nothing. Creating a symlink here would produce a self-loop.
    local src_real dest_real
    src_real="$(realpath "$src")"
    dest_real="$(realpath -m "$dest")"
    if [[ "$dest_real" == "$src_real" ]]; then
        printf '  ok:   %s\n' "$dest"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    printf '  link: %s -> %s\n' "$dest" "$src"
}

echo "Symlinking awesome-config from $DOTFILES"

# Kitty
link kitty/kitty.conf                  "$HOME/.config/kitty/kitty.conf"
link kitty/themes/poimandres.conf      "$HOME/.config/kitty/themes/poimandres.conf"
link kitty/themes/cyberdream.conf      "$HOME/.config/kitty/themes/cyberdream.conf"
link kitty/themes/everblush.conf       "$HOME/.config/kitty/themes/everblush.conf"

# Zellij
link zellij/config.kdl                 "$HOME/.config/zellij/config.kdl"
link zellij/layouts/python-dev.kdl     "$HOME/.config/zellij/layouts/python-dev.kdl"
link zellij/layouts/phd.kdl            "$HOME/.config/zellij/layouts/phd.kdl"
link zellij/layouts/latex-thesis.kdl   "$HOME/.config/zellij/layouts/latex-thesis.kdl"

# Starship
link starship/starship.toml            "$HOME/.config/starship.toml"

# Neovim
link nvim/init.lua                     "$HOME/.config/nvim/init.lua"
link nvim/lua                          "$HOME/.config/nvim/lua"
# lazy.nvim writes its lockfile next to init.lua. Symlinked so `:Lazy sync`
# updates the tracked file directly — without this, lazy creates its own real
# file there and each machine silently drifts to different plugin commits.
link nvim/lazy-lock.json               "$HOME/.config/nvim/lazy-lock.json"

# niri (Wayland compositor) and its shell components.
link niri/config.kdl                   "$HOME/.config/niri/config.kdl"

# noctalia — bar, launcher, notifications, clipboard, lock, idle and wallpaper.
# config.toml is safe to symlink because noctalia writes runtime changes (the
# settings GUI, `noctalia msg ...`) to ~/.local/state/noctalia/settings.toml
# instead, so the repo copy stays clean. palettes/ is read-only to noctalia.
link noctalia/config.toml              "$HOME/.config/noctalia/config.toml"
link noctalia/palettes                 "$HOME/.config/noctalia/palettes"

link niri/keys.sh                      "$HOME/.local/bin/niri-keys"
chmod +x "$DOTFILES/niri/keys.sh" "$DOTFILES/niri/install-deps.sh" \
         "$DOTFILES/noctalia/make-palette.py"
mkdir -p "$HOME/.config/wallpapers" "$HOME/Pictures/Screenshots"

# niri treats a missing `include` as a FATAL config error, not a skipped file —
# so ~/.config/niri/noctalia.kdl has to exist before the first login or the
# session won't start. noctalia regenerates it on every theme change; this is
# only the seed. Not symlinked and not tracked: it's generated output, and niri
# resolves the include against the symlink's directory (~/.config/niri), not the
# repo, so noctalia's writes never land here.
if [[ ! -f "$HOME/.config/niri/noctalia.kdl" ]]; then
    mkdir -p "$HOME/.config/niri"
    cat > "$HOME/.config/niri/noctalia.kdl" <<'SEED'
// Seeded by install.sh; noctalia overwrites this on the next theme change.
layout {
    focus-ring {
        active-color   "#6cbfbf"
        inactive-color "#2d3437"
    }
}
SEED
    printf '  seed: %s\n' "$HOME/.config/niri/noctalia.kdl"
fi

# Same idea for kitty: kitty.conf includes themes/noctalia.conf, which noctalia
# generates. kitty only warns on a missing include rather than refusing to start,
# but seeding it means a fresh clone opens themed instead of on kitty's defaults.
if [[ ! -f "$HOME/.config/kitty/themes/noctalia.conf" ]]; then
    mkdir -p "$HOME/.config/kitty/themes"
    seed_theme="$(cat "$HOME/.config/current-theme" 2>/dev/null || echo everblush)"
    cp "$DOTFILES/kitty/themes/${seed_theme}.conf" \
       "$HOME/.config/kitty/themes/noctalia.conf" 2>/dev/null \
        && printf '  seed: %s\n' "$HOME/.config/kitty/themes/noctalia.conf"
fi

# Pre-rendered wallpapers, one per theme, so a fresh clone has them without
# waiting on a 400M-point render. Re-roll any of them in place with:
#   ./niri/make-wallpaper-chaos.py <theme> niri/wallpapers/<theme>.png
# Symlinks, so a re-render shows up on the next switch-theme with no re-install.
# ~/.config/wallpapers is what noctalia's [wallpaper] directory points at, so
# these also populate its wallpaper picker and the /wall launcher provider.
link niri/wallpapers/everblush.png     "$HOME/.config/wallpapers/everblush.png"
link niri/wallpapers/poimandres.png    "$HOME/.config/wallpapers/poimandres.png"
link niri/wallpapers/cyberdream.png    "$HOME/.config/wallpapers/cyberdream.png"

# niri isn't in the Ubuntu archive, so the configs above are inert until it's
# built. Ask rather than run it unprompted — install-deps.sh needs sudo and a
# source build takes a while. ponytail: prompt, not a --yes flag; add one when
# this needs to run unattended.
if ! command -v niri >/dev/null; then
    read -rp "  niri not installed. Run niri/install-deps.sh now? [y/N] " ok
    [[ "$ok" == [yY] ]] && "$DOTFILES/niri/install-deps.sh" \
        || echo "  skipped: run ./niri/install-deps.sh when you want the niri session"
fi

# Ubuntu ships waybar.service AND swaync.service globally enabled and
# WantedBy=graphical-session.target, which niri.service joins — so systemd starts
# both even though nothing in this repo spawns them any more. A stray waybar
# lands on top of noctalia's bar, and a stray swaync grabs
# org.freedesktop.Notifications first, which leaves noctalia unable to claim it
# and kills notifications silently. Killing the processes isn't enough: systemd
# restarts them. Mask both.
#
# install-deps.sh no longer installs either package, so this is a no-op on a
# fresh machine; it matters on boxes that ran the old stack.
for unit in waybar.service swaync.service; do
    if systemctl --user list-unit-files "$unit" >/dev/null 2>&1; then
        if [[ "$(systemctl --user is-enabled "$unit" 2>/dev/null)" != "masked" ]]; then
            systemctl --user stop "$unit" >/dev/null 2>&1 || true
            systemctl --user mask "$unit" >/dev/null 2>&1 \
                && echo "  mask: $unit (would fight noctalia)"
        fi
    fi
done

# Ulauncher — kept so the GNOME session still works as a fallback while you
# settle into niri. Under niri the launcher is noctalia's (Alt+Space).
# Link the single autostart entry, not all of ~/.config/autostart — other apps
# drop their own .desktop files in that directory.
link ulauncher/settings.json           "$HOME/.config/ulauncher/settings.json"
link ulauncher/shortcuts.json          "$HOME/.config/ulauncher/shortcuts.json"
link ulauncher/ulauncher.desktop       "$HOME/.config/autostart/ulauncher.desktop"
chmod +x "$DOTFILES/ulauncher/gnome-keybinding.sh"
"$DOTFILES/ulauncher/gnome-keybinding.sh"

# Modern shell config (source this from ~/.zshrc or ~/.bashrc yourself)
link .modern_shell_config              "$HOME/.modern_shell_config"

# Theme switcher
link switch-theme.sh                   "$HOME/.local/bin/switch-theme"
chmod +x "$DOTFILES/switch-theme.sh"

# Apply the current theme so every surface starts in sync. Defaults to everblush
# on a fresh machine. Without a running noctalia this only does nvim/zellij and
# says so — the rest follows at the next login from noctalia/config.toml.
CURRENT_THEME="$(cat "$HOME/.config/current-theme" 2>/dev/null || echo everblush)"
echo
echo "Applying theme: $CURRENT_THEME"
"$DOTFILES/switch-theme.sh" "$CURRENT_THEME" || echo "  (theme switch failed — run switch-theme manually)"

echo
echo "Done. This script did NOT touch ~/.zshrc or ~/.bashrc."
echo "If you haven't already, add this line to your shell rc:"
echo "    source ~/.modern_shell_config"
echo
echo "Switch themes with:  switch-theme poimandres | cyberdream | everblush"
echo "Install the niri desktop stack with:  ./niri/install-deps.sh"
