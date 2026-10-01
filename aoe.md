# Age of Empires II: DE — hotkey plan

Portable hotkey setup for AoE2 DE under Proton, tuned for a **ZSA Voyager** split
keyboard. The goal: bind villager/military/economy actions once, and have them
follow me to any machine.

> Gaming happens in the **GNOME (Wayland)** session, not niri. niri is the work
> session only, so its `Alt`-based keybind policy does not apply here.

## TL;DR

Set hotkeys through the **in-game menu**, not by editing files. Steam Cloud
already syncs the profile, so portability is solved. Use the Voyager for the
parts the game cannot express: a dedicated game layer, and macros.

## Verified facts

Established by inspecting this install (2026-08-21), not from documentation.

| Thing | Value |
|---|---|
| App ID | `813780` |
| Install size | 16.06 GB, `StateFlags 4` (fully installed) |
| Runtime | Proton Experimental + Steam Linux Runtime 4.0 |
| GPU | NVIDIA RTX 5070 Ti, driver 580.173.02 |
| Steam account | `ogre_bane` / Bane24 (`76561199079234556`) |
| Keyboard | ZSA Voyager, USB `3297:1977` |

Profile location (inside the Proton prefix):

```
~/.steam/debian-installation/steamapps/compatdata/813780/pfx/drive_c/users/
  steamuser/Games/Age of Empires 2 DE/76561199079234556/profile/
    ├── Hotkeys.hkp        active profile
    ├── Hotkeys/Base.hkp   profile definition
    ├── AdditionalOptions.aop
    └── Player.nfp
```

### Steam Cloud already carries the hotkeys

The cloud mirror at `userdata/1118968828/813780/remote/` contains
`Hotkeys.hkp` and `Hotkeys/Base.hkp`, byte-identical to the local profile:

```
1b5d2195166cf3aca53edb8859fda0b4  Hotkeys.hkp        (both)
3d18b789e829123828abe512856c5f93  Hotkeys/Base.hkp   (both)
```

**Implication:** set hotkeys once, log in anywhere, they arrive. The path is
keyed to the *account* ID, not the machine.

### Why not edit the files directly

`.hkp` is **raw DEFLATE** (2,160 bytes → 34,342 decompressed, `wbits=-15`)
wrapping an undocumented length-prefixed binary format with tokens like
`HandlerBaseGroupBegin` and `GroupHeaderGuard`. It is readable:

```python
import zlib; zlib.decompress(open('Base.hkp','rb').read(), -15)
```

but not safely writable — no schema, and a patch can change it. Worse, **the
game rewrites this file on exit**, so edits only survive if AoE2 is fully
closed. Since Cloud already gives the portability, hand-editing buys nothing
and risks a reset profile.

## Shipped presets

The game ships four, from `resources/_common/dat/hotkeys.json` (489 KB):

`classic` · `definitive` · `high definition` · `left handed`

There is **no grid preset** — a common misconception. `left handed` is the
interesting one for a split board, because it pulls cycling onto the left hand:

| Action | `definitive` | `left handed` |
|---|---|---|
| `NEXT_IDLE_VILLAGER` | `.` | **`V`** |
| `NEXT_IDLE_MILITARY_UNIT` | `,` | **`B`** |

Everything else sampled was identical. So `left handed` ≈ `definitive` with the
two most-pressed cycle keys moved into the home block.

## Voyager strategy

The Voyager's left half natively covers:

```
 `  1  2  3  4  5
tab Q  W  E  R  T
esc A  S  D  F  G
sft Z  X  C  V  B     + 2 thumb keys
```

AoE2's defaults already live almost entirely in that block — `Q W E R T`,
`A S D F G`, `Z X C V B` for build menus, `1`–`5` for control groups. **The left
half alone can play the game.** That is the whole ergonomic win, and it needs no
firmware work.

What firmware *should* fix — things the in-game menu cannot do:

1. **Control groups 6–0 on the left hand.** Defaults put them on the right half,
   which breaks one-handed play. Put them on a layer over `Q W E R T` or the
   number row.
2. **A dedicated AoE2 layer**, toggled by a thumb key, so the same physical keys
   do game things in game and normal things elsewhere.
3. **Suppress `Super`.** GNOME grabs it for the Activities overview — a stray
   press minimises the game. Map it out of the layer entirely.
4. **Macros** for repeated sequences (select TC → queue villager, or
   idle-villager → build house).

### GNOME keys to avoid

These are intercepted before AoE2 sees them:

| Key | GNOME action |
|---|---|
| `Super` | Activities overview |
| `Alt+Tab` | Window switcher |
| `Alt+F4` | Close window |
| `Ctrl+Alt+←/→` | Switch workspace |
| `Super+1…9` | Dash launch |

Plain `Ctrl+`, `Shift+` and bare letters are free — which is where AoE2 lives, so
conflicts are minimal. Only `Super` and `Alt` need care.

## Plan

- [ ] **1. Start from `left handed`** in Options → Hotkeys. Closest to the
      split-board ergonomics; avoids rebinding ~40 keys by hand.
- [ ] **2. Rebind the high-frequency actions** to the left block:
      `SELECT_ALL_TOWN_CENTERS` (`H`), `NEXT_IDLE_VILLAGER` (`V`),
      `GOTO_SELECTED_OBJECT` (`Space`), `ALL_BACK_TO_WORK` (`V` in TC group).
- [ ] **3. Verify it saved** — quit the game fully, then confirm the profile
      mtime moved and the Cloud copy matches (`md5sum` both).
- [ ] **4. Build the Voyager AoE2 layer** in Oryx: control groups 6–0, `Super`
      removed, thumb-key layer toggle.
- [ ] **5. Snapshot the profile into this repo** as a conflict safety net.
- [ ] **6. Test in a single-player match** before ranked.

## Backup / restore

Cloud sync has one failure mode: two machines writing different profiles, where
Steam picks a winner and the other is lost. A git-tracked snapshot guards it.

```bash
# with AoE2 CLOSED
PROFILE=~/.steam/debian-installation/steamapps/compatdata/813780/pfx/drive_c/users/steamuser/Games/"Age of Empires 2 DE"/76561199079234556/profile
REPO=~/Documents/repo/awesome-config/aoe2

mkdir -p "$REPO"
cp -r "$PROFILE/Hotkeys.hkp" "$PROFILE/Hotkeys" "$REPO/"   # backup
cp -r "$REPO/Hotkeys.hkp" "$REPO/Hotkeys" "$PROFILE/"      # restore
```

Restoring requires the game closed, or it will be overwritten on exit.

## Open questions

- Which actions actually matter to *my* play? The plan above assumes a standard
  eco-heavy opening; worth revisiting after a few games.
- Does the Voyager layer approach beat just using in-game binds? Only for
  control groups 6–0 and macros — everything else the game handles natively.

## Reference

- Action list: `steamapps/common/AoE2DE/resources/_common/dat/hotkeys.json`
- Hotkey groups: `VILLAGER_HOTKEYS` (37), `TOWN_CENTER_HOTKEYS` (18),
  `GAME_COMMAND_HOTKEYS` (25), `CYCLE_COMMAND_HOTKEYS` (25),
  `GROUP_COMMAND_HOTKEYS` (81)
- Oryx (Voyager configurator): <https://configure.zsa.io/>
