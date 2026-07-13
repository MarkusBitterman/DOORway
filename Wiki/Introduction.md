# Introduction to DOORway

DOORway is a complete Hyprland desktop environment, packaged as a Home Manager module for NixOS. You install it the way you install any other flake input — `inputs.doorway.url = "github:MarkusBitterman/DOORway";`, set `doorway.enable = true;` — and on the next rebuild you have an animated tiling Wayland desktop with a status bar, launcher, lock screen, notifications, and a theme switcher, all configured to talk to each other.

This article exists so you can decide whether DOORway is the desktop you want before you spend any time installing it. It is opinionated about what it does and doesn't try to be.

---

## What you actually get

A working session, not a parts list. After enabling the module and rebuilding, logging into the Hyprland session gives you all of this at once:

| Layer | Component | What it does for you |
|---|---|---|
| Compositor | **Hyprland** (lua-config era, 0.55+) | Animated tiling Wayland compositor with workspaces, scratchpad, groups |
| Shell | **QuickShell** (QML/Qt6, single process) | Top bar, right sidebar (system controls), left sidebar ("The Desk Edition"), OSD, notification popups, session screen |
| Launcher | **anyrun** | App launcher plus every dmenu-style picker (window switcher, file finder, emoji/glyph, clipboard history, keybind hint) |
| Lock | **DOORway Lock** + **Hypridle** | Idle-triggered shader-screensaver lock (retro-CRT GLSL + PAM panel); hyprlock remains as automatic fallback |
| Wallpaper | **awww** + `wallpaper.sh` | Animated wallpaper backend; wallpaper changes drive Hyprland border colors via matugen |
| Terminal | **Kitty** | Default terminal with GPU acceleration |
| Screenshots | **grim** + **slurp** + **satty** | Region/window/full capture, freeze-and-shoot, annotation |
| Clipboard | **cliphist** + **wl-paste** | Persistent clipboard history with anyrun picker UI |
| Color | **hyprpicker** | Pixel color picker |
| Display tone | **hyprsunset** | Optional blue-light filter (temperature driven by QuickShell, optionally on real sunset times) |
| Auth UI | **polkit-gnome** | Graphical password prompts for sudo/admin actions |
| Secrets | **gnome-keyring** | Secret Service API for VSCodium, Firefox, etc. (provided system-side by HALLway) |

Plus the DOORway-specific layer:

| Tool | Purpose |
|---|---|
| `doorway-shell` | Front-end script that dispatches to every utility in `~/.local/lib/doorway/` (screenshots, wallpapers, brightness, volume, gamemode, etc.) |
| `doorwayctl` | IPC control utility for interacting with the running session |
| `doorway-ipc` | Direct IPC communication primitive |
| ~100 scripts in `~/.local/lib/doorway/` | The actual work — `wallpaper.sh`, `screenshot.sh`, `volumecontrol.sh`, `anyrun-dmenu.sh`, etc. |

You don't have to glue these together yourself. The keybindings in `Configs/.config/hypr/keybindings.lua` already call them, the bar already shows their output, and the anyrun pickers are already styled.

---

## Who this is for

