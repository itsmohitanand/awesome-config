#!/usr/bin/env bash
# install-deps.sh — install the niri desktop stack on Ubuntu 26.04.
#
#   ./niri/install-deps.sh          apt packages + build niri from source
#   ./niri/install-deps.sh --ppa    apt packages + niri from a third-party PPA
#   ./niri/install-deps.sh --apt-only
#                                   apt packages only, skip niri itself
#
# niri is NOT in the Ubuntu 26.04 archive. Source build is the default because
# it's what upstream documents and it doesn't add an unaudited apt source to
# your system. --ppa is faster but pulls from ppa:avengemedia/danklinux, which
# is a community repo — your call.

set -euo pipefail

MODE="source"
case "${1:-}" in
--ppa) MODE="ppa" ;;
--apt-only) MODE="none" ;;
"") ;;
*) echo "Unknown option: $1" >&2; exit 1 ;;
esac

echo "==> Installing desktop packages from apt"
sudo apt update
sudo apt install -y \
    wl-clipboard \
    playerctl \
    brightnessctl \
    pavucontrol \
    qalculate-gtk \
    wireplumber \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    policykit-1-gnome \
    qt6ct \
    fonts-inter \
    yaru-theme-icon \
    xwayland \
    libxcb-cursor-dev \
    libxcb1-dev \
    libclang-dev \
    liblz4-dev \
    wayland-protocols \
    meson \
    ninja-build \
    just \
    libegl-dev \
    libgles-dev \
    libfreetype-dev \
    libfontconfig-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libharfbuzz-dev \
    libxkbcommon-dev \
    libglib2.0-dev \
    libsecret-1-dev \
    libsodium-dev \
    libsdbus-c++-dev \
    libpipewire-0.3-dev \
    libwireplumber-0.5-dev \
    libpam0g-dev \
    libpolkit-agent-1-dev \
    libpolkit-gobject-1-dev \
    libcurl4-openssl-dev \
    libwebp-dev \
    libjxl-dev \
    libsndfile1-dev \
    librsvg2-dev \
    libqalculate-dev \
    libxml2-dev \
    libmd4c-dev \
    libtomlplusplus-dev \
    libical-dev \
    nlohmann-json3-dev \
    libstb-dev \
    libjemalloc-dev

echo
echo "==> Cargo-installed extras (not packaged for Ubuntu)"
if ! command -v cargo >/dev/null; then
    echo "    cargo not found — skipping. Install rustup, then re-run."
else
    # xwayland-satellite: X11 apps (Slack, Discord, DBeaver). niri 26.04 manages
    # the process itself; niri/config.kdl points at ~/.cargo/bin/xwayland-satellite.
    # Needs libclang-dev (above) — it builds bindgen, and `clang` alone ships only
    # versioned libclang-NN.so.1, not the libclang.so that bindgen's search wants.
    if command -v xwayland-satellite >/dev/null; then
        echo "    xwayland-satellite — already installed"
    else
        echo "    xwayland-satellite — installing (X11 apps: Slack, Discord)"
        cargo install --git https://github.com/Supreeeme/xwayland-satellite --locked \
            || echo "    WARNING: xwayland-satellite failed to build; X11 apps won't run" >&2
    fi

    # yazi: terminal file manager, bound to Alt+E in niri/config.kdl. Not in the
    # Ubuntu archive. Must go through the `yazi-build` helper crate — installing
    # yazi-fm/yazi-cli directly makes their build.rs abort telling you so.
    # Needs a recent rustc (26.5 wants >= 1.95); `rustup update` if it complains,
    # since cargo won't silently fall back to an older yazi.
    if command -v yazi >/dev/null; then
        echo "    yazi — already installed"
    else
        echo "    yazi — installing (file manager, Alt+E)"
        cargo install --force yazi-build \
            || echo "    WARNING: yazi failed to build; Alt+E won't open a file manager" >&2
    fi
fi

# ── noctalia from source ────────────────────────────────────────────────────
# The whole desktop shell: bar, launcher, notifications, clipboard, lock screen,
# idle handling, OSD and wallpaper. Replaces waybar + swaync + fuzzel + swayidle
# + swaylock + swww, which is why none of those are in the apt list any more.
#
# Not packaged for Ubuntu (as of 26.04), so it's a source build. v5 is native
# C++23 with meson — no Qt, no Quickshell, unlike the v4 many guides describe.
# Needs GCC 13+; 26.04 ships 15 and 24.04 ships 13, so both desks are fine.
#
# Tracks main deliberately: v5 is beta and upstream only supports the latest
# version. Pin a tag here instead if a bad day makes that a poor trade.
#
# Installs to ~/.local, no sudo. niri inherits ~/.local/bin on PATH.
echo
echo "==> Building noctalia (desktop shell) from source"
NOC_SRC="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia-src"
if [[ -d "$NOC_SRC/.git" ]]; then
    git -C "$NOC_SRC" fetch --prune && git -C "$NOC_SRC" reset --hard origin/main
else
    rm -rf "$NOC_SRC"
    git clone https://github.com/noctalia-dev/noctalia-shell.git "$NOC_SRC"
fi

