# Interface Tour

You just logged into DOORway for the first time. This article tells you what you're looking at, what's clickable, and how to find every menu and panel without having to memorize keybindings yet.

For the *keyboard* side of the interface (which keys do what), see [Keybindings-Primer.md](Keybindings-Primer.md). The two articles are designed to be read together.

---

## What you see on first login

A wallpaper, a walnut-woodgrain bar across the top of the screen, and a cursor. Nothing else.

That's deliberate — Hyprland is a tiling window manager, not a launcher-on-the-desktop environment. There's no "Start" button in the conventional sense; the interaction model is "press a key to open something." The bar is the only persistent visible UI element.

What happened invisibly between login and your desktop appearing: unlike classic Hyprland setups, DOORway launches almost nothing from Hyprland's own startup hook (it runs exactly one command — `hyprctl setcursor`). Everything else is a **declarative systemd user unit** tied to `graphical-session.target`:

| Unit | What it gives you |
|---|---|
| `doorway-quickshell` | The entire shell: bar, sidebars, OSD, notifications, session screen, lock |
| `doorway-anyrun` | Launcher daemon (instant startup + close-on-retoggle IPC) |
| `doorway-matugen-watcher` | Recolors Hyprland window borders when the wallpaper changes |
| `doorway-wallpaper` | Wallpaper daemon (awww) |
| `doorway-text-clipboard` / `doorway-image-clipboard` | Clipboard history recording |
| `doorway-network-manager-applet` / `doorway-bluetooth-applet` / `doorway-removable-media-applet` | Tray applets |
| `doorway-idle` | hypridle — dims, locks, then DPMS-off on idle |
| `doorway-blue-light-filter` | hyprsunset (temperature driven by the shell) |
| `doorway-polkit-auth` | Graphical password prompts |
| `doorway-battery-notify` / `doorway-notifications`-era units | Battery warnings routed through the shell |

If something's missing — no bar, no wallpaper — that's a debug question: `systemctl --user --failed`, then [Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md).

---

## The bar

The top bar is QuickShell, styled after the Atari VCS 800 "Black Walnut": a walnut-veneer shell with light/dark plastic *wells* set into it. The woodgrain is mode-independent; only the wells flip with light/dark mode.

Left to right:

- **Identity button** (far left) — the HALLway mark. Opens the left sidebar.
- **Active-window label** — the focused app's name and title on a plate tinted with the app icon's dominant color.
- **Resource gauges** — HUD-style dials for CPU, memory, and network activity.
- **Center wells** — clock/date and media (MPRIS) readouts.
- **Indicators** (right cluster) — volume, microphone, network, Bluetooth as glyphs engraved into the wood; they light up red (LED-style) when the right sidebar is open.
- **System tray** — nm-applet, blueman, udiskie and friends, rendered monochrome to match the engraving.
- **Utility buttons** — including the light/dark mode toggle and the right-sidebar button (far right).

---

## The right sidebar — system controls

