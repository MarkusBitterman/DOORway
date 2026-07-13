# Keybindings Reference

This article documents the keybinding *system* — how binds are declared, the
description contract that powers the on-screen hint, and how to regenerate a
complete index. For the three consumer-facing views of the actual keys, use:

| You want… | Go to |
|---|---|
| The complete rendered table | [`KEYBINDINGS.md`](../KEYBINDINGS.md) in the repo root |
| A by-use-case learning tour | [Keybindings-Primer.md](Keybindings-Primer.md) |
| The live, always-current list | press `SUPER + /` in a running session |

Those three are the canonical lists. This page is the reference for *how the
binds work*, so it doesn't repeat the ~114-line table (which would drift the
moment someone edits the config).

---

## Source of truth

Every keybinding lives in `Configs/.config/hypr/keybindings.lua` — a single file,
~215 lines, fully grouped and commented. As of 2026-07-13 it defines **114 binds**
across Window Management, Session, QuickShell panels, Launcher, Hardware Controls,
Utilities, Theming, and Workspaces.

There is no second bind file to reconcile. `userprefs.lua` (generated from
`doorway.keyboard`) carries input settings, not binds.

---

## The `hl.bind` API

Binds use the Hyprland lua API. The shape:

```lua
hl.bind(<key string>, <dispatcher>, <opts table>)
```

```lua
hl.bind(mainMod .. " + Q", hl.dsp.window.close(),
  { description = "[Window Management] close focused window" })

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("anyrun close || anyrun"),
  { description = "[Launcher] application launcher (anyrun)" })
```

- **Key string** — `"MOD + MOD + KEY"`. `mainMod` is a local set to `"SUPER"`.
  The trailing token must be a valid xkb keysym (e.g. `Control_R`, not `CTRL_R`).
  See [Hyprland-Lua-API-Cheatsheet § hl.bind](Hyprland-Lua-API-Cheatsheet.md#hlbind).
- **Dispatcher** — an `hl.dsp.*` call (see the cheatsheet). `hl.dsp.exec_cmd("...")`
  for shell commands; typed dispatchers like `hl.dsp.window.close()`,
  `hl.dsp.focus({ direction = "l" })`, `hl.dsp.window.move({ workspace = 1 })`.
- **Opts** — `description` (required for the hint; see below) plus flags:
  `repeating = true` (fires while held), `locked = true` (works on the lock
  screen — used for volume/brightness), `mouse = true` (mouse-button binds).

---

## The `[Group|Subgroup]` description contract

Every `description` follows a strict format:

```
[Group] action text
[Group|Subgroup] action text
```

This is **not decorative** — it's structured input for
`~/.local/lib/doorway/keybinds/hint-hyprland.py`, which parses `hyprctl binds -j`
and renders the `SUPER + /` keybindings hint (an anyrun picker). The parser splits
on `[...]` and `|` to build the grouped, searchable menu.

**If you add or change a bind, keep the format** or it won't group correctly in
the hint. The groups currently in use:

`Window Management` · `Window Management|Group Navigation` · `Window Management|Change focus` · `Window Management|Resize` · `Session` · `Launcher` · `Launcher|Apps` · `QuickShell` · `Hardware Controls|Audio` · `Hardware Controls|Media` · `Hardware Controls|Brightness` · `Utilities` · `Utilities|Screen Capture` · `Theming` · `Workspaces` · `Workspaces|Navigation` · `Workspaces|Special`

---

## Regenerating a full index

The live set (what's actually loaded, including any runtime additions) comes from
Hyprland itself:

```bash
hyprctl binds -j | jq -r '.[] | "\(.modmask) \(.key)\t\(.description)"'
```

`hint-hyprland.py` is the existing consumer of this — it's the closest thing to a
generator and the model to follow if you ever want a fully auto-built
`KEYBINDINGS.md`. Until that generator exists, `KEYBINDINGS.md` is maintained by
hand from `keybindings.lua` (see [CLAUDE.md § Documentation Hygiene](../CLAUDE.md#documentation-hygiene)
for the rule: regenerate the whole table from the lua, don't patch rows ad hoc).

---

## Notable structural facts

- **Session actions go through the QuickShell session screen**, not discrete
  binds: `SUPER + Delete` and `CTRL + ALT + Delete` both call
  `qs -c doorway ipc --any-display call sessionScreen open`. Lock/suspend/logout/
  shutdown are chosen *inside* that screen.
- **Two removed binds** leave a comment marker in the file: `SUPER + SHIFT + R`
  (wallbash mode) and `SUPER + SHIFT + T` (theme select) were deleted in Phase 10
  when their backing scripts went away. Light/dark mode moved to the shell (no
  keybind); there's no theme gallery to select from.
- **anyrun pickers are toggle-safe**: every launcher bind is
  `anyrun close || <picker>` so pressing it again closes an open picker. `pkill`
  can't do this — the Nix-wrapped process is named `.anyrun-wrapped`.

---

## What to read next

- **The `hl.dsp.*` dispatcher and `hl.bind` flag reference** → [Hyprland-Lua-API-Cheatsheet.md](Hyprland-Lua-API-Cheatsheet.md)
- **The rendered key list** → [`KEYBINDINGS.md`](../KEYBINDINGS.md)
- **Learning the keys by use case** → [Keybindings-Primer.md](Keybindings-Primer.md)