# Local patches, applied on top of upstream. The reset --hard above wipes them
# every time, which is the point: they're re-applied from source of truth here
# rather than living as uncommitted edits in a cache dir nobody backs up.
#
# FAIL LOUDLY if one stops applying. Tracking main means upstream will eventually
# touch the same lines, and a patch that silently no-ops gives you a build that
# looks fine and quietly lost a feature. Drop the patch (and this block) if
# upstream implements it properly.
PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../noctalia/patches" && pwd)"
if [[ -d "$PATCH_DIR" ]]; then
    for patch in "$PATCH_DIR"/*.patch; do
        [[ -e "$patch" ]] || continue
        if git -C "$NOC_SRC" apply --check "$patch" 2>/dev/null; then
            git -C "$NOC_SRC" apply "$patch"
            echo "    patched: $(basename "$patch")"
        else
            echo "    ERROR: $(basename "$patch") no longer applies to upstream main." >&2
            echo "           Rebase or delete it, then re-run. Building unpatched." >&2
        fi
    done
fi
# --buildtype=release, not -Dnative_optimizations: the office box and this one
# share a cache dir layout but not a CPU, and native codegen isn't portable.
# --wipe reconfigures an existing build dir; it errors out if there isn't one.
noc_setup=(meson setup "$NOC_SRC/build-release" "$NOC_SRC"
           --prefix="$HOME/.local" --buildtype=release -Dtests=disabled)
[[ -d "$NOC_SRC/build-release" ]] && noc_setup+=(--wipe)
if "${noc_setup[@]}"; then
    ninja -C "$NOC_SRC/build-release" \
        && ninja -C "$NOC_SRC/build-release" install \
        && echo "    noctalia $("$HOME/.local/bin/noctalia" --version 2>/dev/null | head -1)" \
        || echo "    WARNING: noctalia build failed; you'll have no bar or launcher" >&2
else
    echo "    WARNING: noctalia meson setup failed; check the dep list above" >&2
fi

# Shell completions aren't installed by meson — upstream leaves that to the
# packager because running the freshly built binary breaks cross-compilation.
if [[ -x "$HOME/.local/bin/noctalia" ]]; then
    mkdir -p "$HOME/.local/share/zsh/site-functions" "$HOME/.local/share/bash-completion/completions"
    "$HOME/.local/bin/noctalia" completions zsh  > "$HOME/.local/share/zsh/site-functions/_noctalia" 2>/dev/null || true
    "$HOME/.local/bin/noctalia" completions bash > "$HOME/.local/share/bash-completion/completions/noctalia" 2>/dev/null || true
fi

case "$MODE" in
none)
    echo
    echo "==> Skipping niri install (--apt-only)"
    ;;

ppa)
    echo
    echo "==> Installing niri from ppa:avengemedia/danklinux"
    read -rp "    This adds a third-party apt source. Continue? [y/N] " ok
    [[ "$ok" == [yY] ]] || { echo "    Aborted."; exit 1; }
    sudo add-apt-repository -y ppa:avengemedia/danklinux
    sudo apt update
    sudo apt install -y niri
    ;;

source)
    echo
    echo "==> Building niri from source"
    sudo apt install -y \
        build-essential pkg-config clang \
        libudev-dev libgbm-dev libxkbcommon-dev libegl1-mesa-dev \
        libwayland-dev libinput-dev libseat-dev libpixman-1-dev \
        libpango1.0-dev libdisplay-info-dev libpipewire-0.3-dev \
        libdbus-1-dev libsystemd-dev

    command -v cargo >/dev/null || { echo "cargo not found — install rustup first" >&2; exit 1; }

    # Fail early and legibly on DNS trouble rather than mid-clone. Tailscale's
    # MagicDNS resolver can transiently hijack resolution on this machine.
    if ! getent hosts github.com >/dev/null; then
        echo "    Cannot resolve github.com." >&2
        echo "    DNS is down — check 'resolvectl status'. If tailscale0 is the" >&2
        echo "    current DNS scope, 'sudo tailscale set --accept-dns=false'" >&2
        echo "    (or 'sudo systemctl restart systemd-resolved') usually fixes it." >&2
        exit 1
    fi

    SRC="${XDG_CACHE_HOME:-$HOME/.cache}/niri-src"
    if [[ -d "$SRC/.git" ]]; then
        git -C "$SRC" fetch --tags --prune
    else
        # A previous run may have left a partial directory behind.
        rm -rf "$SRC"
        git clone https://github.com/niri-wm/niri.git "$SRC"
    fi

    # Build the newest tagged release rather than main.
    LATEST="$(git -C "$SRC" tag --list 'v*' --sort=-v:refname | head -1)"
    echo "    Building $LATEST"
    git -C "$SRC" checkout --quiet "$LATEST"
    cargo build --manifest-path "$SRC/Cargo.toml" --release --locked

    sudo install -Dm755 "$SRC/target/release/niri"          /usr/local/bin/niri
    # niri-session is what the .desktop file's Exec= actually invokes. Without
    # it GDM fails instantly and drops straight back to the login screen with
    # nothing in the journal.
    sudo install -Dm755 "$SRC/resources/niri-session"       /usr/local/bin/niri-session
    sudo install -Dm644 "$SRC/resources/niri.desktop"       /usr/share/wayland-sessions/niri.desktop
    sudo install -Dm644 "$SRC/resources/niri-portals.conf"  /usr/share/xdg-desktop-portal/niri-portals.conf
    sudo install -Dm644 "$SRC/resources/niri.service"       /usr/lib/systemd/user/niri.service
    sudo install -Dm644 "$SRC/resources/niri-shutdown.target" /usr/lib/systemd/user/niri-shutdown.target
    systemctl --user daemon-reload
    ;;
esac

echo
echo "==> Optional: adw-gtk3 (makes GTK3 apps match libadwaita)"
echo "    Not packaged for Ubuntu. Grab a release from:"
echo "      https://github.com/lassekongo83/adw-gtk3/releases"
echo "    and extract into ~/.themes/. switch-theme uses it if present,"
echo "    otherwise it falls back to Yaru-dark."

echo
echo "Done. Now run ./install.sh to symlink the configs, then log out and pick"
echo "\"niri\" in the GDM session picker."
