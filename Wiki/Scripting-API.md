# Scripting API

DOORway's runtime scripting surface is one binary and a library of scripts:
`doorway-shell` (the dispatcher) in front of ~100 scripts under
`~/.local/lib/doorway/`. This article documents how the dispatch works, the
environment contract every script relies on, and how to add your own.

For where this sits in the bigger picture, see
[Architecture-Overview.md](Architecture-Overview.md).

---

## `doorway-shell`

`doorway-shell` is the front-end that keybindings and systemd services shell out
to. It does three jobs: resolve DOORway's paths, source the shared environment,
and dispatch to a script by name.

### Invocation forms

```
doorway-shell <script-name> [args...]   # run a lib script by basename (no extension)
doorway-shell <builtin> [args...]       # a built-in subcommand
```

Example — these are literally how the keybindings call it:

```bash
doorway-shell screenshot s              # runs screenshot.sh with arg "s"
doorway-shell volumecontrol -q -o i     # runs volumecontrol.sh
doorway-shell wallpaper -Gn             # runs wallpaper.sh
```

### Built-in subcommands

| Command | What it does |
|---|---|
| `help`, `-h`, `--help` | Usage banner |
| `-s`, `scripts` | List available scripts, formatted |
| `--list-script` | List script names (plain) |
| `--list-script-path` | List script names with full paths |
| `wallbash <script>` | Run a wallbash script via `call_wallbashScript` |
| `completions [bash\|zsh\|fish]` | Generate shell completions |
| `init`, `--init` | Print the init block (for `eval "$(doorway-shell init)"`) |
| `logout` | `doorway-logout` |
| `lock-session` | Lock the session |

Anything not matching a built-in falls through to `run_command "$@"`, which
searches `DOORWAY_SCRIPTS_PATH` for a script whose basename (minus extension)
matches the first argument.

### How it finds itself (Nix-store-safe)

`doorway-shell` never hardcodes paths. It derives them from its own location:

```
BIN_DIR=$(dirname "$(which "${EXECUTABLE:-doorway-shell}")")   # resolves through PATH to the store
LIB_DIR=$(realpath "${BIN_DIR}/../lib")                        # ../lib within the closure
SHARE_DIR=$(realpath "${BIN_DIR}/../share")
```

`which` resolves through PATH to the actual `/nix/store/...` path, and `realpath`
navigates the sibling `lib`/`share` dirs inside the same closure. This is why the
same script works whether it's run from the store, a `nix develop` shell, or a
keybinding.

### `DOORWAY_SCRIPTS_PATH`

The colon-separated search path `run_command` walks. Default:

```
$XDG_CONFIG_HOME/doorway/scripts : $LIB_DIR/doorway
```

The user-overridable `$XDG_CONFIG_HOME/doorway/scripts` comes first so you can
shadow a shipped script with your own. Nonexistent entries are skipped.

> Cleaned up 2026-07-13: the default used to append `waybar/scripts` paths left
> over from the pre-QuickShell era. Those directories no longer exist and were
> removed from the default.

---

## The `DOORWAY_SHELL_INIT` guard

Most lib scripts need DOORway's environment (XDG dirs, `globalcontrol.sh`
functions like `get_hyprConf`, theme state). Rather than each re-sourcing it, they
guard on a single variable at the top:

```bash
[[ $DOORWAY_SHELL_INIT -ne 1 ]] && eval "$(doorway-shell init)"
```

`doorway-shell init` prints the exported environment plus the contents of
`globalcontrol.sh`; the guard makes re-sourcing a no-op once it's set. 30+ lib
scripts use this pattern. If you write a new script that needs the DOORway
environment, start with that line.

---

## The script library (`~/.local/lib/doorway/`)

~100 scripts, mostly `*.sh` plus a few Python helpers. The load-bearing ones the
keybindings and services call directly:

| Script | Purpose |
|---|---|
| `globalcontrol.sh` | Core environment + shared functions (sourced, not run) |
| `wallpaper.sh` | Wallpaper selection + awww backend + matugen trigger |
| `screenshot.sh` | Region / window / full capture (grim + slurp + satty) |
| `volumecontrol.sh` | Volume/mic with OSD feedback |
| `brightnesscontrol.sh` | Backlight (brightnessctl) + external monitors (ddcutil) |
| `cliphist.sh` | Clipboard history picker |
| `anyrun-dmenu.sh` | dmenu-style picker on anyrun — backs every menu flow |
| `window-switcher.sh` / `file-finder.sh` | MRU window switch / `fd`-backed file open |
| `keybinds_hint` (`hint-hyprland.py`) | Searchable keybind index from `keybindings.lua` |
| `gamemode` / `gamelauncher.sh` | Low-latency mode / game launcher |
| `emoji-picker` / `glyph-picker` | anyrun emoji / Unicode pickers |

Source of truth for the full list: `ls Configs/.local/lib/doorway/` in the repo,
or `doorway-shell -s` at runtime.

---

## Removed: the vestigial HyDE binaries

Until 2026-07-13 the repo also shipped two binaries in `~/.local/bin/`:

- **`doorwayctl`** — upstream HyDE's **`hydectl`** (a Bubble Tea TUI + Hyprland
  dispatcher, `hydectl` Go module, version `r45.5b3a9cc`). Committed as a 13 MB
  prebuilt binary, never rebuilt or rebranded — it still identified as `hydectl`
  and shelled out to `hyde-shell`, which doesn't exist in DOORway, so it would
  fail if run.
- **`doorway-ipc`** — [`github.com/khing/hyde-ipc`](https://github.com/khing/hyde-ipc),
  a Hyprland IPC event listener / config watcher. Another prebuilt binary carried
  over opaquely.

Both were **renamed at the filename level only**, were **not built from source**
in this repo, and had **zero callers** anywhere in `Configs/`. `doorwayctl` was
even invoked (and silently failing) at every zsh startup via a completion stub.
They were deleted along with the completion and their `flake.nix` entries.

**If DOORway ever wants a TUI dispatcher or an IPC event tool**, the right move is
to build it from source through the flake (the declarative-and-ours principle),
not to re-vendor a prebuilt upstream binary. The runtime IPC that DOORway
*actually* uses today is QuickShell's `qs ipc` — see
[Architecture-Overview § IPC topology](Architecture-Overview.md#ipc-topology).

---

## Adding a script

1. Drop `myscript.sh` in `Configs/.local/lib/doorway/`.
2. If it needs the DOORway environment, start with the `DOORWAY_SHELL_INIT` guard.
3. `shellcheck` it (`shellcheck Configs/.local/lib/doorway/myscript.sh`).
4. Rebuild. Call it as `doorway-shell myscript [args]`.
5. Bind it in `Configs/.config/hypr/keybindings.lua` if it's user-facing.

Remember the Nix-store rule: scripts must not write into `~/.config/<app>/`
(read-only store symlinks). Use `$XDG_DATA_HOME` / `$XDG_CACHE_HOME` /
`$XDG_STATE_HOME` for runtime writes. See [CLAUDE.md § Nix Store Workflow](../CLAUDE.md#nix-store-workflow--critical).

---

## What to read next

- **The runtime map** → [Architecture-Overview.md](Architecture-Overview.md)
- **The keybinds that call these scripts** → [Keybindings-Reference.md](Keybindings-Reference.md)
- **Contributor rules** → [CLAUDE.md](../CLAUDE.md)
