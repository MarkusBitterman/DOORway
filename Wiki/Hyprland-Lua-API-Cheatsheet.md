# Hyprland Lua API Cheatsheet

Every `hl.*` call DOORway uses, with the exact shape it expects — pulled from the
live config, not from memory. Hyprland's lua API (0.55+) has no static types, so a
wrong shape or a nonexistent function fails at *runtime* (or silently). This page
is the quick-reference for writing new config and reading the
[upstream lua example](https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua).

For *why* the config is lua at all and what changed semantically, see
[Lua-Migration-Notes.md](Lua-Migration-Notes.md). For diagnosing lua errors, see
[Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md).

---

## Frequency in this repo

Roughly, by call count — a sense of what the config is made of:

| Call | ~count | Role |
|---|---|---|
| `hl.bind` | 114 | keybindings |
| `hl.dsp.*` | ~90 | dispatchers (inside binds) |
| `hl.window_rule` | 37 | per-window rules |
| `hl.config` | 35 | declarative config tables |
| `hl.layer_rule` | 16 | per-layer-surface rules |
| `hl.animation` / `hl.curve` | 10 / 6 | animation leaves + bezier curves |
| `hl.monitor` | 7 | monitor setup |
| `hl.gesture` | 5 | touchpad gestures |
| `hl.exec_cmd` | 5 | runtime shell side-effects |
| `hl.on` | 2 | lifecycle event hooks |
| `hl.keyword` | 2 | custom `doorway:*` keywords |
| `hl.env` | 2 | environment variables |

---

## Declarative config

### `hl.config(table)`

The declarative core — the lua equivalent of hyprlang's top-level keywords. Nested
tables map to hyprlang's `section:key`.

```lua
hl.config({
    general = { gaps_in = 5, border_size = 2 },
    decoration = { rounding = 10 },
    group = { groupbar = { col = { active = "rgba(...)" } } },
})
```

Called 35× — `defaults.lua` uses it for general/decoration/input/layout, and
groupbar config that used to be `hl.keyword("group:groupbar:...")`.

### `hl.env(KEY, VALUE)`

One env var per call. Child processes launched by Hyprland inherit these.

```lua
hl.env("DOORWAY_LOCKSCREEN", "doorway-lock")
-- env.lua iterates a table: for _,e in ipairs(envs) do hl.env(e[1], e[2]) end
```

### `hl.keyword(key, value)`

Sets an arbitrary keyword — used only for the custom `doorway:*` namespace that
`hyprctl getoption` can query. **Wrap in `pcall`** — unknown keywords emit
warnings:

```lua
pcall(function() hl.keyword("doorway:" .. k, tostring(v)) end)
```

---

## Keybindings

### `hl.bind(keys, dispatcher, opts)`

```lua
hl.bind("SUPER + Q", hl.dsp.window.close(),
  { description = "[Window Management] close focused window" })

hl.bind("SUPER + SHIFT + Right", hl.dsp.window.resize({ x = 30, y = 0 }),
  { description = "[...] resize right", repeating = true })

hl.bind("F12", hl.dsp.exec_cmd("doorway-shell volumecontrol -q -o i"),
  { description = "[Hardware Controls|Audio] increase volume", repeating = true, locked = true })
```

- **keys** — `"MOD + MOD + KEYSYM"`. The trailing token must be a valid **xkb
  keysym** (`Control_R`, `Print`, `comma`), *not* Hyprland modifier shorthand
  (`CTRL_R` fails with `Unknown keysym`).
- **opts flags** — `repeating` (fires while held), `locked` (works on the lock
  screen), `mouse` (for `mouse:272`-style button binds).

### `hl.dsp.*` dispatchers

Used inside `hl.bind`. The ones this repo uses:

| Dispatcher | Shape |
|---|---|
| `hl.dsp.exec_cmd(str)` | run a shell command (the workhorse — 54×) |
| `hl.dsp.window.close()` | close focused |
| `hl.dsp.window.float({ action = "toggle" })` | toggle floating |
| `hl.dsp.window.fullscreen({ action = "toggle" })` | toggle fullscreen |
| `hl.dsp.window.move({ workspace = 1 })` / `{ workspace = "special", silent = true }` | move window |
| `hl.dsp.window.resize({ x = 30, y = 0 })` | resize by delta |
| `hl.dsp.window.drag()` / `hl.dsp.window.resize()` (no args) | mouse move/resize |
| `hl.dsp.focus({ direction = "l" })` / `{ workspace = 1 }` / `{ workspace = "r+ 1" }` | focus window/workspace |
| `hl.dsp.group.toggle()` / `.next()` / `.prev()` | window groups |
| `hl.dsp.workspace.toggle_special()` | scratchpad toggle |
| `hl.dsp.layout("togglesplit")` | dwindle split toggle |

