# Niri + DMS on Ubuntu 24.04

## Try it inside Ubuntu first

```bash
bash dms/install.sh
bash dms/preview.sh
# Automated preview with screenshots and an automatic exit:
bash dms/preview.sh --smoke
```

The preview opens a nested Niri window using separate settings and a private
D-Bus session. Close that window to exit. It disables idle/suspend locking and
uses DMS's **demo** lock screen for screenshots. Logs and images are printed under
`/tmp/dms-preview.*`. The smoke test checks rendering and IPC, not password unlock.

Verified on 2026-09-29: Niri 26.04, Ubuntu 24.04.5, NVIDIA RTX 5090, DMS 1.6.2,
and portable Quickshell 0.3.1. Desktop, launcher, and lock demo render. This does
**not** prove a GDM/DRM session works: nested rendering uses the host desktop's
output, not the physical output modes in `config.kdl`. The earlier blank login
has not been diagnosed; the user journal was inaccessible during this check.

## Installation and runtime

`bash install.sh` installs the pinned user-local DMS runtime before linking the
Niri config. DMS owns the bar, launcher, notifications, clipboard, wallpaper,
and idle lock. Waybar, SwayNC, Swayidle and swww are no longer autostarted.
The installer masks the user Waybar and SwayNC services to prevent duplicate
panels/notification servers at login. Legacy configs and the standalone lock
fallback remain available.

Ubuntu 24.04's Qt 6.4 is too old for current Quickshell. `dms/install.sh` installs
DMS from its upstream release and a **third-party pkgforge Quickshell AppImage**
under `~/.local/share/awesome-config/dms-1.6.2`. Both downloads have pinned SHA-256
checksums. It extracts the AppImage, so FUSE is unnecessary. Its cross-libc
preloads deadlocked in jemalloc here; the installer moves them aside inside
that private runtime. It changes no system Qt libraries, apt sources, or PAM files.
This is a tested local workaround, not official DMS support for Ubuntu 24.04.

DMS settings are writable copies in `~/.config/DankMaterialShell/settings.json`.
The installer seeds them only if absent; subsequent GUI changes are preserved.
It also seeds the Everblush wallpaper in DMS's state file. DMS app-theme generation
is initially disabled so the repository's `switch-theme` remains authoritative.
Do not use `dms update` for this pinned setup; update the installer and re-test the
runtime as a pair.

## Login and shortcuts

At GDM, select your username, choose **Niri** using the gear, then log in.
Ubuntu/GNOME remains selectable. `Alt+Shift+E` exits Niri back to GDM.

| Key | Action |
| --- | --- |
| `Alt+Return` | Ghostty |
| `Alt+Space` | DMS launcher |
| `Alt+N` | DMS notifications |
| `Alt+V` | DMS clipboard |
| `Alt+,` | DMS settings |
| `Alt+Escape` | DMS lock; standalone locker if DMS is unavailable |
| `Alt+Shift+Slash` | Search all shortcuts through Fuzzel |
| `Alt+H/J/K/L` | Focus windows/monitors |
| `Alt+O` | Niri overview |
| `Alt+Shift+E` | Quit Niri |

## The password screen

The previous plain circle and retry counter came from `niri/lock.sh` using
Swaylock. DMS replaces it with a wallpaper, clock, date, and password field.
It does not replace GDM's login screen or automatically fix rejected passwords.

Defaults select **system PAM authentication**, `/etc/pam.d/login`, preserving
Ubuntu's `common-auth` and SSSD/domain authentication. No password is stored.
DMS's validator accepts the stack; it reports a missing `pam_lastlog.so` in an
optional *session* rule in Ubuntu's login file. That is not evidence of a failed
authentication rule. Actual successful unlock must be tested by the user.

Idle lock is 10 minutes; monitor power-off is 12 minutes; lock before suspend is
enabled. Configure these in DMS settings. Do not also start Swayidle or another
locker in the same session.

## If the real session is blank

Try `Alt+Return`, `Alt+Space`, and `Alt+Shift+E`. Inspect these from a working
terminal or TTY:

```bash
niri validate
journalctl --user -u niri.service -b --no-pager
niri msg outputs  # only from a running Niri session
~/.local/bin/dms doctor
```

Check output names and advertised modes before changing the pinned monitor
blocks. The render GPU is selected by PCI path, not unstable renderD numbering.
A working nested preview does not validate those physical-display settings.