`SUPER + SPACE` (or click the bar's right-edge button). An overlay panel in an ENCOM-boardroom style: a flat ink instrument screen with hairline line-work, tracked micro-labels (`SYSTEMS`, `LOG`), and outline "hud key" controls. The data-flow shader is contained to the vitals band at the top — a live readout whose traces surge with net/CPU load — so all text sits on solid ground. Gold is reserved for "now": today's date, uptime, lit state pips. The look is fixed (mode-independent) in both light and dark cartridge modes.

What's in it:

- **Quick toggles** — night light, game mode, idle inhibit ("coffee"), mic mute, and friends
- **Sliders** — volume, brightness (works on desktop monitors via DDC/CI), microphone
- **Network + Bluetooth** — toggle and pick from Wi-Fi / device list dialogs
- **Calendar** — a compact month grid (collapsible to a one-line date strip)
- **Notification history** — every popup that's come and gone this session, grouped by app

The pop-out dialogs (Wi-Fi, Bluetooth, audio devices, night light) open *over* the
boardroom in the same hairline hud language — a framed ink card with corner-squared
edges, tracked labels, and flat text commands — rather than the old Material sheets.
Gold still means "now" (your connected network, an enabled toggle); red means
destructive ("Forget device").
- **Light/dark quick toggle** — same cartridge-mode switch as the bar button

Brightness on external monitors uses `ddcutil` over i2c — if the slider does nothing on a desktop display, check that you rebuilt with the `nixosModules.default` module (it grants the seat user `/dev/i2c-*` access).

---

## The left sidebar — The Desk Edition

`SUPER + SHIFT + SPACE`. A matte, ink-on-paper "open magazine page" — serif DOORWAY masthead, *Desk Edition* kicker — with informational pages you flip through like a periodical. Deliberately the visual opposite of the glossy right sidebar.

---

## The session screen

`SUPER + Delete` or `CTRL + ALT + Delete`. A full-screen overlay with the session actions: **lock**, **suspend**, **logout**, **shutdown** (plus reboot). `Escape` cancels.

---

## Notifications and OSD

Notifications are rendered by QuickShell (it registers as the `org.freedesktop.Notifications` daemon — there is no dunst). Popups appear as they arrive; dismissed ones accumulate in the right sidebar's history pane.

Volume and brightness changes (keys or sliders) show a transient OSD overlay — a cartridge faceplate with a segmented VU meter.

Muting or unmuting the output **also** raises the OSD, and the muted state is loud about itself: red bezel, red warning wash across the faceplate, red speaker glyph, a red strike bar across the meter, and an inverse-video `MUTE` tag where the percentage normally sits. The meter's lit blocks drop to a faint ghost rather than going blank, so nudging the volume while muted still moves the bar — you can see the level you'll come back to without it ever reading as live.

---

## anyrun pickers

anyrun is the universal menu primitive — one launcher window that also backs every dmenu-style picker. **Pressing the same keybind again closes an open picker** (each bind is `anyrun close || <picker>`).

| Menu | Keybind |
|---|---|
| **Application launcher** | `SUPER + A` |
| **Window switcher** (MRU-ordered) | `SUPER + Tab` |
| **File finder** | `SUPER + SHIFT + E` |
| **Keybindings hint** | `SUPER + /` |
| **Emoji picker** | `SUPER + ,` |
| **Glyph picker** | `SUPER + .` |
| **Clipboard (quick)** | `SUPER + V` |
| **Clipboard manager** | `SUPER + SHIFT + V` |
| **Wallpaper selector** | `SUPER + SHIFT + W` |
| **Animation presets** | `SUPER + SHIFT + Y` |
| **Hyprlock layout** | `SUPER + SHIFT + U` |
| **Game launcher** | `SUPER + SHIFT + G` |

The launcher also understands typed actions: `dark` / `light` switch the shell's cartridge mode, and a calculator plugin evaluates math inline.

---

## The lock screen

With `doorway.lock.backend = "doorway-lock"` (HALLway's default host config), `SUPER + L` or idle timeout brings up **DOORway Lock**: a signal-cutout intro, then rotating retro-CRT shaders as a screensaver. Any key, mouse, or controller input raises the Nintendo-Power-styled password panel over the shader; authentication is real PAM.

If the QuickShell process isn't running for any reason, the wrapper falls back to **hyprlock** automatically — the session never fails open. Layouts for the fallback are selected with `doorway.lock.layout` / `SUPER + SHIFT + U`.

---

## Theming: what changes what

| You change… | What recolors |
|---|---|
| **Light/dark mode** (bar button, sidebar toggle, launcher `dark`/`light`) | Every shell surface flips between the gray-cart and gold-cart palettes. Persisted in `~/.config/doorway/config.json` |
| **Wallpaper** (`SUPER + SHIFT + W`, `SUPER + ALT + ←/→`) | The wallpaper itself + Hyprland window-border accent colors (matugen). The shell's colors do **not** follow the wallpaper — they're a committed palette |
| **Animation preset** (`SUPER + SHIFT + Y`) | Window open/close/workspace animation curves |
| **GTK/icon/cursor themes** | Declarative Nix options (`doorway.theme.iconTheme`, `doorway.cursor`, HM `gtk.*`) — rebuild to change |

---

## Where state lives

| What | Where |
|---|---|
| **Shell config** (palette mode, toggles, weather cache keys) | `~/.config/doorway/config.json` (writable; everything else in that dir is a store symlink) |
| **Screenshots** | `~/Pictures/Screenshots/` (`screenshot.sh` is the source of truth) |
| **Wallpaper trigger** | `~/.cache/doorway/wall.set` (the matugen watcher inotify-waits on this) |
| **Hyprland border colors** | `~/.local/share/matugen/hyprland-colors.lua` (rendered by matugen) |
| **Session state** | `$XDG_STATE_HOME/doorway/staterc` |
| **Clipboard history** | `~/.cache/cliphist/db` |
| **QuickShell logs** | `/run/user/$(id -u)/quickshell/by-id/<instance>/log.log` (plus the journal: `journalctl --user -u doorway-quickshell.service`) |
| **Hyprland session log** | `/run/user/$(id -u)/hypr/<INSTANCE_SIG>/hyprland.log` |
| **Hyprland crash reports** | `~/.cache/hyprland/hyprlandCrashReport*.txt` |

---

## What to read next

- **You want to memorize the keyboard shortcuts** → [Keybindings-Primer.md](Keybindings-Primer.md)
- **A panel didn't appear or a menu isn't working** → [Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md), and check `journalctl --user -u doorway-quickshell.service`
- **You want to restyle or extend the shell** → the QML lives in `Configs/.config/quickshell/doorway/`; editing-and-rebuilding is the workflow (see [Using-DOORway-with-Nix.md § Editing DOORway](Using-DOORway-with-Nix.md#editing-doorway))
