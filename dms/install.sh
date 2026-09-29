#!/usr/bin/env bash
# User-local, pinned DMS runtime for Ubuntu 24.04 x86_64. No system Qt/PAM edits.
set -euo pipefail
[[ $(uname -m) == x86_64 ]] || { echo 'This portable runtime supports x86_64 only.' >&2; exit 1; }
[[ $EUID != 0 ]] || { echo 'Run as your normal user, without sudo.' >&2; exit 1; }
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/awesome-config/dms-1.6.2"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/awesome-config-dms"
mkdir -p "$CACHE" "$DEST" "$HOME/.local/bin"
fetch() {
    local url=$1 file=$2 hash=$3
    if ! echo "$hash  $file" | sha256sum --check --status 2>/dev/null; then
        curl --fail --location --retry 3 "$url" -o "$file"
    fi
    echo "$hash  $file" | sha256sum --check
}
fetch 'https://github.com/AvengeMedia/DankMaterialShell/releases/download/v1.6.2/dms-full-amd64.tar.gz' \
    "$CACHE/dms-full-amd64.tar.gz" 29d93a8c84843966ab20edd7c20710dfc693050388528140864c908a92877662
fetch 'https://github.com/pkgforge-dev/Quickshell-AppImage/releases/download/0.3.1-1%402026-09-22_1790090866/quickshell-0.3.1-1-anylinux-x86_64.AppImage' \
    "$CACHE/quickshell.AppImage" 2f69fb0f3cf814b6a03b9e1a1fe6bc6eeac8cbd50a3082844f533d2f6d0be341
if [[ ! -x "$DEST/runtime/AppRun" ]]; then
    STAGE="$(mktemp -d "$CACHE/extract.XXXXXX")"
    chmod +x "$CACHE/quickshell.AppImage"
    (cd "$STAGE" && "$CACHE/quickshell.AppImage" --appimage-extract >extract.log)
    # This release extracts to AppDir with a squashfs-root compatibility symlink.
    mv "$STAGE/AppDir" "$DEST/runtime"
fi
# These cross-libc preloads deadlock in jemalloc on the tested Noble machine.
# Keep them for inspection, but don't preload them. Bundled Qt/libc still work.
if [[ -d "$DEST/runtime/lib/sharun-preload" ]]; then
    mv "$DEST/runtime/lib/sharun-preload" "$DEST/runtime/lib/sharun-preload.disabled"
fi
timeout -k 2 10 "$DEST/runtime/AppRun" --version
tar -xzf "$CACHE/dms-full-amd64.tar.gz" -C "$DEST" ./bin/dms
cat > "$DEST/bin/qs" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
RUNTIME="$(cd "$(dirname "$0")/../runtime" && pwd)"
export DISABLE_AUTO_UPDATES=1
exec "$RUNTIME/AppRun" "$@"
WRAPPER
chmod +x "$DEST/bin/qs"
ln -sfn qs "$DEST/bin/quickshell"
# DMS discovers qs through its own private PATH; no global Qt environment.
install -m755 "$SOURCE_DIR/run.sh" "$HOME/.local/bin/dms"
SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell"
mkdir -p "$SETTINGS"
if [[ ! -e "$SETTINGS/settings.json" ]]; then
    cp "$SOURCE_DIR/settings.json" "$SETTINGS/settings.json"
fi
# Seed wallpaper on first install. DMS owns these mutable files, not symlinks.
python3 - "$SOURCE_DIR/../niri/wallpapers/everblush.png" <<'PY'
import json, os, pathlib, sys
p = pathlib.Path(os.environ.get('XDG_STATE_HOME', str(pathlib.Path.home()/'.local/state'))) / 'DankMaterialShell/session.json'
if not p.exists():
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps({'wallpaperPath': str(pathlib.Path(sys.argv[1]).resolve()), 'isLightMode': False}, indent=2)+'\n')
PY
"$HOME/.local/bin/dms" version
"$HOME/.local/bin/dms" auth validate --path /etc/pam.d/login
# Prevent the packaged legacy panel/notification services from racing DMS at login.
# No --now: applying the config should not disrupt the current desktop session.
for unit in waybar.service swaync.service; do
    if [[ $(systemctl --user show "$unit" -p LoadState --value 2>/dev/null) != not-found ]]; then
        systemctl --user mask "$unit"
    fi
done
printf '\nInstalled DMS. Try: bash dms/preview.sh\n'
