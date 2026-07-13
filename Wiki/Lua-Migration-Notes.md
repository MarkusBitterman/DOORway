# Lua Migration Notes

DOORway's Hyprland config is written in lua, not hyprlang (`.conf`). This was the
first large divergence from upstream HyDE and it changes how you read, write, and
port config. This article explains *why*, *what changed semantically* (not just
syntactically), and *what to watch for* when porting an upstream HyDE `.conf`
change onto the lua fork.

Background reading: [Hyprland's lua-ification announcement](https://hypr.land/news/26_lua/),
the [upstream lua example](https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua),
and [Hyprland-Lua-API-Cheatsheet.md](Hyprland-Lua-API-Cheatsheet.md) for the API surface.

---

## Why lua

Hyprland 0.55+ introduced a lua config format alongside hyprlang. DOORway migrated
fully (TODO.md Phases 1–8, spread across 2026-05). The motivation:

- **It's the direction upstream is going** — the lua API is where new
  configuration expressiveness lands.
- **Real logic, not string templating.** hyprlang config-generation in HyDE meant
  shell scripts `sed`-ing `.conf` files. Lua lets the config compute
  (loops, conditionals, `pcall` guards, shared data modules) natively.
- **`require()` gives a real module system** — the orchestrator chain (see
  [Architecture-Overview.md](Architecture-Overview.md)) is lua modules requiring
  each other, with a shared `variables.lua` data module that lua caches as a
  singleton.

`configType = "lua"` in `flake.nix` tells Home Manager's Hyprland module to expect
lua. `Hyprland --verify-config` parses lua the same way it parses hyprlang.

---

## The mental model shift: declarative → event-driven

hyprlang is purely declarative — every line is a keyword assignment. Lua kept the
declarative table (`hl.config({...})`) but moved a lot of behavior into a scripting
layer:

| hyprlang | lua |
|---|---|
| `bind = SUPER, Q, killactive` | `hl.bind("SUPER + Q", hl.dsp.window.close(), {...})` |
| `exec-once = foo` | `hl.on("hyprland.start", function() hl.exec_cmd("foo") end)` |
| `env = KEY,VALUE` | `hl.env("KEY", "VALUE")` |
| `windowrule = float, class:X` | `hl.window_rule({ match = { class = "X" }, float = true })` |
| `general { gaps_in = 5 }` | `hl.config({ general = { gaps_in = 5 } })` |

The practical upshot: keybindings are **function calls**, exec-once is a
**lifecycle event**, and config becomes a program that runs top-to-bottom. Load
order matters (env before children, `variables` early, `finale` last).

---

## Semantic changes (not just syntax)

These are the traps — places where the meaning shifted, not just the spelling.

### `repeat` → `repeating`

`repeat` is a **lua reserved keyword**, so a bare table key `repeat = true` is a
syntax error (`unexpected symbol near 'repeat'`). Upstream renamed the flag to
`repeating`:

```lua
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.resize({ x = 30, y = 0 }),
  { description = "...", repeating = true })
```

### Dispatchers are namespaced lua calls, not strings

hyprlang dispatch is a string (`killactive`, `movetoworkspace`). Lua dispatch is a
**typed call** under `hl.dsp.*` — `hl.dsp.window.close()`,
`hl.dsp.focus({ direction = "l" })`, `hl.dsp.window.move({ workspace = 1 })`. A
bare dispatcher string won't work; it's evaluated as lua.

### Type-strict fields

The lua API is opinionated about field shapes where hyprlang was forgiving:

- `opacity` is a space-separated **string** `"0.9 0.9 1.0"`, not a table.
- `tag` is one string per rule call — two tags means two `hl.window_rule` calls.
- `hl.monitor` wants `mode`/`position`/`scale` as separate string fields.

### Keysyms, not modifier shorthand

`hl.bind` splits on the last `+`; the trailing token must be a valid **xkb keysym**
(`Control_R`, `Print`, `comma`), not Hyprland shorthand (`CTRL_R` → `Unknown
keysym`).

---

## The `hl.source` gap and what it forced

The single most consequential discovery of the migration: **`hl.source()` does not
exist on Hyprland 0.55.1** (nor `hl.include`, `hl.load`, `hl.parse`). There is no
way for a lua config to consume an external config file at runtime.

This broke the inherited **wallbash** color pipeline outright — wallbash writes a
hyprlang `colors.conf`, and lua had no way to read it back. Rather than wait for an
upstream sourcing API, DOORway changed architecture:

- **matugen** renders a real `hyprland-colors.lua` file, which `dynamic.lua`
  consumes with plain `pcall(dofile, ...)` — no sourcing API needed.
- The QuickShell shell owns all *other* colored surfaces with a committed palette.

See [Theming.md](Theming.md) for the resulting two-system design. The lesson
generalizes: **if a migration path depends on an API that turns out not to exist,
re-architecting around a file the lua runtime *can* load (`dofile`) beats waiting
for upstream.**

Also nil on 0.55.1, discovered the same way: `hl.keyword("gesture", ...)` and
dotted nested keywords (`hl.keyword("group:groupbar:col.active", ...)`). Replaced
with `hl.gesture({...})` and `hl.config({ group = { groupbar = {...} } })`.

---

## Porting an upstream HyDE `.conf` change

DOORway now owns the hypr config directly, so upstream HyDE `.conf` edits don't
merge cleanly. When cherry-picking a HyDE change:

1. **Read what the hyprlang change *means*,** then express it in the lua API —
   don't translate line-by-line. A `windowrule` becomes an `hl.window_rule` table;
   an `exec-once` usually becomes a **systemd unit** in `flake.nix`, not an
   `hl.on` hook (see the de-HyDE migration in [Architecture-Overview](Architecture-Overview.md)).
2. **Check the API call exists** against the upstream lua example before assuming
   it's available.
3. **Validate before deploying:**
   ```bash
   XDG_DATA_HOME=$PWD/Configs/.local/share \
     Hyprland --verify-config -c $PWD/Configs/.config/hypr/hyprland.lua
   ```
   This catches syntax errors, nil `hl.*` calls, and type mismatches without a
   running session. It's the check that caught the `repeat` bug, the `hl.keyword`
   nils, and the windowrule type mismatches during the migration.

The `sed`-based rebrand commands in [CLAUDE.md § Rebrand a new upstream merge](../CLAUDE.md#rebrand-a-new-upstream-merge)
mostly no longer apply to the hypr tree (it's lua now, and DOORway-owned).

---

## What stayed hyprlang

A few daemon configs use their *own* parser, not Hyprland's, so they stay `.conf`:

`hyprlock.conf`, `hyprlock/*.conf` (themes), `hypridle.conf`, `hyprsunset.conf`.
These are generated by `flake.nix` from `doorway.{lock,idle,blueLight}` options —
they're hyprlang-shaped because hyprlock/hypridle/hyprsunset read them, not because
Hyprland does.

---

## What to read next

- **The API surface, every call** → [Hyprland-Lua-API-Cheatsheet.md](Hyprland-Lua-API-Cheatsheet.md)
- **The config chain the modules form** → [Architecture-Overview.md](Architecture-Overview.md)
- **Diagnosing a lua parse error** → [Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md)
- **The full phase-by-phase migration ledger** → `TODO.md` in the repo root
