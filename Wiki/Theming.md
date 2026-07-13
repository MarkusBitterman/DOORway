# Theming

DOORway's color story is deliberately split into two independent systems. Getting
this distinction right is the whole article, so here it is up front:

- **The shell** (bar, sidebars, OSD, notifications, lock) uses a **committed
  palette** — two hand-authored "cartridge" schemes that do *not* change with the
  wallpaper. You switch between them (light/dark) explicitly.
- **Hyprland's window borders** use **matugen** — Material You accent colors
  extracted from the current wallpaper, regenerated on every wallpaper change.

This is a reversal of the usual Hyprland-dotfiles convention (where the wallpaper
drives everything). It's intentional: DOORway has a signature look, and the shell
commits to it rather than dissolving into whatever wallpaper is loaded.

> Historical note: this replaced the inherited **wallbash** pipeline, which was
> blocked anyway — Hyprland 0.55's lua API has no `hl.source()` to consume
> wallbash's hyprlang color files at runtime. See
> [Lua-Migration-Notes.md](Lua-Migration-Notes.md) and
> [Troubleshooting § the missing hl.source](Troubleshooting-Hyprland.md).

---

## System 1: the committed cartridge palette (shell)

### The single source of truth

`Configs/.config/quickshell/doorway/modules/common/DoorwayPalette.qml` holds every
brand color. The tokens are named after the Nintendo-Power / retro-cartridge
identity from the user's website — `powerRed`, `powerGold`, `heroBlue`,
`koholintGrass`, `agedPaper`, and so on.

### Two cartridge modes

One boolean drives everything:

```qml
readonly property bool goldCart:
    (Config.options?.appearance?.palette?.mode ?? "dark") === "gold"
```

| Mode | Cartridge | Character |
|---|---|---|
| `"dark"` | gray NES cart | dark plastic wells, default |
| `"gold"` | gold Zelda cart | light mode — warm gold plastic |

Many tokens are mode-aware — they resolve differently per cartridge so the same
semantic color reads correctly on either background:

```qml
readonly property color redBright:  goldCart ? powerRed  : "#FF5C4A"
readonly property color netAccent:  goldCart ? heroBlue  : skyHint
readonly property color plasticShellTop:    goldCart ? "#D6BF71" : "#2C2822"
readonly property color bevelHighlight:     goldCart ? Qt.rgba(1,1,1,0.35) : Qt.rgba(1,1,1,0.06)
```

The **woodgrain shell** (Black Walnut bar / right-sidebar background) is
mode-*independent* — walnut in both modes. Only the *wells* set into it (BarGroup,
sidebar cards) flip with the cartridge. That's the "Black Walnut design law" from
the overhaul: the wood is the shell, the plastic is the theme.

### From palette to Material scheme

`modules/common/Appearance.qml` maps the cartridge mode to a full Material 3 color
scheme, so the ported end-4 components (which expect `m3primary`, `m3surface`,
`colLayer0`…`colLayer4`, etc.) work unchanged:

```qml
property QtObject m3colors: DoorwayPalette.goldCart ? goldScheme : darkScheme
readonly property QtObject darkScheme: QtObject { /* gray-cart M3 tokens */ }
readonly property QtObject goldScheme: QtObject { /* gold-cart M3 tokens */ }
```

So the layering is: **cartridge mode → `DoorwayPalette` tokens →
`Appearance.{dark,gold}Scheme` → every component's `colLayerN` / `colPrimary`.**

### Switching modes

The mode persists at `appearance.palette.mode` in `~/.config/doorway/config.json`
(JsonAdapter writeback — this is the one runtime-written shell file). Switch it via:

| Method | How |
|---|---|
| Bar util button | the dark-mode button on the top bar |
| Right sidebar | the light/dark quick toggle |
| Launcher | type `dark` or `light` into anyrun (`SUPER + A`) |
| IPC | `qs -c doorway ipc --any-display call theme toggleLightDark` (`getMode` returns the current one) |

The `theme` IPC target is `services/ThemeMode.qml`.

---

## System 2: matugen (Hyprland borders)

matugen runs for exactly **one** output: Hyprland's window-border accent colors.
The shell does not consume it.

### The pipeline

1. `wallpaper.sh` sets the wallpaper and touches `~/.cache/doorway/wall.set`.
2. `doorway-matugen-watcher.service` (`inotifywait -e moved_to,create`) fires.
3. `matugen image <wallpaper>` renders the template.
4. `dynamic.lua` does `pcall(dofile, "~/.local/share/matugen/hyprland-colors.lua")`
   and `hyprctl reload` picks up the new border colors.

### The config

`Configs/.config/matugen/config.toml`:

```toml
[config]
reload_apps = false                    # DOORway drives its own hyprctl reload

[templates.hyprland-colors]
input_path  = "~/.config/matugen/templates/hyprland-colors.lua"
output_path = "~/.local/share/matugen/hyprland-colors.lua"
mode = "Dark"
```

The template (`templates/hyprland-colors.lua`) is a Tera template that writes
`hl.config({ general = { col = { active_border = "rgba(<hex>ee)", ... } } })`.
Template variables use matugen's `{{colors.primary.default.hex_stripped}}` form
(rrggbb, no `#`) — verify against `matugen --help` if you upgrade matugen, since
the 3.x → 4.x key names shifted.

### If borders stop following the wallpaper

```bash
systemctl --user status doorway-matugen-watcher.service
ls -l ~/.local/share/matugen/hyprland-colors.lua   # should update on wallpaper change
```

The rendered file is written to `~/.local/share/matugen/` (writable, not
Nix-managed). If it's missing, the watcher never ran or matugen errored — check the
journal.

---

## Static theme settings (declarative, not runtime)

GTK theme, icon theme, cursor, and fonts are *not* part of either dynamic system —
they're the same on every session, so they're declarative Nix options (Pass 11 of
the de-HyDE migration lifted them out of the old imperative `theme.switch.sh`):

| Setting | Where |
|---|---|
| GTK theme / icon theme / fonts | HM `gtk.*` + `doorway.theme.iconTheme` + `doorway.fonts.*` |
| Cursor | `doorway.cursor.{package,name,size}` (→ `home.pointerCursor`) |
| Qt/Wayland toolkit env | `home.sessionVariables` |
| `color-scheme` (dconf) | `dconf.settings."org/gnome/desktop/interface"` |

Change these in your Home Manager config and rebuild — there's no runtime switcher
for them (single-theme focus; DOORway ships one look, in two cartridge modes).

---

## What to read next

- **The surfaces these colors paint** → [Interface-Tour.md](Interface-Tour.md)
- **How the shell process is structured** → [Architecture-Overview.md](Architecture-Overview.md)
- **Why matugen replaced wallbash** → [Lua-Migration-Notes.md](Lua-Migration-Notes.md)
- **The cold-start color-capture gotchas (why Qt5Compat over MultiEffect)** → [CLAUDE.md](../CLAUDE.md) and the memory notes on cold-start validation
