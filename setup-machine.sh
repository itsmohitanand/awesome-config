#!/usr/bin/env bash
# Bootstrap this Ubuntu machine, then use the alipes desktop installer.
# Run as your normal user: bash setup-machine.sh
set -euo pipefail
[[ "$EUID" != 0 ]] || { echo 'Run without sudo; this script invokes sudo when needed.' >&2; exit 1; }
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
trap 'echo "Setup stopped at line $LINENO. Fix the reported error and rerun bash setup-machine.sh." >&2' ERR

sudo -v
sudo apt update
# Install build dependencies before install-deps.sh builds its Cargo extras.
sudo apt install -y rustup build-essential pkg-config clang cmake ninja-build \
    gettext unzip curl git fontconfig libssl-dev libudev-dev libgbm-dev \
    libxkbcommon-dev libegl1-mesa-dev libwayland-dev libinput-dev libseat-dev \
    libpixman-1-dev libpango1.0-dev libdisplay-info-dev libpipewire-0.3-dev \
    libdbus-1-dev libsystemd-dev ripgrep fd-find fzf bat zoxide zsh
rustup toolchain install stable --profile minimal
rustup default stable

bash "$DOTFILES/niri/install-deps.sh"
for app in starship zellij; do
    if ! command -v "$app" >/dev/null; then
        cargo install --locked "$app" --root "$HOME/.local"
    fi
done
# Make Cargo desktop helpers visible in the login PATH too.
for app in yazi ya swww swww-daemon xwayland-satellite; do
    if [[ -x "$HOME/.cargo/bin/$app" && ! -e "$HOME/.local/bin/$app" ]]; then
        ln -s "$HOME/.cargo/bin/$app" "$HOME/.local/bin/$app"
    fi
done

# This branch enables vim._core.ui2, so use upstream's nightly source tag.
# Build in a dedicated cache; reuse it if a previous attempt was interrupted.
NVIM_SRC="${XDG_CACHE_HOME:-$HOME/.cache}/awesome-config-neovim"
if ! command -v nvim >/dev/null; then
    if [[ ! -d "$NVIM_SRC" ]]; then
        git clone --depth 1 --branch nightly https://github.com/neovim/neovim.git "$NVIM_SRC"
    fi
    make -C "$NVIM_SRC" CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$HOME/.local"
    make -C "$NVIM_SRC" CMAKE_INSTALL_PREFIX="$HOME/.local" install
fi

# Install the font named by both the terminal and desktop configs.
FONT_DIR="$HOME/.local/share/fonts/IosevkaNerdFont"
if ! fc-list : family | grep -Fq 'Iosevka Nerd Font Mono'; then
    FONT_ARCHIVE="$(mktemp --suffix=.zip)"
    curl --fail --location --retry 3 \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Iosevka.zip \
        -o "$FONT_ARCHIVE"
    mkdir -p "$FONT_DIR"
    unzip -o "$FONT_ARCHIVE" '*.ttf' -d "$FONT_DIR"
    fc-cache -f "$FONT_DIR"
fi

bash "$DOTFILES/install.sh"
if ! grep -Fq 'source ~/.modern_shell_config' "$HOME/.bashrc"; then
    cp -p "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d-%H%M%S)"
    printf '\n# awesome-config\nsource ~/.modern_shell_config\n' >> "$HOME/.bashrc"
fi
niri validate -c "$DOTFILES/niri/config.kdl"
ghostty +validate-config
printf '\nSetup complete. Log out, select niri in the login screen, and log in.\n'
