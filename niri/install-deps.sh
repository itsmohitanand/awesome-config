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
    waybar \
    fuzzel \
    sway-notification-center \
    swaybg \
    swaylock \
    swayidle \
    wl-clipboard \
    cliphist \
    wlsunset \
    playerctl \
    brightnessctl \
    pavucontrol \
    wireplumber \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    policykit-1-gnome \
    qt6ct \
    fonts-inter \
    yaru-theme-icon \
    xwayland \
    libxcb-cursor-dev \
    libxcb1-dev

# hyprlock is a nicer lock screen than swaylock and is packaged on 26.04.
if apt-cache policy hyprlock 2>/dev/null | grep -q Candidate:\ [0-9]; then
    sudo apt install -y hyprlock
fi

echo
echo "==> Cargo-installed extras (not packaged for Ubuntu)"
if ! command -v cargo >/dev/null; then
    echo "    cargo not found — skipping. Install rustup, then re-run."
else
    # xwayland-satellite: X11 apps (Slack, Discord). niri 26.04 manages the
    # process itself; niri/config.kdl points at ~/.cargo/bin/xwayland-satellite.
    if command -v xwayland-satellite >/dev/null; then
        echo "    xwayland-satellite — already installed"
    else
        echo "    xwayland-satellite — installing (X11 apps: Slack, Discord)"
        cargo install --git https://github.com/Supreeeme/xwayland-satellite --locked \
            || echo "    WARNING: xwayland-satellite failed to build; X11 apps won't run" >&2
    fi

    # swww: animated wallpaper transitions. Not published to crates.io — it only
    # ships from git, so `cargo install swww` fails with "not found in registry".
    # set-wallpaper falls back to swaybg if this doesn't build.
    if command -v swww >/dev/null; then
        echo "    swww — already installed"
    else
        echo "    swww — installing (animated wallpaper transitions)"
        cargo install --git https://github.com/LGFae/swww --locked \
            || echo "    WARNING: swww failed to build; set-wallpaper will use swaybg" >&2
    fi
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
