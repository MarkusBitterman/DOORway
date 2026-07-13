# CLAUDE.md - AI Assistant Guidelines for DOORway

## Project Overview

**DOORway** is the Hyprland Desktop Environment for [HALLway OS](https://github.com/MarkusBitterman/HALLway). It originated as a fork of [HyDE](https://github.com/HyDE-Project/HyDE) and has been fully rebranded as an independent project adapted for NixOS.

**Important distinction:** DOORway is NOT a "port" of HyDE. It IS DOORway — its own project with its own identity, that happens to share lineage with HyDE. When writing documentation or comments, refer to this project as "DOORway" not "HyDE fork" or "ported from HyDE".

### Philosophy

> **Your desktop should be beautiful, functional, and yours — by default.**

This project follows the HALLway ecosystem principles:
- **User sovereignty** — Configs live in the repo, not scattered across the system
- **Declarative where possible** — Nix flake with Home Manager module
- **Practical over pure** — Bash script fallback for quick setup
- **Fork-friendly** — Easy to customize and extend

## Architecture

```
DOORway/
├── Configs/                    # All dotfiles (the payload)
│   ├── .config/
│   │   ├── hypr/              # Hyprland config (main entry point)
│   │   ├── quickshell/        # QuickShell shell (bar, sidebars, OSD, notifications, session)
│   │   ├── matugen/           # Hyprland border colors from wallpaper (template engine)
│   │   ├── anyrun/            # App launcher + dmenu-style pickers
│   │   ├── doorway/         # DOORway-specific settings
│   │   └── kitty/             # Terminal
│   └── .local/
│       ├── bin/               # doorway-shell, doorwayctl, doorway-ipc
│       ├── lib/doorway/     # 100+ utility scripts
│       ├── share/hypr/        # Session orchestrators (startup, variables, env, dynamic)
│       └── share/doorway/   # Data files, templates
├── flake.nix                  # Nix flake with Home Manager module
└── README.md                  # User documentation
```

## QuickShell Shell Architecture

DOORway's shell surface (Initiative II, Phases 12–16) is a single QuickShell process forked from [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) `ii/` (GPLv3, attribution preserved).

### Surface ownership

| Surface | QML entry point | Wayland layer | Namespace |
|---------|----------------|---------------|-----------|
| Top bar | `modules/ii/bar/Bar.qml` | Top | `quickshell:bar` |
| Right sidebar | `modules/ii/sidebarRight/SidebarRight.qml` | Overlay | `quickshell:sidebarRight` |
| Left sidebar | `modules/ii/sidebarLeft/SidebarLeft.qml` | Overlay | `quickshell:sidebarLeft` |
| OSD | `modules/ii/osd/Osd.qml` | Overlay | `quickshell:osd` |
| Notification popups | `modules/ii/notifications/NotificationPopups.qml` | Overlay | `quickshell:notificationPopups` |
| Session screen | `modules/ii/session/SessionScreen.qml` | Overlay | `quickshell:session` |

All surfaces are loaded by `panelFamilies/IllogicalImpulseFamily.qml` via `PanelLoader`.

### Color theming

QuickShell colors are **committed, not wallpaper-derived**: `modules/common/DoorwayPalette.qml`
is the single source of truth (Nintendo-Power tokens), with two cartridge modes mirroring the
user's website — `dark` (gray NES cart) and `gold` (gold LoZ cart / light). The mode is
persisted at `appearance.palette.mode` in `~/.config/doorway/config.json` and switched by the
`ThemeMode` service (`qs ipc call theme toggleLightDark`, the bar's dark-mode util button,
sidebar quick toggle, or launcher `dark`/`light` actions). `Appearance.qml` maps each mode to
a full Material scheme (`darkScheme`/`goldScheme`).

matugen still runs for one output only: `doorway-matugen-watcher.service` calls
`matugen image <wallpaper>` on wallpaper change (inotifywait) and renders
`~/.local/share/matugen/hyprland-colors.lua` — Hyprland border accent colors
(pcall(dofile)'d by dynamic.lua). The shell does not consume matugen output.

### DOORway Lock (shader-screensaver lock screen)

The lock screen is a QuickShell `WlSessionLock` module (`modules/ii/lock/`,
state machine in `services/DoorwayLock.qml`): signal-cutout intro → rotating
retro-CRT GLSL shaders (ported from the user's website) → NP-styled password
panel over the shader on any key/mouse/controller input → PAM (`login`).
Selected per host via `doorway.lock.backend = "doorway-lock"`; the
`doorway-lock.sh` wrapper **falls back to hyprlock** whenever the shell is
down, and `unlock_cmd` is an IPC call (never pkill — that kills the shell).

- **Shaders**: sources in `assets/shaders/lock/src/`, baked `.qsb` committed.
  After editing GLSL: `nix develop -c ./build.sh` in `assets/shaders/lock/`
  (Qt6 ShaderEffect only loads precompiled `.qsb`; uniforms iTime/iResolution
  [+ progress for signal_cutout] surface as QML properties by name).
- **Testing**: `DOORWAY_LOCK_TEST=1 qs -p <repo config>` opens a floating
  harness window (Ctrl+L lock, Ctrl+N shader, Ctrl+U unlock; real PAM, zero
  lockout risk). A nested instance's WlSessionLock locks the REAL session —
  export `DOORWAY_LOCK_AUTOUNLOCK_SECS=20` for integration tests.
- **Crash recovery**: when the lock client dies the compositor keeps the
  session locked+blank (secure — the desktop is never exposed). A marker at
  `$XDG_RUNTIME_DIR/doorway/locked` makes the restarted shell re-assert the
  lock (Restart=always) so a password prompt returns. **Recovery from TTY**
  (Ctrl+Alt+F2, log in) is a single command:

  ```
  systemctl --user restart doorway-quickshell.service
  ```

  Switch back with Ctrl+Alt+F1. If that TTY can't reach the user bus, prefix
  with `export XDG_RUNTIME_DIR=/run/user/$(id -u)`.

  **`ExitType` gotcha (fixed 2026-07-11):** mkDoorwayService now uses
  `ExitType=main`, not `cgroup`. With `cgroup`, `Restart=always` fires only
  when the whole cgroup empties, so any persistent child that outlives a crash
  wedges recovery — the unit sits `active` with `MainPID=0` forever. This isn't
  just DOORway code: quickshell spawns `nmcli monitor`, which is unremovable,
  so you can't fix it child-by-child — track the main process instead. If a
  wedged unit ever recurs, read
  `/sys/fs/cgroup$(systemctl --user show doorway-quickshell.service -p ControlGroup --value)/cgroup.procs`
  and map PIDs via `/proc/PID/cmdline` to find the orphan. DoorwayLock's own
  long-lived children still self-exit on parent death (defensive), e.g.
  `doorway-lock-controller-watch.sh` polls `kill -0 $PPID`.

### IPC keybindings

Sidebar/session toggles use `qs ipc`. Two workarounds are required for QS 0.3.0:
- `-c doorway` — selects the named config instance (not the "default")
- `--any-display` — bypasses a display-filter bug caused by an empty `instance.lock` file
- `ExecStartPost` in `doorway-quickshell.service` creates `by-id/ipc.sock` → live socket symlink that `qs ipc` resolves to

### Runtime writes

QuickShell's only runtime-written file is its config at `~/.config/doorway/config.json`
(JsonAdapter writeback; the parent dir is real+writable because flake.nix links
`doorway/config.toml` and `doorway/wallbash` individually, not the whole dir).
matugen writes its rendered template to `~/.local/share/matugen/` (writable, not Nix-managed).

## Key Files

| File | Purpose |
|------|---------|
| `Configs/.config/hypr/hyprland.lua` | Main Hyprland config entry point |
| `Configs/.config/hypr/monitors.lua` | Monitor configuration (user edits this — lua format) |
| `Configs/.config/hypr/userprefs.lua` | User preferences (keyboard, etc.) |
| `Configs/.config/hypr/keybindings.lua` | All keybindings |
| `Configs/.local/share/hypr/startup.lua` | exec-once app launch sequence |
| `Configs/.local/share/hypr/variables.lua` | App definitions and session variables |
| `Configs/.local/share/hypr/env.lua` | Environment variable injection into Hyprland |
| `Configs/.local/share/doorway/hyprland.lua` | Core DOORway orchestrator (sources the share/hypr/ files) |
| `Configs/.local/lib/doorway/globalcontrol.sh` | Core environment setup |
| `flake.nix` | Nix flake with homeManagerModules.default |

## Nix Store Workflow — CRITICAL

### Never edit deployed paths directly

Every file under `~/.config/`, `~/.local/bin/`, `~/.local/lib/doorway/`,
`~/.local/share/doorway/`, etc. is either:

- A **symlink into the Nix store** (`/nix/store/…`) — root-owned, epoch-timestamped,
  `EROFS: read-only file system` on any write attempt, OR
- A **generated file** produced by Home Manager at activation time.

**Do not attempt to edit these paths.** The `EROFS` error is the signal, not a
permissions problem to work around. Any tool call that tries to `Edit` or `Write`
a `/nix/store/` path (or a path that symlinks there) will fail immediately.

### Where to make changes

Every deployed file has a 1:1 source in this repo under `Configs/` at the same
relative path:

| Deployed path | Source in this repo |
|---|---|
| `~/.config/hypr/hyprland.lua` | `Configs/.config/hypr/hyprland.lua` |
| `~/.local/share/waybar/` | `Configs/.local/share/waybar/` |
| `~/.local/lib/doorway/waybar.py` | `Configs/.local/lib/doorway/waybar.py` |
| `~/.local/bin/doorway-shell` | `Configs/.local/bin/doorway-shell` |
| `~/.local/share/doorway/hyprland.lua` | `Configs/.local/share/doorway/hyprland.lua` |

**Rule**: When a file needs changing, always edit under `Configs/`, then rebuild.

### Rebuilding after source changes

```bash
sudo nixos-rebuild switch --flake ~/Developments/HALLway/#2600AD
```

The git tree may be dirty — that is expected and harmless during development.

### Identifying Nix store files

```bash
ls -la ~/.config/waybar        # symlink → /nix/store/... → read-only
ls -la ~/.local/lib/doorway/waybar.py  # same pattern
stat ~/.local/lib/doorway/waybar.py   # mtime = Dec 31 1969 (epoch 0) = Nix store
```

Signs a path is Nix-managed:
- `ls -la` shows `-> /nix/store/...`
- File timestamp is `Dec 31  1969` (epoch 0)
- Owner is `root root` with `r--r--r--` permissions

### Runtime writes into config directories

If a script needs to **write data at runtime** (backups, caches, state), it must
NOT write into `~/.config/<app>/` — that directory may be a read-only Nix store
symlink. Use the correct XDG write location:

| Data type | Correct path | Example |
|---|---|---|
| Persistent user data | `$XDG_DATA_HOME` (`~/.local/share/`) | theme state |
| Regeneratable/cache | `$XDG_CACHE_HOME` (`~/.cache/`) | wallbash output, layout backups |
| Runtime state | `$XDG_STATE_HOME` (`~/.local/state/`) | doorway staterc |
| Temp/socket files | `$XDG_RUNTIME_DIR` (`/run/user/<uid>/`) | IPC sockets |

**Caveat:** `$XDG_DATA_HOME/<app>/` may also be a Nix-managed whole-dir symlink
(e.g. `~/.local/share/waybar/` → Nix store). If redirecting from config to data
still hits EROFS, redirect further to `$XDG_CACHE_HOME/doorway/<app>/`.

### Whole-directory vs individual file links in the flake

When `flake.nix` manages a config dir as a single entry:
```nix
"waybar".source = "${configDir}/.config/waybar";   # WHOLE-DIR SYMLINK
```
The entire `~/.config/waybar/` becomes a read-only Nix store symlink. No script
can create files inside it at runtime.

When it uses individual file links (like hypr was migrated to):
```nix
"hypr/hyprland.lua".source = "${configDir}/.config/hypr/hyprland.lua";
"hypr/keybindings.lua".source = ...;
```
Home Manager creates a real `~/.config/hypr/` directory with individual symlinks
inside it — and generated files (`monitors.lua`, `userprefs.lua`) can coexist.

**If a script crashes with `EROFS` writing into `~/.config/<app>/`**, the fix is
one of:
1. Redirect the write to `$XDG_DATA_HOME` or `$XDG_CACHE_HOME` (preferred for
   runtime-generated data that doesn't belong in config), OR
2. Migrate `flake.nix` from whole-dir to individual file links for that app
   (required when generated config files must live alongside source-controlled ones).

**Migration trap (hit 2026-07-02):** converting a whole-dir link to individual
links does NOT clean up by itself. HM's orphan cleanup keeps the old dir symlink
(the path still exists in the new generation — as a real directory now), and link
creation then fails with EROFS trying to back up files inside the stale read-only
symlink, failing the entire activation. Pair the flake change with a transitional
activation entry that `rm`s the old symlink, ordered
`entryBetween [ "linkGeneration" ] [ "writeBoundary" ]` (see
`home.activation.doorwayDirDelink`). Relatedly, any activation script that writes
*inside* an HM-managed directory must be `entryAfter [ "writeBoundary"
"linkGeneration" ]` — with only `writeBoundary`, the DAG tie-break can run it
before the directory exists.

## Working with This Codebase

### Naming Conventions

- **doorway** (lowercase) — paths, variables, file names
- **DOORWAY_** — environment variable prefix
- **DOORway** — branding, documentation, user-facing text
- **doorway-shell** — CLI tools use hyphenated lowercase

### Environment Variables

All DOORway environment variables use the `DOORWAY_` prefix:

```bash
$DOORWAY_CONFIG_HOME   # ~/.config/doorway
$DOORWAY_DATA_HOME     # ~/.local/share/doorway
$DOORWAY_CACHE_HOME    # ~/.cache/doorway
$DOORWAY_THEME         # Current theme name
$DOORWAY_HYPRLAND      # Marker variable in hyprland.lua
```

### doorway-shell Path Architecture

`doorway-shell` resolves `LIB_DIR` relative to its own Nix store path:
- `BIN_DIR` → `<nix-store>/.local/bin/`
- `LIB_DIR` → `<nix-store>/.local/lib/`
- Scripts must live in `$LIB_DIR/doorway/` (NOT `hyde/` — which no longer exists)

`env.lua` injects `~/.local/lib/doorway/` into PATH for Hyprland child processes.
`home.sessionPath` in `flake.nix` covers all other session processes (XFCE, TTY).
The `nix develop` shell also exports this PATH so `launch-unit.sh` works directly.

### Adding New Features

1. **Scripts** go in `Configs/.local/lib/doorway/`
2. **Configs** go in `Configs/.config/<app>/`
3. **Update flake.nix** if adding new config directories

### Flake-based deploy workflow (DOORway → HALLway)

DOORway is a flake input to HALLway. The Nix evaluator fetches the latest
**pushed** commit — local uncommitted changes are completely invisible to it.

```bash
# In this repo (DOORway):
git commit && git push

# In HALLway:
nix flake update doorway   # updates flake.lock to latest pushed commit
sudo nixos-rebuild switch --flake ~/Developments/HALLway/#2600AD
```

**Always commit and push before rebuilding in HALLway.** `nix flake update`
without a prior push will silently reuse the previous commit.

### Three versions of the code exist at any moment

Because DOORway deploys as a Home Manager module through HALLway's flake.lock,
there are always three potentially-different versions in play:

1. **Working tree** — what you just edited under `Configs/`
2. **Pushed HEAD** — what `nix flake update doorway` will fetch
3. **Deployed generation** — what the running session actually executes

**Before interpreting any runtime symptom, establish which version produced it:**

```bash
diff ~/.config/quickshell/doorway/path/to/File.qml \
     ~/Developments/DOORway/Configs/.config/quickshell/doorway/path/to/File.qml \
  && echo "deployed == working tree"
```

A fix that "doesn't work" is usually a fix that isn't deployed yet — not a wrong
fix. Do not debug the old code's behavior against the new code's expectations.

Two practical consequences:
- `sudo nixos-rebuild switch` needs the user's password — hand it off
  (suggest they run `! sudo nixos-rebuild switch --flake ~/Developments/HALLway/#2600AD`).
- After a switch, `systemctl --user restart doorway-quickshell.service` (and
  similar user services) so they pick up the new store paths — HM does not
  reliably restart them.

### Services carry their environment — your shell does not

HM-generated systemd user units inject Nix store paths via `Environment=` that
exist nowhere else. Example: `doorway-quickshell.service` sets
`QML_IMPORT_PATH=<qt5compat-store-path>/lib/qt-6/qml`; without it, any `qs`
launched from a plain shell fails with `module "Qt5Compat.GraphicalEffects" is
not installed` even though the deployed shell runs fine.

**A program that works as a service but fails in your shell (or vice versa) is
an environment problem, not a code problem.** Recover the service's exact env:

```bash
systemctl --user show doorway-quickshell.service -p ExecStart -p Environment
```

### Testing QuickShell repo sources without a rebuild

Run a second instance directly against the working tree (borrow the env var
from the service as above):

```bash
QML_IMPORT_PATH=<from-service> qs -p ~/Developments/DOORway/Configs/.config/quickshell/doorway
```

- The nested instance and the deployed one **overlap at identical screen
  coordinates**. Before screenshotting (`grim -g "X,Y WxH" out.png`), stop the
  deployed service so you know which instance you're looking at — then restart it.
- Drive the nested instance's IPC with the same `-p` path:
  `qs -p <repo path> ipc --any-display call sidebarRight open`
- QuickShell hot-reloads QML file changes, but a hot reload initializes
  differently than a cold start (theme colors already settled, windows already
  created). **Bugs that only manifest on cold start — first-paint color capture,
  race-dependent init — are masked by hot reload.** Always verify with a fresh
  instance launch, not a reload.

### Testing Changes

Configs in `Configs/.config/hypr/` use Hyprland 0.55+ lua format (`hl.config`, `hl.bind`, `hl.window_rule`). `hyprctl reload` works the same on lua configs as it did on hyprlang.

```bash
# After nixos-rebuild switch — smoke-test the deployed config for type errors:
Hyprland --verify-config

# To verify SOURCE files before rebuilding (temporarily redirects system module symlinks):
orig_hypr=$(readlink ~/.local/share/hypr)
orig_dw=$(readlink ~/.local/share/doorway)
ln -sfn "$HOME/Developments/DOORway/Configs/.local/share/hypr" ~/.local/share/hypr
ln -sfn "$HOME/Developments/DOORway/Configs/.local/share/doorway" ~/.local/share/doorway
Hyprland --verify-config 2>&1
ln -sfn "$orig_hypr" ~/.local/share/hypr
ln -sfn "$orig_dw" ~/.local/share/doorway

# Full dev environment
nix develop
shellcheck Configs/.local/lib/doorway/*.sh
```

## Upstream Relationship

DOORway is forked from HyDE. When referencing upstream:
- Keep GitHub URLs pointing to HyDE-Project for attribution
- Use "forked from HyDE" in comments where appropriate
- Don't rename upstream references in theme files

## Common Tasks

### Rebrand a new upstream merge

If pulling changes from HyDE upstream:
```bash
# After merge, fix branding
find . -type f \( -name "*.sh" -o -name "*.conf" \) -exec sed -i 's/hyde/doorway/g' {} +
find . -type f \( -name "*.sh" -o -name "*.conf" \) -exec sed -i 's/HYDE_/DOORWAY_/g' {} +
# Review changes carefully - some hyde references should stay (URLs, attribution)
```

Note: these `*.conf` sed commands no longer apply to the lua files in `Configs/.config/hypr/` (which DOORway now owns and maintains directly). The commands are still safe to run — they simply won't match much in the hypr/ tree anymore. Lua-side rebranding should be done by hand or with a separate `-name "*.lua"` pass if upstream ever adopts lua.

### Add a new config directory

1. Add to `Configs/.config/<newdir>/`
2. Add to `flake.nix` in `xdg.configFile`

### Debugging a Hyprland Session (Empty Desktop)

If Hyprland starts but shows only a cursor with no bar or wallpaper:

0. **Parse the config first** — catches type errors and nil-function calls without a
   running session. Prints to stdout; no Error Overlay required:
   ```bash
   Hyprland --verify-config
   ```
   Common migration errors: `"on"`/`"off"` where a `bool` is required, a Lua table
   where a `string` is required, or calling a nil `hl.*` function (e.g. `hl.keyword`).

1. **Hyprland log** — Lua config errors appear in the Error Overlay (on-screen) but
   are NOT reliably written to the log file. The log is most useful for exec-once and
   backend errors, not config parse errors. When in doubt, use step 0 instead.
   ```bash
   cat /run/user/$(id -u)/hypr/*/hyprland.log | grep -v "DEBUG from aquamarine"
   ```

2. **exec-once failures** — silent in the Hyprland log; check journalctl:
   ```bash
   journalctl --user -b -n 200 | grep -iE "(waybar|quickshell|doorway|hypr)"
   ```

3. **Check for EROFS crashes in startup scripts** — `waybar.py`, `wallpaper.sh`, etc.
   may crash silently if they try to write inside a whole-dir Nix store symlink
   (`~/.config/waybar/`, etc.). See **Nix Store Workflow** section above.
   Quick test: `~/.local/lib/doorway/launch-unit.sh -u doorway-Hyprland-bar.scope -t scope -- waybar.py --watch`
   and check `/tmp/doorway-bar-launch.log` for a Python traceback.

4. **Sanity-check launch-unit.sh** without logging out (from XFCE Wayland or `nix develop`):
   ```bash
   export PATH="$HOME/.local/lib/doorway:$PATH"
   export XDG_SESSION_DESKTOP=Hyprland
   export XDG_CURRENT_DESKTOP=Hyprland
   launch-unit.sh -u test.scope -t scope -- echo "ok"
   ```

5. **Nested Hyprland** (`start-hyprland` inside a Wayland compositor) — visual checks only.
   Keyboard is dead in nested mode: libseat's builtin backend cannot open `/dev/input/*`.
   This is expected, not a DOORway bug.

### Working with logs

The journal is the primary diagnostic instrument for the QuickShell surface —
start there, not with code reading:

```bash
# The one command that surfaces most UX defects:
journalctl --user -u doorway-quickshell.service -b --no-pager | grep -vE "DEBUG|INFO"
```

**Treat warnings as load-bearing, not noise.** Nearly every UX defect found in
the 2600.7.2 review had been announcing itself in the journal for weeks:

- `Could not load icon "name?fallback=file://..."` — an icon request whose
  fallback never resolves; the on-screen result is a black/purple placeholder
  that loads as `Image.Ready` (no error anywhere else).
- `Ignoring unresolvable import "..."` (qmlscanner) — a dead import; the file
  either shouldn't exist or is missing a dependency lost in a port.
- `ReferenceError: X is not defined` — a QML component referencing a service
  that was removed; the feature it feeds is silently dead.
- `Read of <path> failed: File does not exist` (FileView) — a config/state file
  the code expects but nothing generates.
- `Process failed to start ... Command: QList("tool", ...)` — a runtime tool the
  QML shells out to that isn't in the Nix closure; the feature falls back or dies.

**Warnings double as version watermarks.** Warning text is emitted by specific
code paths, so the journal tells you *which version is running*: e.g. seeing
`?fallback=file://` warnings after the CustomIcon fix means the old code is
still deployed (see "Three versions" above).

**Per-instance QuickShell logs** live in `/run/user/$(id -u)/quickshell/by-id/<id>/log.log`.
One dir per launch; `ExecStartPre` prunes dirs older than 10 minutes. Find the
live instance's dir through its open fds, not by newest-mtime (races against
nested test instances):

```bash
pid=$(systemctl --user show doorway-quickshell.service -p MainPID --value)
ls -l /proc/$pid/fd | grep -o "by-id/[^/]*" | head -1
```

**QML failure modes are silent by design** — placeholder textures load
"successfully", scanners "ignore" broken imports, `Connections` warn instead of
erroring. The screen can look 90% fine while the journal lists every defect.
Skim `journalctl --user -u doorway-quickshell -b -p warning` after any shell
change, and diff the warning set before/after a deploy.

## Documentation Hygiene

A 2026-07-13 reconciliation pass found 7 weeks of drift: TESTING.md prescribed a
removed command, the wiki documented a setup script that never existed, DOORway
Lock shipped against an unchecked TODO item, and CHANGELOG.md was frozen at
v26.5.22. Rules to keep the docs true:

**Docs update in the same commit as the change.** A feature isn't done until its
TODO.md checkbox is flipped and every doc that names the old behavior is updated.

**Doc map — what to touch when:**

| Change | Docs to update |
|---|---|
| Module option added/changed (`doorway.*`) | README § Module Options Reference |
| Keybind added/changed | KEYBINDINGS.md + `Wiki/Keybindings-Primer.md` (regenerate the affected tables from `keybindings.lua` — its `[Group\|Sub]` descriptions are the source of truth; don't patch ad hoc) |
| Component added/replaced/removed | README § Components + `Wiki/Introduction.md` table + `Wiki/Interface-Tour.md` |
| Initiative/arc completes | CHANGELOG.md entry at completion — never backfilled weeks later |
| Testing/deploy workflow changes | TESTING.md (+ this file) |
| Shell surface redesigned | `Wiki/Interface-Tour.md` + the CLAUDE.md surface-ownership table above |

**Never document a command without verifying it exists** (run it, or check the
script/subcommand is still present). Confidently-wrong prescriptions are worse
than missing docs — the removed `doorway-shell app` subcommand sat as step 1 of
TESTING.md's sanity checks for weeks.

**One canonical home per open TODO item.** If an item must be mentioned twice,
the second mention is a pointer ("tracked in X"), not a duplicate checkbox.

**Drift detector** — retired-tool names appearing in docs outside historical
notes mean a doc pass is due; extend the pattern when another tool is retired:

```bash
grep -rn -iE "waybar|dunst|\brofi\b|wlogout|swww|hyde-shell|hydectl" \
  README.md KEYBINDINGS.md TESTING.md Wiki/*.md
```

## Code Style

- **Shell scripts**: Use `shellcheck`, prefer `[[ ]]` over `[ ]`
- **Nix**: Use `nixfmt` (`nixfmt flake.nix`)
- **Python**: Use `ruff` (`ruff check --fix` or `ruff format`)
- **Configs**: Follow upstream HyDE style for consistency
- **Comments**: Explain *why*, not *what*

## Integration with HALLway

DOORway is designed to be imported into HALLway's flake:

```nix
# In HALLway's flake.nix inputs:
doorway.url = "github:MarkusBitterman/DOORway";

# In home-manager config:
imports = [ inputs.doorway.homeManagerModules.default ];
doorway = {
  enable = true;
  monitor = "HDMI-A-1,1920x1080@100,0x0,1";
  keyboard = "us";
};
```

The flake exposes `lib.doorwayDeps` so HALLway can reference the same package list.