> **Every dispatcher is evaluated as lua**, so a bare dispatcher *string* is a
> syntax error — use the `hl.dsp.*` call form (this is a load-bearing gotcha; see
> the project memory on Hyprland dispatch being lua).

---

## Rules

### `hl.window_rule(table)`

`match` selects; the other keys are the rule. 37× in this repo.

```lua
hl.window_rule({
    match = { class = "^(.*mpv.*)$|^(.*vlc.*)$" },
    idle_inhibit = "fullscreen",
})

hl.window_rule({
    match = { class = "^(pavucontrol)$" },
    float = true,
})
```

- `opacity` is a **space-separated string**: `"0.9 0.9 1.0"` (active inactive
  fullscreen), *not* a table.
- `tag` is one string per call (`"+name"`); two tags = two calls.

### `hl.layer_rule(table)`

For Wayland layer surfaces (bar, anyrun, notifications, sidebars). `match.namespace`
is the surface's namespace.

```lua
hl.layer_rule({
    match = { namespace = "anyrun" },
    blur = true,
    ignore_alpha = 0,
})
```

The QuickShell namespaces are `quickshell:bar`, `quickshell:sidebarRight`, etc.
(see [Architecture-Overview § surface map](Architecture-Overview.md#the-quickshell-surface)).

### `hl.monitor(table)`

```lua
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = "1" })
```

`mode`, `position`, `scale` are separate string fields. DOORway generates
`monitors.lua` from `doorway.monitor` — you rarely write this by hand.

---

## Animations

### `hl.curve(name, spec)` + `hl.animation(table)`

Bezier curves are named, then referenced by animation leaves:

```lua
hl.curve("wind",   { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "wind", style = "slide" })
```

Animation presets in `animations/*.lua` are self-contained files of these.

---

## Gestures

### `hl.gesture(table)`

Touchpad gestures. **Guard with `if hl.gesture then`** — it's a lua-specific
binding that may not exist on every build:

```lua
if hl.gesture then
    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    hl.gesture({ fingers = 3, direction = "pinchin", action = "float", action_modifier = "tile" })
end
```

---

## Lifecycle & side-effects

### `hl.on(event, fn)`

Hooks a lifecycle event. DOORway uses it twice:

```lua
hl.on("hyprland.start", function() hl.exec_cmd("hyprctl setcursor ...") end)
hl.on("monitor.added", function(mon) ... end)
```

The `hyprland.start` body is now down to a single `hyprctl setcursor` — everything
else migrated to systemd units (see [Architecture-Overview](Architecture-Overview.md)).

### `hl.exec_cmd(str)`

Runs a shell command at config-eval time (distinct from `hl.dsp.exec_cmd`, which
is a *dispatcher* used inside binds). For genuinely IPC-dependent one-shots.

---

## What does NOT exist on 0.55.1

Confirmed empirically — do not reach for these:

- **`hl.source`** / `hl.include` / `hl.load` / `hl.parse` — no way to source
  external config at runtime. This is why wallbash was replaced by matugen
  emitting a real `.lua` file consumed via `pcall(dofile, ...)`. See
  [Lua-Migration-Notes.md](Lua-Migration-Notes.md).
- **`hl.keyword("gesture", ...)`** and dotted nested keywords like
  `hl.keyword("group:groupbar:col.active", ...)` return nil — use `hl.gesture({...})`
  and `hl.config({ group = { groupbar = {...} } })` instead.

When in doubt, the [upstream example](https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua)
is the authoritative surface — if a call isn't there, it probably doesn't exist.

---

## What to read next

- **Why lua, and what changed semantically** → [Lua-Migration-Notes.md](Lua-Migration-Notes.md)
- **Diagnosing a lua config error** → [Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md)
- **The config chain these calls live in** → [Architecture-Overview.md](Architecture-Overview.md)
