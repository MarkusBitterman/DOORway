# DOORway Keybindings

Complete keyboard reference for DOORway. The source of truth is
[`Configs/.config/hypr/keybindings.lua`](Configs/.config/hypr/keybindings.lua) —
every bind there carries a `[Group|Subgroup] description` tag, which powers the
searchable on-screen hint.

> [!TIP]
> <kbd>Super</kbd> + <kbd>/</kbd> shows all keybindings, searchable, at any time.
> It reflects the live config exactly, so it never drifts from customizations.

App defaults honor your environment: `$TERMINAL` (kitty), `$EDITOR` (code),
`$EXPLORER` (dolphin), `$BROWSER` (firefox).

---

## Window Management

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>Q</kbd> | close focused window |
| <kbd>ALT</kbd> + <kbd>F4</kbd> | close focused window |
| <kbd>SUPER</kbd> + <kbd>W</kbd> | toggle floating |
| <kbd>SUPER</kbd> + <kbd>G</kbd> | toggle group |
| <kbd>SHIFT</kbd> + <kbd>F11</kbd> | toggle fullscreen |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>F</kbd> | toggle pin on focused window |
| <kbd>SUPER</kbd> + <kbd>J</kbd> | toggle split |
| <kbd>SUPER</kbd> + <kbd>F5</kbd> | reload Hyprland config |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>R</kbd> | restart QuickShell (apply a rebuild) |

### Session

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>L</kbd> | lock screen |
| <kbd>SUPER</kbd> + <kbd>Delete</kbd> | session screen (lock / suspend / logout / shutdown) |
| <kbd>CTRL</kbd> + <kbd>ALT</kbd> + <kbd>Delete</kbd> | session screen (lock / suspend / logout / shutdown) |

### Group Navigation

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>H</kbd> | change active group backwards |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>L</kbd> | change active group forwards |

### Change focus

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>Left</kbd> | focus left |
| <kbd>SUPER</kbd> + <kbd>Right</kbd> | focus right |
| <kbd>SUPER</kbd> + <kbd>Up</kbd> | focus up |
| <kbd>SUPER</kbd> + <kbd>Down</kbd> | focus down |
| <kbd>ALT</kbd> + <kbd>Tab</kbd> | cycle focus (and raise) |

### Resize Active Window

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>Right</kbd> | resize window right |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>Left</kbd> | resize window left |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>Up</kbd> | resize window up |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>Down</kbd> | resize window down |

### Move Active Window

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>CTRL</kbd> + <kbd>Left</kbd> | move active window left |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>CTRL</kbd> + <kbd>Right</kbd> | move active window right |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>CTRL</kbd> + <kbd>Up</kbd> | move active window up |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>CTRL</kbd> + <kbd>Down</kbd> | move active window down |

### Move & Resize with mouse

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>Left mouse</kbd> | hold to move window |
| <kbd>SUPER</kbd> + <kbd>Right mouse</kbd> | hold to resize window |
| <kbd>SUPER</kbd> + <kbd>Z</kbd> | hold to move window |
| <kbd>SUPER</kbd> + <kbd>X</kbd> | hold to resize window |

---

## QuickShell Panels

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>SPACE</kbd> | toggle right sidebar (system controls) |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>SPACE</kbd> | toggle left sidebar (The Desk Edition) |

---

## Launcher

### Apps

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>T</kbd> | terminal emulator |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>T</kbd> | dropdown terminal |
| <kbd>SUPER</kbd> + <kbd>E</kbd> | file explorer |
| <kbd>SUPER</kbd> + <kbd>C</kbd> | text editor |
| <kbd>SUPER</kbd> + <kbd>B</kbd> | web browser |
| <kbd>CTRL</kbd> + <kbd>SHIFT</kbd> + <kbd>Escape</kbd> | system monitor |

### anyrun menus

