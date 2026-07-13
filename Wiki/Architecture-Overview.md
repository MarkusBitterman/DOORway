# Architecture Overview

This article is the map of how DOORway fits together at runtime: the lua config
chain that boots Hyprland, the single QuickShell process that draws every visible
surface, the declarative systemd units that run everything else, and the IPC
topology that ties keybindings to the shell.

If you're trying to *change* something and want to know which file owns it, this
is the article. For the read-only user's-eye view, see
[Interface-Tour.md](Interface-Tour.md); for the Nix deployment mechanics, see
[Using-DOORway-with-Nix.md](Using-DOORway-with-Nix.md).

---

## The three runtime layers

DOORway at runtime is three cooperating layers, not one monolith:

1. **Hyprland** — the compositor, configured entirely in lua. Owns window
   management, animations, keybindings, window/layer rules, and env vars.
2. **QuickShell** — one QML/Qt6 process (`doorway-quickshell.service`) that draws
   the bar, both sidebars, OSD, notifications, session screen, and lock.
3. **The systemd user-unit fleet** — declarative units in `flake.nix` for every
   daemon that used to be an `exec-once` (clipboard, tray applets, idle, wallpaper,
   matugen watcher, blue-light, polkit).

The historically important fact: **Hyprland launches almost none of this.** After
the de-HyDE migration (TODO.md Phase 9), Hyprland's startup hook runs exactly one
command — `hyprctl setcursor`. Everything else is a systemd unit tied to
`graphical-session.target`, which UWSM activates with Hyprland's environment.

---

## The lua config chain

Hyprland reads one entry point and `require()`s a fixed chain of modules. Two
files bootstrap it:

```
~/.config/hypr/hyprland.lua                 (user entry — you may edit this)
    ├── require("monitors")                 generated from doorway.monitor
    ├── require("userprefs")                generated from doorway.keyboard
    ├── dofile(".../windowrules.lua")       user window rules (dofile: see note)
    ├── require("keybindings")              all keybinds
    └── dofile(~/.local/share/doorway/hyprland.lua)   ← core orchestrator
            ├── require("env")              env vars (child processes inherit)
            ├── require("variables")        shared data module (returns a table)
            ├── require("defaults")         monitor fallback, decoration, input, layouts
            ├── require("windowrules")      core DOORway window rules
            ├── require("dynamic")          matugen border colors + groupbar config
            ├── require("startup")          the lone hyprctl setcursor
            ├── require("workflows")        active workflow preset
            └── require("finale")           doorway:* custom keywords (must be last)
```

