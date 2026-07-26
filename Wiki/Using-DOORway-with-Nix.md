# Using DOORway with Nix

This article gets DOORway running on your NixOS system via the flake + Home Manager module — the only supported path, and the one HALLway uses and we test against. It's declarative, rollback-safe, and version-pinned.

If you've never written a Nix flake before, start at the next section. If you're already running flakes for your NixOS config, [skip ahead](#1-add-doorway-as-a-flake-input).

---

## A 60-second tour of Nix flakes

A **flake** is a self-contained Nix project with three parts:

1. **Inputs** — other flakes (or sources) it depends on, pinned to specific commits in a generated `flake.lock` file. This is what makes builds reproducible: everyone using the flake at a given lock version gets bit-identical inputs.
2. **Outputs** — things the flake produces. Packages, NixOS modules, Home Manager modules, devShells, library functions, anything Nix can express.
3. **`flake.nix`** — the manifest tying inputs and outputs together. Pure Nix; no side effects.

DOORway is a flake. Its `inputs` are `nixpkgs/nixos-unstable` plus a pinned `hyprland`. Its `outputs` are:

- `homeManagerModules.default` — the Home Manager module you import (also exposed as `homeManagerModules.doorway`)
- `nixosModules.default` — the system-side module: owns `programs.hyprland`, i2c access for external-monitor brightness, UPower, gnome-keyring, and the XDG menu spec KDE apps need
- `devShells.default` — a `nix develop` shell with Hyprland, linters, formatters, and helpers (for hacking on DOORway itself)
- `lib.doorwayDeps` — the dependency package list, exposed for downstream flakes (HALLway) to reuse

Why a flake and not a tarball: pinned inputs mean the version of Hyprland that DOORway was tested against is the version you actually get. No "works on my machine" because the lock file makes the machine the same.

---

## Flake integration

The five-step version:

### 1. Add DOORway as a flake input

In your system flake (the one with `nixosConfigurations.<hostname>`), add the input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add this:
    doorway.url = "github:MarkusBitterman/DOORway";
  };

  # ...
}
```

`inputs.<name>.follows = "nixpkgs"` makes a downstream flake share your system's nixpkgs rather than pulling its own. DOORway doesn't pin nixpkgs aggressively, so this is optional but recommended.

### 2. Pass `inputs` through to your Home Manager configuration

Home Manager modules can't see your flake's `inputs` by default. Pass them in via `extraSpecialArgs` (Home Manager's idiom) or `_module.args` (Nix's standard idiom):

```nix
# In outputs:
homeConfigurations.<user>@<host> = home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  extraSpecialArgs = { inherit inputs; };
  modules = [ ./home.nix ];
};
```

…or, if you're using `home-manager.users.<user> = ...` inside a NixOS config block:

```nix
home-manager.extraSpecialArgs = { inherit inputs; };
home-manager.users.<user> = import ./home.nix;
```

### 3. Import the Home Manager module

In `home.nix` (or wherever your user's Home Manager configuration lives):

```nix
{ config, pkgs, inputs, ... }:
{
  imports = [
    inputs.doorway.homeManagerModules.default
  ];

  # ...
}
```

### 4. Enable it

Same file:

```nix
doorway = {
  enable = true;
  monitor = "HDMI-A-1,1920x1080@100,0x0,1";   # see "Module options" below
  keyboard = "us";
};
```

### 5. Rebuild

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

On next login (select "Hyprland" from your display manager's session menu), DOORway is your desktop.

### Full minimal example

If you're starting from scratch, here's the smallest working `home.nix` that enables DOORway:

```nix
{ inputs, pkgs, ... }:
{
  imports = [ inputs.doorway.homeManagerModules.default ];

  home.username = "your-user";
  home.homeDirectory = "/home/your-user";
  home.stateVersion = "24.11";  # match your NixOS release

  doorway = {
    enable = true;
    monitor = "HDMI-A-1,1920x1080@60,0x0,1";
  };

  programs.home-manager.enable = true;
}
```

---

## Module options

The full options reference lives in the [README § Module Options Reference](../README.md#module-options-reference) — it covers `doorway.{cursor,fonts,theme,input,animations,lock,idle,blueLight,shell,bar,weather}` and the service toggles. The core options:

| Option | Type | Default | What it does |
|---|---|---|---|
| `doorway.enable` | bool | `false` | Master toggle. Nothing else happens unless this is `true`. |
| `doorway.monitor` | string | `",preferred,auto,1"` | Primary monitor configuration in Hyprland's `output,mode,position,scale` format. Parsed into `hl.monitor({...})` in the generated `monitors.lua`. |
| `doorway.extraMonitors` | list of strings | `[]` | Additional monitors, same format as `monitor`. One entry per extra display. |
| `doorway.keyboard` | string | `"us"` | xkb keyboard layout. Injected into the generated `userprefs.lua` as `kb_layout`. |
| `doorway.installPackages` | bool | `true` | Whether to add DOORway's runtime dependencies (hyprland, quickshell, anyrun, matugen, kitty, etc.) to `home.packages`. Set to `false` if you install them at the NixOS system level instead. |

### `monitor` and `extraMonitors` — worked examples

The format is the same string format Hyprland's `monitor=` directive uses, split by commas: **`output,mode,position,scale`**.

**Single monitor at 100 Hz:**
```nix
doorway.monitor = "HDMI-A-1,1920x1080@100,0x0,1";
```

**Dual monitor — laptop + external:**
```nix
doorway.monitor = "eDP-1,1920x1080@60,1920x0,1";
doorway.extraMonitors = [
  "HDMI-A-1,2560x1440@144,0x0,1"
];
```

**Mixed scaling — 4K monitor at 1.5× alongside a 1080p:**
```nix
doorway.monitor = "DP-1,3840x2160@60,0x0,1.5";
doorway.extraMonitors = [
  "HDMI-A-1,1920x1080@60,2560x0,1"   # positioned to the right of the scaled 4K
];
```

**Auto-detect (default):**
```nix
doorway.monitor = ",preferred,auto,1";
# Equivalent to: monitor=,preferred,auto,1 in hyprlang
# Hyprland picks the preferred mode and auto-arranges position. Useful for testing.
```

If you need anything more advanced (mirrored displays, manual `transform=`, etc.), you can drop into `~/.config/hypr/monitors.lua` directly — but be aware that this is a generated file that the module rewrites on every rebuild, so you'd lose customizations. For genuinely complex monitor setups, edit `flake.nix`'s `parseMon` helper or fork the module.

### Why `installPackages` is a thing

By default the module adds all of DOORway's runtime dependencies (hyprland, quickshell, anyrun, matugen, hyprlock, hypridle, kitty, grim/slurp, brightnessctl, ddcutil, etc.) to `home.packages` so a clean Home Manager activation gives you a fully working desktop with no further package management.

But you may already install these at the **NixOS system level** (which is what HALLway does — it puts Hyprland in `environment.systemPackages` so it shows up in the display manager's session list). Setting `doorway.installPackages = false;` prevents duplicate installs.

The package list itself is also exposed as `inputs.doorway.lib.doorwayDeps pkgs` so downstream flakes (like HALLway) can install the same dependencies at the system level without copy-pasting.

---

## What gets deployed at activation

When `doorway.enable = true` and you rebuild, Home Manager creates:

### Hyprland config (`~/.config/hypr/`)

Individual symlinks into the Nix store, so the generated files can live alongside the source-controlled ones:

| Path | Source |
|---|---|
| `hypr/hyprland.lua` | `Configs/.config/hypr/hyprland.lua` (read-only) |
| `hypr/keybindings.lua` | `Configs/.config/hypr/keybindings.lua` (read-only) |
| `hypr/windowrules.lua` | `Configs/.config/hypr/windowrules.lua` (read-only) |
| `hypr/animations.lua` | `Configs/.config/hypr/animations.lua` (read-only) |
| `hypr/workflows.lua` | `Configs/.config/hypr/workflows.lua` (read-only) |
| `hypr/{hypridle,hyprlock,hyprsunset}.conf` | **generated** from `doorway.idle`, `doorway.lock`, `doorway.blueLight` options |
| `hypr/{animations,themes,workflows,hyprlock}/` | corresponding source directories |
| `hypr/monitors.lua` | **generated** from your `doorway.monitor` + `extraMonitors` options |
| `hypr/userprefs.lua` | **generated** from your `doorway.keyboard` option (and a few sensible defaults) |
| `hypr/doorway-{cursor,fonts,theme,animation-preset}.lua` | **generated** sidecars carrying module-option values into the lua config |

The generated files are real files Home Manager writes (not symlinks), which is why they can coexist with the symlinked source files — a whole-directory symlink to the Nix store would have been read-only and prevented this.

### Other app configs (`~/.config/<app>/`)

- `~/.config/quickshell/doorway/` → the whole shell (whole-dir symlink)
- `~/.config/anyrun/` → launcher + picker config (whole-dir symlink)
- `~/.config/kitty/` → terminal config (whole-dir symlink)
- `~/.config/matugen/` → config.toml + templates (individual links)
- `~/.config/doorway/` → individual links for `config.toml` and `wallbash/` only — the directory itself is real and writable, because the shell persists its runtime config to `~/.config/doorway/config.json` there

### User binaries and libraries (`~/.local/`)

- `~/.local/bin/doorway-shell` (executable)
- `~/.local/lib/doorway/` → ~100 utility scripts (screenshot, wallpaper, volume, pickers, etc.)
- `~/.local/share/doorway/` → data files, templates
- `~/.local/share/hypr/` → lua orchestrator + startup/env/dynamic/variables modules

### PATH

`home.sessionPath = [ "$HOME/.local/bin" "$HOME/.local/lib/doorway" ];` — so `doorway-shell <subcommand>` and the individual script names work from any terminal in your session.

### Hyprland config type

`wayland.windowManager.hyprland.configType = "lua";` — this tells Home Manager's Hyprland module to expect lua, not hyprlang. Important if you also use Home Manager's `wayland.windowManager.hyprland.settings = { ... }` API elsewhere (you probably don't, because we're doing everything via the lua files).

### What you'll see at runtime

On first login after `nixos-rebuild switch`, you'll see the wallpaper come up, then the QuickShell bar at the top, then a brief moment as services warm up (clipboard daemons, tray applets, matugen watcher, etc.). Total cold-start to "everything responsive" is typically 1–3 seconds on modern hardware.

After later rebuilds, run `systemctl --user restart doorway-quickshell.service` so the shell picks up its new store paths — Home Manager does not reliably restart user services.

If something doesn't appear (empty desktop, no bar), follow [Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md). The two most common causes are silent exec-once failures (check `journalctl --user -b -n 200`) and lua parse errors (run `Hyprland --verify-config`).

---

## Editing DOORway

**Important:** the deployed paths under `~/.config/`, `~/.local/lib/doorway/`, etc. are read-only Nix store symlinks. You can't edit them directly — `EROFS: read-only file system` is the error you'll get.

To make a change:

1. Edit the corresponding source file under `Configs/` in this repo.
2. Rebuild: `sudo nixos-rebuild switch --flake ~/path/to/your/system-flake#<hostname>`
3. For Hyprland-only changes, `hyprctl reload` picks up the new config without a logout.