Pressing the same keybind a second time closes an open anyrun window
(every launcher bind is `anyrun close || <picker>`).

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>A</kbd> | application launcher |
| <kbd>SUPER</kbd> + <kbd>Tab</kbd> | window switcher |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>E</kbd> | file finder |
| <kbd>SUPER</kbd> + <kbd>/</kbd> | keybindings hint |
| <kbd>SUPER</kbd> + <kbd>,</kbd> | emoji picker |
| <kbd>SUPER</kbd> + <kbd>.</kbd> | glyph picker |
| <kbd>SUPER</kbd> + <kbd>V</kbd> | clipboard |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>V</kbd> | clipboard manager |

---

## Hardware Controls

Volume and brightness binds are `locked` — they keep working on the lock screen.

### Audio

| Keys | Action |
| :--- | :--- |
| <kbd>F10</kbd> / <kbd>XF86AudioMute</kbd> | toggle mute output |
| <kbd>F11</kbd> / <kbd>XF86AudioLowerVolume</kbd> | decrease volume |
| <kbd>F12</kbd> / <kbd>XF86AudioRaiseVolume</kbd> | increase volume |
| <kbd>XF86AudioMicMute</kbd> | un/mute microphone |

### Media

| Keys | Action |
| :--- | :--- |
| <kbd>XF86AudioPlay</kbd> / <kbd>XF86AudioPause</kbd> | play / pause media |
| <kbd>XF86AudioNext</kbd> | next media |
| <kbd>XF86AudioPrev</kbd> | previous media |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>M</kbd> | toggle mute for active window |

### Brightness

| Keys | Action |
| :--- | :--- |
| <kbd>XF86MonBrightnessUp</kbd> | increase brightness |
| <kbd>XF86MonBrightnessDown</kbd> | decrease brightness |

Works on laptop panels (brightnessctl) and external monitors (ddcutil DDC/CI).

---

## Utilities

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>K</kbd> | toggle keyboard layout |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>G</kbd> | game mode |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>G</kbd> | game launcher |

### Screen Capture

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>P</kbd> | color picker |
| <kbd>SUPER</kbd> + <kbd>P</kbd> | snip screen |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>P</kbd> | freeze and snip screen |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>P</kbd> | print monitor |
| <kbd>Print</kbd> | print all monitors |

---

## Theming and Wallpaper

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Right</kbd> | next global wallpaper |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Left</kbd> | previous global wallpaper |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>W</kbd> | select a global wallpaper |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>Y</kbd> | select animations preset |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>U</kbd> | select hyprlock layout |

Light/dark (gold/gray cartridge) mode is toggled from the bar's dark-mode button,
the right sidebar, or launcher `dark`/`light` — not a keybinding.

---

## Workspaces

### Navigation

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>1</kbd>..<kbd>9</kbd> | navigate to workspace 1–9 |
| <kbd>SUPER</kbd> + <kbd>0</kbd> | navigate to workspace 10 |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>Right</kbd> | change active workspace forwards |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>Left</kbd> | change active workspace backwards |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>Down</kbd> | navigate to nearest empty workspace |
| <kbd>SUPER</kbd> + <kbd>mouse_down</kbd> | next workspace |
| <kbd>SUPER</kbd> + <kbd>mouse_up</kbd> | previous workspace |

### Move window to workspace

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>1</kbd>..<kbd>0</kbd> | move to workspace 1–10 (and follow) |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>1</kbd>..<kbd>0</kbd> | move to workspace 1–10 (silent) |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>ALT</kbd> + <kbd>Right</kbd> | move window to next relative workspace |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>ALT</kbd> + <kbd>Left</kbd> | move window to previous relative workspace |

### Scratchpad (special workspace)

| Keys | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>S</kbd> | toggle scratchpad |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>S</kbd> | move to scratchpad |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>S</kbd> | move to scratchpad (silent) |

---

## Custom Keybindings

Add your own binds in the repo at `Configs/.config/hypr/keybindings.lua`, then
rebuild — the deployed copy under `~/.config/hypr/` is a read-only Nix store
symlink and can't be edited in place.

Binds use the Hyprland lua API:

```lua
hl.bind("SUPER + N", hl.dsp.exec_cmd("my-command"),
  { description = "[Launcher|Apps] my custom launcher" })
```

Keep the `[Group|Subgroup] description` format — it feeds the
<kbd>Super</kbd> + <kbd>/</kbd> hint menu.