**Load order is load-bearing.** `env` first so child processes inherit the
environment; `variables` early because later modules `require` it (lua caches the
returned table, so it's a shared singleton); `finale` last because its custom
keywords must be set after everything else.

**Why `dofile` for user `windowrules.lua`:** the orchestrator also has a module
named `windowrules`. `require` caches by module name, so a second `require("windowrules")`
would return the *first* file's cached table. `dofile` runs the file fresh,
avoiding the collision. Same reason the core entry is `dofile`'d, not `require`'d.

**Source locations** (edit these, then rebuild):

| Module | Repo source |
|---|---|
| User entry | `Configs/.config/hypr/hyprland.lua` |
| Core orchestrator | `Configs/.local/share/doorway/hyprland.lua` |
| `env`, `variables`, `defaults`, `windowrules`, `dynamic`, `startup`, `finale` | `Configs/.local/share/hypr/*.lua` |
| `keybindings`, user `windowrules` | `Configs/.config/hypr/*.lua` |
| `monitors`, `userprefs`, `doorway-{cursor,fonts,theme,animation-preset}` | **generated** by `flake.nix` from `doorway.*` options |

`variables.lua` is now a pure data module (returns a table) — the de-HyDE passes
stripped it of its `app()` launcher helper and `start` daemon table. It's still
read by runtime scripts via `get_hyprConf()`.

---

## The QuickShell surface

One process, six Wayland surfaces. All are loaded by
`panelFamilies/IllogicalImpulseFamily.qml` via `PanelLoader`.

| Surface | QML entry point | Layer | Namespace |
|---|---|---|---|
| Top bar | `modules/ii/bar/Bar.qml` | Top | `quickshell:bar` |
| Right sidebar | `modules/ii/sidebarRight/SidebarRight.qml` | Overlay | `quickshell:sidebarRight` |
| Left sidebar | `modules/ii/sidebarLeft/SidebarLeft.qml` | Overlay | `quickshell:sidebarLeft` |
| OSD | `modules/ii/osd/Osd.qml` | Overlay | `quickshell:osd` |
| Notifications | `modules/ii/notifications/NotificationPopups.qml` | Overlay | `quickshell:notificationPopups` |
| Session screen | `modules/ii/session/SessionScreen.qml` | Overlay | `quickshell:session` |
| Lock | `modules/ii/lock/` (`WlSessionLock`) | (session lock) | `quickshell:lock` |

The namespaces matter because `windowrules.lua` targets them with layer rules
(blur, ignorezero). If a surface loses its blur, check the `hl.layer_rule` match
string against the namespace above.

Services (reactive state, D-Bus, subprocess wrappers) live under
`services/` and `modules/common/`. The color system is `modules/common/DoorwayPalette.qml`
+ `Appearance.qml` — see [Theming.md](Theming.md).

Forked from [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) `ii/`
(GPLv3, attribution preserved) — hence the `ii/` subtree name.

---

## The systemd unit fleet

Everything that isn't Hyprland or the shell is a declarative user unit, built by
two `flake.nix` helpers:

- **`mkDoorwayService`** — long-running daemons (`Type=exec`, `ExitType=main`,
  `Restart=always`, `PartOf=graphical-session.target`).
- **`mkDoorwayOneshot`** — bootstrap steps (`Type=oneshot`, `RemainAfterExit=true`).

Key units:

| Unit | Command | Slice |
|---|---|---|
| `doorway-quickshell` | the shell (gated by `shell.enable`) | app-graphical |
| `doorway-matugen-watcher` | `inotifywait` on `wall.set` → `matugen image` + `hyprctl reload` | app-graphical |
| `doorway-anyrun` | `anyrun daemon` | app-graphical |
| `doorway-wallpaper` | `wallpaper.sh --start --global` | app-graphical |
| `doorway-text-clipboard` / `doorway-image-clipboard` | `wl-paste --watch cliphist store` | app-graphical |
| `doorway-{network-manager,bluetooth,removable-media}-applet` | tray applets | app-graphical |
| `doorway-idle` / `doorway-blue-light-filter` | hypridle / hyprsunset | app-graphical |
| `doorway-polkit-auth` | polkit-gnome agent | (oneshot-adjacent) |

**`ExitType=main` is critical** (CLAUDE.md documents the gotcha): with
`ExitType=cgroup`, `Restart=always` only fires when the whole cgroup empties, so
any child that outlives a crash (quickshell spawns an unremovable `nmcli monitor`)
wedges recovery — the unit sits `active` with `MainPID=0` forever.

Diagnose the fleet with `systemctl --user --failed` and
`journalctl --user -u doorway-quickshell.service`.

---

## IPC topology

Keybindings and scripts drive the shell through QuickShell's IPC. The pattern in
`keybindings.lua` is:

```
qs -c doorway ipc --any-display call <target> <function>
```

Three flags are load-bearing on QS 0.3.0 (CLAUDE.md § IPC keybindings):
`-c doorway` selects the named config instance; `--any-display` bypasses a
display-filter bug from an empty `instance.lock`; and `doorway-quickshell.service`'s
`ExecStartPost` maintains a `by-id/ipc.sock` symlink that `qs ipc` resolves.

**IPC targets** (each is an `IpcHandler { target: "..." }` in the QML):

| Target | Functions | Defined in |
|---|---|---|
| `bar` | `toggle` `open` `close` | `modules/ii/bar/Bar.qml` |
| `sidebarRight` | `toggle` `open` `close` | `modules/ii/sidebarRight/SidebarRight.qml` |
| `sidebarLeft` | `toggle` `open` `close` | `modules/ii/sidebarLeft/SidebarLeft.qml` |
| `sessionScreen` | `open` `close` `toggle` | `modules/ii/session/SessionScreen.qml` |
| `theme` | `toggleLightDark` `setMode` `getMode` | `services/ThemeMode.qml` |
| `brightness` | `increment` `decrement` | `services/Brightness.qml` |
| `mpris` | `playPause` `pauseAll` `next` `previous` | `services/MprisController.qml` |
| `cliphistService` | `update` | `services/Cliphist.qml` |
| `wallpapers` | `apply` | `services/Wallpapers.qml` |
| `crtShader` | (shader control) | `services/DoorwayCrtShader.qml` |
| `lock` | `lock` `unlock` `wake` `nextShader` `status` `devType` `devSubmit` | `services/DoorwayLock.qml` |

**Gotcha (CLAUDE.md):** IPC singletons like these are lazy in QuickShell — some
need an eager touch from `shell.qml` to register their handler at startup. If an
IPC call reports "no such target," check the singleton is instantiated eagerly.

**Never `pkill` the shell to toggle a surface** — that kills every surface. The
lock screen's `unlock_cmd` is an IPC call for exactly this reason.

---

## doorway-shell

One binary sits in front of the runtime: **`doorway-shell`** (`~/.local/bin/`) —
the script dispatcher. It resolves its lib dir relative to its own Nix store path,
sources `globalcontrol.sh`, and dispatches `doorway-shell <name> [args]` to a
script found on `DOORWAY_SCRIPTS_PATH`. This is what keybindings and services
shell out to. See [Scripting-API.md](Scripting-API.md).

> The repo formerly also shipped `doorwayctl` and `doorway-ipc` — prebuilt
> upstream HyDE binaries (`hydectl` and khing's `hyde-ipc`), never rebuilt or
> called by anything in DOORway. They were deleted 2026-07-13. See
> [Scripting-API.md § removed binaries](Scripting-API.md#removed-the-vestigial-hyde-binaries).

---

## Where to go next

- **Theming internals** → [Theming.md](Theming.md)
- **The script surface** → [Scripting-API.md](Scripting-API.md)
- **Every keybind** → [Keybindings-Reference.md](Keybindings-Reference.md)
- **The `hl.*` API this repo uses** → [Hyprland-Lua-API-Cheatsheet.md](Hyprland-Lua-API-Cheatsheet.md)
- **Why the config is lua at all** → [Lua-Migration-Notes.md](Lua-Migration-Notes.md)
- **Contributor rules, Nix store workflow, log discipline** → [CLAUDE.md](../CLAUDE.md)
