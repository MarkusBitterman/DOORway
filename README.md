# DOORway

**The Hyprland Desktop Environment for HALLway OS**

> **Your desktop should be beautiful, functional, and yours — by default.**

DOORway is a complete Hyprland desktop environment built for NixOS and the [HALLway](https://github.com/MarkusBitterman/HALLway) ecosystem. It originated as a fork of [HyDE](https://github.com/HyDE-Project/HyDE) and has been fully rebranded and adapted for declarative NixOS configuration.

---

## Table of Contents

- [What is DOORway?](#what-is-doorway)
- [Quick Start](#quick-start)
- [Components](#components)
- [Configuration](#configuration)
  - [Module Options Reference](#module-options-reference)
- [Themes](#themes)
- [Keybindings](#keybindings)
- [Contributing](#contributing)
- [Origins & Acknowledgments](#origins--acknowledgments)

---

## What is DOORway?

DOORway is the desktop environment layer of HALLway OS. It provides:

| Component | Purpose |
|-----------|---------|
| **Hyprland** | Wayland compositor with animations and tiling |
| **QuickShell** | QML/Qt6 shell: top bar, sidebars, OSD, notifications, session screen, lock screen |
| **DOORway Lock** | Shader-screensaver lock screen (QuickShell `WlSessionLock`); hyprlock remains as automatic fallback |
| **matugen** | Hyprland border accent colors derived from the active wallpaper |
| **anyrun** | Application launcher and dmenu-style picker menus |
| **awww** | Animated wallpaper backend |

**Why DOORway exists:**

- **NixOS-native** — Designed for declarative configuration with Home Manager
- **Part of HALLway** — Shares the ecosystem's philosophy of user sovereignty
- **Independent evolution** — The DE evolves separately from the OS configuration
- **Self-contained** — All configs live in this repo, not scattered across the system

---

## Quick Start

### For HALLway OS Users

DOORway is designed to integrate with the [HALLway](https://github.com/MarkusBitterman/HALLway) NixOS flake.

**Prerequisites**: Hyprland and dependencies installed via NixOS/Home Manager

```nix
# In your HALLway (or any NixOS home-manager) config:
imports = [ inputs.doorway.homeManagerModules.default ];
doorway.enable = true;
```

### Required NixOS Packages

When using the flake (`homeManagerModules.default`), all packages are declared in `doorwayDeps` and managed automatically — no manual package list needed.

For manual setups, core dependencies include:

```nix
hyprland          # compositor
quickshell        # shell (bar, sidebars, OSD, notifications, lock)
matugen           # wallpaper → Hyprland border colors
anyrun            # launcher + picker menus
hyprlock          # lock screen fallback
hypridle          # idle daemon
awww              # wallpaper backend
material-symbols  # icon font for QuickShell surfaces
polkit_gnome      # authentication agent
ddcutil           # external-monitor brightness (DDC/CI)

# Screenshots & clipboard
grim  slurp  cliphist

# Utilities
kitty  brightnessctl  playerctl  wireplumber  fd

# Optional
hyprsunset  satty  dolphin
```

---

## Components

### Core Utilities

| Tool | Description |
|------|-------------|
| `doorway-shell` | Script dispatcher — the front-end keybindings and services shell out to (`doorway-shell <name> [args]`) |

### Scripts Library

Located in `~/.local/lib/doorway/`:

| Script | Function |
|--------|----------|
| `animations.sh` | Animation preset switching |
| `brightnesscontrol.sh` | Screen brightness with OSD feedback |
| `volumecontrol.sh` | Audio volume with OSD feedback |
| `screenshot.sh` | Screenshot capture (area, window, full) |
| `cliphist.sh` | Clipboard history manager |
| `lockscreen.sh` | Lock screen launcher (DOORway Lock or hyprlock, per `doorway.lock.backend`) |
| `anyrun-dmenu.sh` | dmenu-style picker on anyrun (backs all menu flows) |
| `wallpaper.sh` | Wallpaper management + matugen trigger |

---

## Configuration

All DOORway settings are declared declaratively in the `doorway.*` namespace of your Home Manager configuration. Options take effect after `nixos-rebuild switch` — no manual file editing required.

### Complete Example

```nix
doorway = {
  enable  = true;
  monitor = "HDMI-A-1,1920x1080@100,0x0,1";
  keyboard = "us";

  # Cursor
  cursor.name = "oreo_spark_neon_pink_bordered_cursors";
  cursor.size = 36;

  # Fonts (scaled for distance viewing on a large monitor)
  fonts.ui.name        = "Atkinson Hyperlegible";
  fonts.ui.size        = 15;
  fonts.monospace.name = "JetBrainsMono Nerd Font Mono";
  fonts.monospace.size = 13;

  # Window geometry & blur
  theme.rounding    = 14;
  theme.gapsIn      = 4;
  theme.gapsOut     = 18;
  theme.borderSize  = 4;
  theme.blur.size   = 8;
  theme.blur.passes = 4;

  # Transparency (higher = more wallpaper glow-through)
  input.activeOpacity   = 0.88;
  input.inactiveOpacity = 0.70;

  # Animations, lock screen
  animations.preset = "LimeFrenzy";
  lock.layout       = "Anurati";

  # Blue-light filter schedule
  blueLight.temperature        = 3500;
  blueLight.schedule.nightTime = "21:00";
  blueLight.schedule.dayTime   = "06:00";

  # Service toggles (disable what you don't need)
  networkApplet.enable = false;  # using iwgtk instead of nm-applet
};
```

---

### Module Options Reference

#### Core

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable the DOORway desktop environment |
| `monitor` | str | `""` | Primary monitor (Hyprland format: `"NAME,WIDTHxHEIGHT@HZ,XxY,SCALE"`) |
| `extraMonitors` | list of str | `[]` | Additional monitor strings (same format) |
| `keyboard` | str | `"us"` | Keyboard layout identifier |
| `installPackages` | bool | `true` | Install all DOORway dependency packages automatically |

#### `doorway.cursor` — Cursor theme

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cursor.package` | package | `pkgs.oreo-cursors-plus` | Nix package providing the cursor theme files |
| `cursor.name` | str | `"oreo_spark_pink_cursors"` | Theme name as it appears under `share/icons/` in the cursor package |
| `cursor.size` | int | `24` | Cursor size in pixels |

All 38 `oreo-cursors-plus` variants follow the pattern `oreo_{colour}_cursors` (static) and `oreo_spark_{colour}_cursors` / `oreo_spark_{colour}_bordered_cursors` (animated).

#### `doorway.fonts` — Typography

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `fonts.ui.name` | str | `"Cantarell"` | UI font for dialogs, GTK apps, and general text |
| `fonts.ui.size` | int | `10` | UI font size in points |
| `fonts.monospace.name` | str | `"CaskaydiaCove Nerd Font Mono"` | Monospace font for terminals and editors |
| `fonts.monospace.size` | int | `9` | Monospace font size in points |
| `fonts.interface` | str | `"JetBrainsMono Nerd Font"` | Font for the bar, menus, and Hyprland groupbar |
| `fonts.sidebar` | str | `"Cantarell"` | Font for QuickShell sidebar content |

#### `doorway.theme` — Window geometry and blur

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `theme.gapsIn` | int (≥ 0) | `3` | Inner gap between tiled windows in pixels |
| `theme.gapsOut` | int (≥ 0) | `8` | Outer gap between windows and screen edge in pixels |
| `theme.borderSize` | int (≥ 0) | `2` | Window border width in pixels. `0` disables borders |
| `theme.rounding` | int (≥ 0) | `10` | Corner rounding radius in pixels. `0` disables rounding |
| `theme.layout` | `"dwindle"` \| `"master"` | `"dwindle"` | Default tiling layout algorithm |
| `theme.blur.enabled` | bool | `true` | Enable background blur behind transparent surfaces |
| `theme.blur.size` | int (≥ 1) | `6` | Blur kernel radius — larger is blurrier but heavier |
| `theme.blur.passes` | int (≥ 1) | `3` | Number of blur passes — more passes = smoother result |
| `theme.iconTheme.name` | str | `"Tela-dracula"` | Icon theme name (Tela variants: `Tela`, `Tela-blue`, `Tela-dracula`, `Tela-nord`, … each also with `-dark`/`-light` suffixes) |
| `theme.iconTheme.package` | package | `pkgs.tela-icon-theme` | Nix package providing the icon theme |

Borders are painted by **matugen** with Material You accent colors extracted from your active wallpaper. `theme.borderSize = 4` with a bold wallpaper and `animations.preset = "LimeFrenzy"` gives a continuously animated neon glow effect.

#### `doorway.animations` — Window animations

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `animations.preset` | enum | `"standard"` | Animation preset loaded from `animations/` |

Available presets:

| Preset | Character |
|--------|-----------|
| `classic` | Traditional slide |
| `diablo-1`, `diablo-2` | Gothic, dramatic |
| `disable` | No animations — for gaming/low-latency |
| `dynamic` | Physics-based slide with looping border gradient |
| `end4` | Material Design 3 curves, `popin 60%` window reveal |
| `fast` | Snappy, minimal duration |
| `high` | Elaborate, high-quality |
| `ja` | Japanese-style |
| `LimeFrenzy` | Overshot spring open/close + looping animated border gradient |
| `me-1`, `me-2` | Personal presets |
| `minimal-1`, `minimal-2` | Subtle, minimal |
| `moving` | Overshot slide |
| `optimized` | Performance-tuned |
| `standard` | Balanced default |
| `theme` | Follows active theme |
| `vertical` | Vertical slide |

#### `doorway.lock` — Lock screen

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `lock.backend` | `"hyprlock"` \| `"doorway-lock"` | `"hyprlock"` | Which locker `lockscreen.sh` launches. `"doorway-lock"` is the QuickShell shader-screensaver lock (retro-CRT shaders + PAM panel); it falls back to hyprlock automatically whenever the shell isn't running, so it never fails open |
| `lock.layout` | enum | `"DOORway"` | Hyprlock layout preset from `hyprlock/` (used by the hyprlock backend and the fallback path) |

Available layouts: `DOORway` (wallbash colors), `Anurati` (sci-fi typeface), `Arfan on Clouds`, `greetd`, `greetd-wallbash`, `IBM Plex`, `IMB Xtented`, `SF Pro`.

#### `doorway.idle` — Idle management

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `idle.enable` | bool | `true` | Enable the idle daemon (hypridle) |
| `idle.timeouts.dim` | int | `60` | Seconds until screen dims |
| `idle.timeouts.lock` | int | `120` | Seconds until session locks |
| `idle.timeouts.dpms` | int | `300` | Seconds until display turns off (DPMS) |
| `idle.timeouts.suspend` | int \| null | `null` | Seconds until `suspend-then-hibernate`, or `null` (default) to end the idle chain at DPMS off. Opt in per host only after verifying firmware sleep actually works |

#### `doorway.session` — Session restore

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `session.restore` | bool | `false` | Reopen the previous session's apps at login (macOS-style "reopen windows"). A timer snapshots running clients to `$XDG_STATE_HOME/doorway/session.json`; a oneshot relaunches each app on its saved workspace at session start. Apps reopen fresh — tabs/buffers are each app's own session-restore feature |
| `session.saveIntervalMinutes` | positive int | `2` | Minutes between session snapshots |

#### `doorway.input` — Input and opacity

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `input.numlock` | bool | `true` | Enable NumLock by default |
| `input.accelProfile` | `"flat"` \| `"adaptive"` \| `"custom"` | `"flat"` | Mouse acceleration profile. `"flat"` = raw input (recommended for gaming) |
| `input.naturalScroll` | bool | `false` | Natural (reversed) touchpad scroll direction |
| `input.activeOpacity` | float 0–1 | `0.9` | Focused window opacity. `1.0` = fully opaque |
| `input.inactiveOpacity` | float 0–1 | `0.75` | Unfocused window opacity |

#### `doorway.blueLight` — Blue-light filter

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `blueLight.enable` | bool | `true` | Enable hyprsunset |
| `blueLight.temperature` | int 1000–10000 | `3500` | Night-mode color temperature in Kelvin. Lower = warmer/redder |
| `blueLight.schedule.dayTime` | str | `"06:00"` | Time (HH:MM) to restore daylight colors |
| `blueLight.schedule.nightTime` | str | `"21:00"` | Time (HH:MM) to apply night temperature |
| `blueLight.schedule.useWeatherTimes` | bool | `false` | With `weather.enable`, use today's actual sunrise/sunset from PirateWeather instead of the fixed times |

Reference temperatures: `2700K` incandescent · `3500K` warm white · `5500K` neutral · `6500K` daylight.

The hyprsunset daemon itself runs scheduleless — QuickShell is the sole temperature driver, so the schedule options control when *QuickShell* applies the night temperature.

#### `doorway.shell` — QuickShell UI shell

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `shell.enable` | bool | `true` | Enable the QuickShell bar, sidebars, OSD, notifications, and session/lock surfaces |

#### `doorway.bar` — Top bar

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `bar.topLeftIcon` | str | `"distro"` | Icon on the bar's top-left button. `"distro"` auto-detects (nixos-symbolic, arch-symbolic, …); any other string is looked up as `<name>-symbolic` in the icon theme, then in `assets/icons/` |

#### `doorway.weather` — PirateWeather bar widget

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `weather.enable` | bool | `false` | Enable the bar weather widget and its periodic fetch service |
| `weather.zipCode` | str | `""` | US ZIP / postal code; geocoded via Nominatim on first run and cached |
| `weather.updateFrequency` | int | `15` | Refresh interval in minutes (systemd timer) |
| `weather.pirateWeatherApiKeyFile` | str | `""` | Path to a systemd `EnvironmentFile` containing `PIRATE_WEATHER_API_KEY=…` (get a key at pirateweather.net; pairs well with sops-nix) |
| `weather.units` | `"us"` \| `"si"` \| `"ca"` \| `"uk2"` | `"us"` | `us` °F/mph · `si` °C/m/s · `ca` °C/km/h · `uk2` °C/mph |

#### Service Toggles

| Option | Type | Default | Controls |
|--------|------|---------|----------|
| `bluetooth.enable` | bool | `true` | `blueman-applet` Bluetooth tray icon |
| `networkApplet.enable` | bool | `true` | `nm-applet --indicator` network tray icon |
| `removableMedia.enable` | bool | `true` | `udiskie` removable-media auto-mount tray |

---

## Themes

DOORway's theming splits into two deliberately separate systems:

### QuickShell: committed cartridge palette

The shell surfaces (bar, sidebars, OSD, notifications, lock) do **not** recolor from the
wallpaper. Colors come from a committed palette singleton
(`modules/common/DoorwayPalette.qml`, Nintendo-Power tokens) with two cartridge modes:

- **`dark`** — gray NES cart
- **`gold`** — gold Zelda cart (light mode)

Toggle via the bar's dark-mode button, the right-sidebar quick toggle, launcher
`dark`/`light` actions, or:

```bash
qs -c doorway ipc --any-display call theme toggleLightDark
```

The mode persists at `appearance.palette.mode` in `~/.config/doorway/config.json`.

### Hyprland borders: matugen from the wallpaper

matugen runs for exactly one output — Hyprland's border accent colors:

1. `wallpaper.sh` sets the wallpaper and writes a trigger file to `~/.cache/doorway/wall.set`
2. `doorway-matugen-watcher` (systemd user service) detects the change via `inotifywait`
3. `matugen image <wallpaper>` renders `~/.local/share/matugen/hyprland-colors.lua`
4. Hyprland reloads; `dynamic.lua` sources the new border colors

### Wallpaper commands

```bash
# Set wallpaper (triggers matugen automatically)
doorway-shell wallpaper.sh /path/to/wallpaper.jpg
```

---

## Keybindings

See [KEYBINDINGS.md](KEYBINDINGS.md) for the complete reference.

### Essential Keys

| Keybind | Action |
|---------|--------|
| `Super + T` | Terminal (Kitty) |
| `Super + A` | Application launcher (anyrun) |
| `Super + Tab` | Window switcher |
| `Super + Q` | Close window |
| `Super + W` | Toggle floating |
| `Shift + F11` | Fullscreen |
| `Super + /` | Show all keybindings |
| `Super + L` | Lock screen |
| `Super + Delete` | Session screen (lock / suspend / logout / shutdown) |
| `Super + SPACE` | Toggle right sidebar (system controls) |
| `Super + Shift + SPACE` | Toggle left sidebar (The Desk Edition) |

### Window Management

| Keybind | Action |
|---------|--------|
| `Super + Arrow` | Focus direction |
| `Super + Shift + Arrow` | Move window |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move to workspace |

### Screenshots

| Keybind | Action |
|---------|--------|
| `Super + P` | Snip a region |
| `Super + Ctrl + P` | Freeze screen, then snip |
| `Super + Alt + P` | Screenshot active monitor |
| `Print` | Screenshot all monitors |
| `Super + Shift + P` | Color picker (hyprpicker) |

---

## Styles

> Screenshots coming soon — DOORway is under active development as of 2026-07.

---

## Contributing

We welcome contributions! DOORway follows HALLway's development practices.

### Development Setup

```bash
git clone https://github.com/MarkusBitterman/DOORway.git
cd DOORway

# Enter dev shell with all tools
nix develop

# Validate before committing
shellcheck Configs/.local/lib/doorway/*.sh
```

### Testing Hyprland Changes

**Live-reload** — once inside any Hyprland session, apply config changes without restarting:

```bash
hyprctl reload

# Target a specific instance (if multiple are running)
ls /tmp/hypr/                                    # list instances
HYPRLAND_INSTANCE_SIGNATURE=<sig> hyprctl reload
```

**Via TTY** — full DRM backend, identical to a real login. Required for testing keybindings
and GPU-specific features (native KMS/DRM):

```
Ctrl+Alt+F2  →  login  →  start-hyprland
Ctrl+Alt+F7  →  back to XFCE (session stays live)
```

**Via nested Wayland** — for visual-only checks (bar renders, wallpaper appears) without
logging out. `start-hyprland` requires a running Wayland compositor. Keyboard input is dead
in nested mode (libseat cannot open `/dev/input/*`) — this is expected:

```bash
# From an XFCE Wayland terminal, or just run nix develop:
export PATH="$HOME/.local/lib/doorway:$PATH"
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CURRENT_DESKTOP=Hyprland
start-hyprland
```

**Debugging startup failures** (empty desktop, no bar or wallpaper):

```bash
# Lua config errors (stdout disabled after init — check the log file):
cat /run/user/$(id -u)/hypr/*/hyprland.log | grep -v "DEBUG from aquamarine"

# Daemon crashes — DOORway services are declarative systemd user units:
journalctl --user -b -n 200 | grep -iE "(quickshell|doorway|hypr)"
systemctl --user status doorway-quickshell.service doorway-matugen-watcher.service

# Shell-surface defects announce themselves as journal warnings:
journalctl --user -u doorway-quickshell.service -b --no-pager | grep -vE "DEBUG|INFO"
```

Inside DOORway: `Super + F5` reloads the config live (see [Keybindings](#keybindings)).

### Troubleshooting Hyprland

If Hyprland loads the emergency fallback or refuses to start, validate the lua config first — this works even on hosts where the compositor itself can't launch (e.g. nested under X11):

```bash
Hyprland --verify-config        # exits 0 if clean, 1 + errors otherwise
```

On NixOS where `~/.config/hypr/` is a read-only nix-store symlink, point `--verify-config` at the working tree and let `XDG_DATA_HOME` override resolution of `require()`d modules so your unactivated edits are seen:

```bash
XDG_DATA_HOME=$PWD/Configs/.local/share \
  Hyprland --verify-config -c $PWD/Configs/.config/hypr/hyprland.lua
```

Common errors and where to fix them:

| Error pattern | What it means | Where to fix |
|---|---|---|
| `unexpected symbol near 'repeat'` | Lua reserved keyword as a bare table key | Use `repeating = true` (upstream renamed `repeat` → `repeating`) |
| `attempt to call a nil value (field 'X')` | `hl.X` doesn't exist on this Hyprland version | Check the [upstream lua example](https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua); note that `hl.source` does **not** exist in 0.55.1 |
| `... expects string, got table` | Type mismatch in `hl.window_rule` / `hl.monitor` | Convert the table to the string form the API wants (e.g. `opacity = "0.9 0.9 1.0"`) |
| `Unknown keysym: "X"` | The trailing key in a bind isn't a valid xkb keysym | Use xkb's name (e.g. `Control_R`, not Hyprland's modifier shorthand `CTRL_R`) |
| `CBackend::create() failed!` | **Not a config issue** — backend / seat problem | Check `journalctl -u greetd`; this is a NixOS/HALLway concern, not DOORway |

For the full walkthrough — decision tree, log paths, worked examples, the wallbash-lua gap — see [`Wiki/Troubleshooting-Hyprland.md`](Wiki/Troubleshooting-Hyprland.md).

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on your system
5. Submit a PR with clear description

---

## Origins & Acknowledgments

DOORway originated as a fork of [HyDE](https://github.com/HyDE-Project/HyDE), the Hyprland Desktop Environment project. We've rebranded and adapted it for NixOS while maintaining theme compatibility with the upstream ecosystem.

**Upstream lineage:**
- [prasanthrangan/hyprdots](https://github.com/prasanthrangan/hyprdots) — Original Hyprdots project
- [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE) — HyDE continuation
- [HyDE-Project/hyde-themes](https://github.com/HyDE-Project/hyde-themes) — Compatible theme repository

**Thanks to:**
- The HyDE Project team for the excellent foundation
- The Hyprland developers
- The NixOS community

---

## License

This project inherits the license from HyDE. See [LICENSE](LICENSE) for details.

---

<div align="center">

**Part of the [HALLway](https://github.com/MarkusBitterman/HALLway) ecosystem**

*Your digital life should live on your hardware, under your rules — by default.*

</div>
