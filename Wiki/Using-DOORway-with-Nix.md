# Using DOORway with Nix

This article gets DOORway running on your NixOS system. There are two paths — the flake-based path (recommended, declarative, rollback-safe) and the manual setup script (good for trying it without touching your system configuration).

If you've never written a Nix flake before, start at the next section. If you're already running flakes for your NixOS config, [skip ahead](#1-add-doorway-as-a-flake-input).

---

## At a glance

| Path | When to use it | What you get | What you commit to |
|---|---|---|---|
| **Flake + Home Manager module** (recommended) | You already manage NixOS declaratively, or you're ready to start | Reproducible, rollback-able, version-pinned desktop that comes back identically on every machine | A few lines in `flake.nix` + an import in `home.nix` |
| **`Scripts/setup-nixos.sh`** | You want to try DOORway before adopting it, or you don't use flakes yet | A working DOORway session running from symlinks into a cloned repo | A clone of this repo somewhere on disk; you handle package installation separately |

The flake path is what HALLway uses and what we test against. The manual path is supported but rougher around the edges.

---

## A 60-second tour of Nix flakes

A **flake** is a self-contained Nix project with three parts:

1. **Inputs** — other flakes (or sources) it depends on, pinned to specific commits in a generated `flake.lock` file. This is what makes builds reproducible: everyone using the flake at a given lock version gets bit-identical inputs.
2. **Outputs** — things the flake produces. Packages, NixOS modules, Home Manager modules, devShells, library functions, anything Nix can express.
3. **`flake.nix`** — the manifest tying inputs and outputs together. Pure Nix; no side effects.

DOORway is a flake. Its `inputs` are just `nixpkgs/nixos-unstable`. Its `outputs` are:

- `homeManagerModules.default` — the Home Manager module you import (also exposed as `homeManagerModules.doorway`)
- `devShells.default` — a `nix develop` shell with Hyprland, linters, formatters, and helpers (for hacking on DOORway itself)
- `lib.doorwayDeps` — the dependency package list, exposed for downstream flakes (HALLway) to reuse

Why a flake and not a tarball: pinned inputs mean the version of Hyprland that DOORway was tested against is the version you actually get. No "works on my machine" because the lock file makes the machine the same.

When you'd still prefer the manual script: you don't yet have a flake-managed NixOS system and you want to evaluate DOORway before adopting flakes generally. The script gets you running without changing how the rest of your system is built.

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

All defined in `flake.nix` (lines 77–105 if you want to read the source):

| Option | Type | Default | What it does |
|---|---|---|---|
| `doorway.enable` | bool | `false` | Master toggle. Nothing else happens unless this is `true`. |
| `doorway.monitor` | string | `",preferred,auto,1"` | Primary monitor configuration in Hyprland's `output,mode,position,scale` format. Parsed into `hl.monitor({...})` in the generated `monitors.lua`. |
| `doorway.extraMonitors` | list of strings | `[]` | Additional monitors, same format as `monitor`. One entry per extra display. |
| `doorway.keyboard` | string | `"us"` | xkb keyboard layout. Injected into the generated `userprefs.lua` as `kb_layout`. |
| `doorway.installPackages` | bool | `true` | Whether to add DOORway's runtime dependencies (hyprland, waybar, rofi, dunst, etc.) to `home.packages`. Set to `false` if you install them at the NixOS system level instead. |

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

By default the module adds all of DOORway's runtime dependencies (hyprland, waybar, rofi, dunst, hyprlock, hypridle, kitty, grim/slurp, brightnessctl, etc.) to `home.packages` so a clean Home Manager activation gives you a fully working desktop with no further package management.

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
| `hypr/shaders.lua` | `Configs/.config/hypr/shaders.lua` (read-only) |
| `hypr/hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf`, `nvidia.conf` | corresponding source `.conf` files |
| `hypr/{animations,shaders,themes,workflows,hyprlock}/` | corresponding source directories |
| `hypr/monitors.lua` | **generated** from your `doorway.monitor` + `extraMonitors` options |
| `hypr/userprefs.lua` | **generated** from your `doorway.keyboard` option (and a few sensible defaults) |

The generated files are real files Home Manager writes (not symlinks), which is why they can coexist with the symlinked source files — a whole-directory symlink to the Nix store would have been read-only and prevented this.

### Other app configs (`~/.config/<app>/`)

Whole-directory symlinks into the Nix store (these don't need generated files alongside them):

- `~/.config/rofi/` → `Configs/.config/rofi/`
- `~/.config/dunst/` → `Configs/.config/dunst/`
- `~/.config/doorway/` → `Configs/.config/doorway/`
- `~/.config/kitty/` → `Configs/.config/kitty/`
- `~/.config/wlogout/` → `Configs/.config/wlogout/`

Notable absence: **waybar's config directory is intentionally not Nix-managed.** `waybar.py` (one of the scripts in `~/.local/lib/doorway/`) generates `~/.config/waybar/{config.jsonc,style.css,includes/}` at runtime from layout templates in `~/.local/share/waybar/`. This is what makes `SUPER + ALT + ↑/↓` (cycle waybar layouts) work without a NixOS rebuild. See [Introduction § The bar is its own thing](Introduction.md#3-the-bar-is-its-own-thing-owned-by-waybarpy) for the rationale.

### User binaries and libraries (`~/.local/`)

- `~/.local/bin/doorway-shell` (executable)
- `~/.local/bin/doorwayctl` (executable)
- `~/.local/bin/doorway-ipc` (executable)
- `~/.local/lib/doorway/` → ~80 utility scripts (theme, screenshot, wallpaper, volume, etc.)
- `~/.local/share/doorway/` → data files, schemas, theme registry
- `~/.local/share/hypr/` → lua orchestrator + startup/env/dynamic/variables modules
- `~/.local/share/waybar/` → waybar layout templates (the source `waybar.py` reads)

### PATH

`home.sessionPath = [ "$HOME/.local/bin" "$HOME/.local/lib/doorway" ];` — so `doorway-shell <subcommand>` and the individual script names work from any terminal in your session.

### Hyprland config type

`wayland.windowManager.hyprland.configType = "lua";` — this tells Home Manager's Hyprland module to expect lua, not hyprlang. Important if you also use Home Manager's `wayland.windowManager.hyprland.settings = { ... }` API elsewhere (you probably don't, because we're doing everything via the lua files).

### What you'll see at runtime

On first login after `nixos-rebuild switch`, you'll see the wallpaper come up, then the waybar at the top, then a brief moment as services warm up (clipboard daemons, notifications, network applet, etc.). Total cold-start to "everything responsive" is typically 1–3 seconds on modern hardware.

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

## The manual setup script

For users who haven't adopted flakes yet, or who want to try DOORway without touching their system config:

```bash
git clone https://github.com/MarkusBitterman/DOORway.git ~/DOORway
cd ~/DOORway/Scripts
./setup-nixos.sh
```

What it does:

- Checks that you're on NixOS and that the required packages are present (hyprland, waybar, rofi, dunst, hyprlock, hypridle, kitty).
- Symlinks every relevant directory from `~/DOORway/Configs/` into `~/.config/`, `~/.local/lib/`, `~/.local/share/`, and `~/.local/bin/`.
- Reports anything that conflicted so you can decide whether to back up your existing dotfiles.

Flags worth knowing:

- `--dry-run` — print what it would symlink without touching the filesystem
- `--force` — overwrite existing files / symlinks at the target paths
- `--help` — flag list

This path does **not** install the runtime packages — you need to ensure hyprland, waybar, rofi, dunst, hyprlock, hypridle, kitty (and the rest of the dependency list — see [`flake.nix` `doorwayDeps`](../flake.nix)) are available at the NixOS system level yourself.

Use this for evaluation. If you stick with DOORway, migrating to the flake path is recommended: it handles packages, is rollback-safe, and is what we test against.

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