The full story (why this is so, where runtime-writes from scripts have to go to avoid EROFS, and the whole-dir vs individual-file-symlink distinction) is in [CLAUDE.md's Nix Store Workflow](../CLAUDE.md#nix-store-workflow--critical). That's the contributor manual; this article is consumer-facing.

---

## Updating DOORway

`flake.lock` pins DOORway to a specific commit. To pull newer changes:

```bash
nix flake update doorway
sudo nixos-rebuild switch --flake .#<hostname>
```

Or `nix flake update` (no argument) to update every input in the lockfile at once.

### Gotcha for contributors

If you're hacking on DOORway itself (editing in this repo and wanting to test changes in HALLway or another consumer), **local uncommitted changes are invisible to Nix.** The flake evaluator clones from the git remote. Workflow:

```bash
# In DOORway:
git commit -am "..."
git push

# In your consumer flake:
nix flake update doorway
sudo nixos-rebuild switch --flake .#<host>
```

`nix flake update` before `git push` will silently reuse the previous commit. The CLAUDE.md "Flake-based deploy workflow" section has the full story.

---

## Using DOORway inside HALLway

HALLway is the NixOS flake that bundles a full operating system around DOORway. From DOORway's perspective, HALLway is just one consumer — it uses the same `inputs.doorway.homeManagerModules.default` pattern any other Nix user would. There's no special "HALLway mode" inside this repo.

If you're already on HALLway, DOORway is already enabled. You shouldn't need to do anything to install it; configuration (monitors, keyboard, etc.) is set in HALLway's flake.

For HALLway-specific deployment workflow (how HALLway pins DOORway, when to `nix flake update doorway`, etc.), see the HALLway repository's own documentation.

---

## What to read next

- **Your desktop launched but you're not sure what you're looking at** → [Interface-Tour.md](Interface-Tour.md)
- **Memorize the keyboard shortcuts** → [Keybindings-Primer.md](Keybindings-Primer.md)
- **The session won't start or shows the emergency banner** → [Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md)
- **You want to write new DOORway scripts or edit existing ones** → [CLAUDE.md](../CLAUDE.md) (contributor manual)
