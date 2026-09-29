#!/usr/bin/env bash
# Open a disposable DMS desktop inside the current X11/Wayland session.
set -euo pipefail
case "${1:-}" in ''|--smoke) ;; *) echo 'Usage: bash dms/preview.sh [--smoke]' >&2; exit 2;; esac
[[ -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} ]] || { echo 'Run from an existing graphical desktop.' >&2; exit 1; }
REPO="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
command -v dms >/dev/null || { echo 'Run bash dms/install.sh first.' >&2; exit 1; }
export DMS_PREVIEW_DIR
DMS_PREVIEW_DIR="$(mktemp -d /tmp/dms-preview.XXXXXX)"
export DMS_PREVIEW_SMOKE="${1:-}" DMS_PREVIEW_REPO="$REPO"
python3 - "$REPO" "$DMS_PREVIEW_DIR" <<'PY'
import json, pathlib, sys
repo, dst = map(pathlib.Path, sys.argv[1:])
# Startup commands in this repository are single logical lines (possibly continued).
lines, skip = [], False
for line in (repo/'niri/config.kdl').read_text().splitlines(True):
    if line.lstrip().startswith('spawn-at-startup '):
        skip = True
    if skip:
        skip = line.rstrip().endswith('\\')
        continue
    lines.append(line)
(dst/'config.kdl').write_text(''.join(lines))
p = dst/'config/DankMaterialShell'
p.mkdir(parents=True)
s = json.loads((repo/'dms/settings.json').read_text())
for key in ('acLockTimeout', 'acMonitorTimeout', 'batteryLockTimeout', 'batteryMonitorTimeout'):
    s[key] = 0
s.update(lockBeforeSuspend=False, loginctlLockIntegration=False, lockAtStartup=False)
(p/'settings.json').write_text(json.dumps(s))
PY
cat > "$DMS_PREVIEW_DIR/bus.conf" <<'BUS'
<busconfig>
  <type>session</type><listen>unix:tmpdir=/tmp</listen><auth>EXTERNAL</auth>
  <policy context="default">
    <allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/>
  </policy>
</busconfig>
BUS
cat > "$DMS_PREVIEW_DIR/start.sh" <<'CHILD'
#!/usr/bin/env bash
set -euo pipefail
dms run >"$DMS_PREVIEW_DIR/dms.log" 2>&1 &
shell_pid=$!
trap 'kill "$shell_pid" 2>/dev/null || true' EXIT
ready=false
for ((i=0; i<25; i++)); do
    if timeout 2 dms ipc call lock isLocked >/dev/null 2>&1; then ready=true; break; fi
    kill -0 "$shell_pid" 2>/dev/null || break
    sleep 1
done
if [[ $ready != true ]]; then
    echo 'DMS did not become ready; inspect dms.log.' >&2
    niri msg action quit --skip-confirmation
    exit 1
fi
dms ipc call wallpaper set "$DMS_PREVIEW_REPO/niri/wallpapers/everblush.png"
if [[ $DMS_PREVIEW_SMOKE == --smoke ]]; then
    sleep 3
    grim "$DMS_PREVIEW_DIR/desktop.png"
    dms ipc call spotlight toggle
    sleep 2
    grim "$DMS_PREVIEW_DIR/launcher.png"
    dms ipc call spotlight toggle
    dms ipc call lock demo
    sleep 2
    grim "$DMS_PREVIEW_DIR/lock.png"
    touch "$DMS_PREVIEW_DIR/PASS"
    niri msg action quit --skip-confirmation
else
    wait "$shell_pid"
fi
CHILD
niri validate -c "$DMS_PREVIEW_DIR/config.kdl"
printf 'Preview logs and screenshots: %s\nClose the Niri window to exit.\n' "$DMS_PREVIEW_DIR"
export XDG_CONFIG_HOME="$DMS_PREVIEW_DIR/config" XDG_STATE_HOME="$DMS_PREVIEW_DIR/state" XDG_CACHE_HOME="$DMS_PREVIEW_DIR/cache"
export XDG_CURRENT_DESKTOP=niri
if [[ $DMS_PREVIEW_SMOKE == --smoke ]]; then
    timeout -k 3 70 dbus-run-session --config-file="$DMS_PREVIEW_DIR/bus.conf" -- \
        niri -c "$DMS_PREVIEW_DIR/config.kdl" -- bash "$DMS_PREVIEW_DIR/start.sh" >"$DMS_PREVIEW_DIR/niri.log" 2>&1
    [[ -f "$DMS_PREVIEW_DIR/PASS" ]] || { echo 'Preview failed; inspect logs.' >&2; exit 1; }
    echo 'PASS: desktop, launcher, and lock demo captured.'
else
    dbus-run-session --config-file="$DMS_PREVIEW_DIR/bus.conf" -- \
        niri -c "$DMS_PREVIEW_DIR/config.kdl" -- bash "$DMS_PREVIEW_DIR/start.sh" >"$DMS_PREVIEW_DIR/niri.log" 2>&1
fi