- **NixOS users who want a curated Hyprland setup** without assembling one from a dozen separate dotfiles repos. You add one flake input and you're done.
- **Users of [HALLway OS](https://github.com/MarkusBitterman/HALLway)**, which consumes DOORway as its desktop layer. If you're on HALLway, you already have this — see [Using-DOORway-with-Nix.md](Using-DOORway-with-Nix.md) for the integration details.
- **People who want a desktop with a committed visual identity** — the Nintendo-Power/retro-CRT "cartridge" look (gray NES cart dark mode, gold Zelda cart light mode), the Black Walnut bar, the magazine-page sidebar — with declarative deployment, reproducibility, and rollback the way you roll back any other NixOS generation.
- **Anyone planning to customize.** The whole `Configs/` tree is a thin payload — keybindings are one lua file, the shell is readable QML, the palette is one committed singleton. You can fork and edit without reverse-engineering an installer.

## Who this isn't for

- **Arch / Fedora / non-NixOS users.** Use [upstream HyDE](https://github.com/HyDE-Project/HyDE) instead. DOORway's deployment story is Nix-shaped end-to-end; there is no equivalent on imperative distros and we don't try to provide one.
- **Anyone wanting hyprlang configs.** DOORway migrated to Hyprland 0.55+'s lua config format. The `*.conf` files are gone (with the exception of a few daemon configs that still use hyprlang — `hypridle.conf`, `hyprlock.conf`). If you have a strong preference for hyprlang, you'll be fighting the codebase.
- **Anyone wanting wallpaper-derived shell theming (Material You everywhere).** DOORway made the opposite choice deliberately: the shell's colors are a *committed* palette (`DoorwayPalette.qml`) with two cartridge modes, and only Hyprland's window-border accents follow the wallpaper (via matugen). If you want your whole bar to recolor per wallpaper, this isn't that desktop.
- **People who want a minimal i3-style setup.** DOORway is loaded: animations, blur, a woodgrain bar with HUD gauges, two sidebars, a shader lock screen. You can strip features but the defaults aren't minimal.

---

## Lineage and how this differs from upstream HyDE

DOORway started as a fork of [HyDE](https://github.com/HyDE-Project/HyDE), which itself continues the lineage of [prasanthrangan/hyprdots](https://github.com/prasanthrangan/hyprdots). The visual identity, theme catalog, and keybinding philosophy come from that upstream.

What's specifically DOORway:

| Concern | Upstream HyDE | DOORway |
|---|---|---|
| **Target OS** | Distro-agnostic, primarily Arch | NixOS-native |
| **Deployment** | Imperative installer shell scripts | Home Manager module via flake input |
| **Config format** | Mostly hyprlang (`.conf`) | Hyprland 0.55+ lua (`.lua`) |
| **Branding prefix** | `HYDE_`, `hyde-shell`, `hydectl` | `DOORWAY_`, `doorway-shell`, `doorwayctl` |
| **Edit workflow** | Edit `~/.config/hypr/*` directly | Edit `Configs/.config/hypr/*` in repo, then `nixos-rebuild switch` (the deployed paths are read-only Nix store symlinks) |

The lua migration was the first large divergence; since then DOORway has replaced the entire inherited UI surface (waybar/dunst/rofi/wlogout → QuickShell + anyrun), so the visual layer is now DOORway's own rather than HyDE's. The migration history lives in `TODO.md` and (eventually) the planned `Lua-Migration-Notes.md` wiki article.

DOORway is then consumed by [HALLway](https://github.com/MarkusBitterman/HALLway), the full NixOS flake that bundles a complete operating system. HALLway treats DOORway as one of its inputs — the same pattern any other NixOS user would use. You can run DOORway outside HALLway just fine; HALLway is the largest consumer, not the only one.

---

## How DOORway thinks about your machine

Three load-bearing ideas shape the design. Worth knowing up front because they explain a lot of "wait, why is it like that?" later:

### 1. The repo is the source of truth, the deployed paths are read-only.

Every file under `~/.config/hypr/`, `~/.config/anyrun/`, `~/.config/quickshell/`, `~/.local/lib/doorway/`, etc. is either a symlink into the Nix store (root-owned, read-only) or a file Home Manager generated at activation. **You don't edit them directly.** You edit the corresponding file in this repo's `Configs/` tree, then `sudo nixos-rebuild switch --flake ...` to redeploy.

This is the single biggest mental shift for users coming from imperative distros. For the full story (including the runtime-write story for scripts that need to save state somewhere), see [CLAUDE.md's Nix Store Workflow section](../CLAUDE.md#nix-store-workflow--critical).

### 2. The lua config is event-driven, not declarative everywhere.

Hyprland 0.55+ kept the declarative `hl.config({...})` table but moved a lot of behavior into the lua scripting layer. Keybindings are function calls (`hl.bind(...)`), exec-once is a lifecycle event (`hl.on("hyprland.start", function() ... end)`), env vars are direct calls (`hl.env(K, V)`). DOORway's `Configs/.local/share/hypr/` directory holds the scripts that wire it all up.

What this means for you: most "I want it to do X on startup" or "I want a new shortcut for Y" changes are simple lua additions, not config-file edits. The full chain is documented (eventually) in the planned `Architecture-Overview.md`.

### 3. The shell is one QuickShell process; the daemons are systemd user units.

Everything you see (bar, sidebars, OSD, notifications, session screen, lock) is a single QuickShell instance running as `doorway-quickshell.service`. Everything that runs alongside it (clipboard watchers, tray applets, idle daemon, matugen watcher, blue-light filter) is a declarative systemd user unit defined in `flake.nix` — Hyprland's own startup hook is down to a single `hyprctl setcursor` call.

Two practical consequences: `systemctl --user status doorway-quickshell.service` (and the journal) is where UI problems surface, not Hyprland's log; and after a rebuild you `systemctl --user restart doorway-quickshell.service` to pick up new store paths — Home Manager does not reliably restart user services for you.

---

## Where to go next

Pick the article that matches your moment:

| You want to… | Read |
|---|---|
| Install DOORway on your NixOS system | [Using-DOORway-with-Nix.md](Using-DOORway-with-Nix.md) |
| Learn the desktop after first login | [Interface-Tour.md](Interface-Tour.md) |
| Memorize the daily-use keyboard shortcuts | [Keybindings-Primer.md](Keybindings-Primer.md) |
| Diagnose a session that won't start or shows the emergency banner | [Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md) |
| Understand the lua orchestrator, IPC topology, and script chain | *Architecture-Overview.md* (planned, not yet written) |
| Read the contributor manual | [CLAUDE.md](../CLAUDE.md) in the repo root |

If you came here from the top-level [README](../README.md), that's the front-porch overview; this wiki is for once you're past the welcome mat and want depth.
