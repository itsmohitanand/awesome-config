# DMS on Ubuntu 24.04

Run `bash dms/install.sh`, then `bash dms/preview.sh` to try the desktop inside
Ubuntu. `bash dms/preview.sh --smoke` captures the desktop, launcher, and lock demo
and exits. See [the first-run guide](../niri/FIRST-RUN.md) for limitations and login.

- `install.sh`: pinned DMS 1.6.2 + third-party Quickshell 0.3.1 runtime, no sudo.
- `run.sh`: installed as `~/.local/bin/dms`; supplies a private Quickshell PATH.
- `settings.json`: initial settings, copied only when no existing settings exist.
- `preview.sh`: separate settings/state/cache, no session environment import,
  no idle/suspend lock. Requires Niri, grim, Python 3, and dbus-run-session.

Sources: [DMS](https://github.com/AvengeMedia/DankMaterialShell/releases/tag/v1.6.2),
[portable runtime](https://github.com/pkgforge-dev/Quickshell-AppImage),
[system PAM authentication](https://danklinux.com/docs/dankmaterialshell/lock-screen-authentication).
