# DOORway Wiki

Long-form documentation for DOORway. The repository [README](../README.md) covers what most users need to install and run the desktop. This wiki is for when you're going deeper — troubleshooting, internals, the scripting API, and the design decisions behind the lua migration.

## Current Articles

### Getting started (read in order)

- [**Introduction**](Introduction.md) — what DOORway is, who it's for, what's in the box, how it relates to upstream HyDE and HALLway, the three load-bearing design ideas.
- [**Using DOORway with Nix**](Using-DOORway-with-Nix.md) — a 60-second flakes intro, the full flake integration walkthrough, the core module options, what gets deployed at activation.
- [**Interface Tour**](Interface-Tour.md) — what you see after first login: the QuickShell bar, both sidebars, the session screen, anyrun pickers, DOORway Lock, the cartridge light/dark modes, and where state files live.
- [**Keybindings Primer**](Keybindings-Primer.md) — a by-use-case tour of the keyboard shortcuts: essentials, window management, workspaces, launchers, screenshots, media, theming, system control, and mouse bindings.
- [**Troubleshooting Hyprland**](Troubleshooting-Hyprland.md) — diagnosing lua config errors, backend / seat crashes, distinguishing DOORway bugs from HALLway / NixOS bugs, log paths, worked examples.

### Internals & reference

- [**Architecture Overview**](Architecture-Overview.md) — the three runtime layers, the lua orchestrator chain, the QuickShell surface map, the declarative systemd unit fleet, the IPC topology, and `doorway-shell`.
- [**Theming**](Theming.md) — the two-system split: the committed `DoorwayPalette.qml` cartridge modes (shell) and the matugen wallpaper → Hyprland-border pipeline; how `Appearance.qml` maps modes to Material schemes.
- [**Scripting API**](Scripting-API.md) — the `doorway-shell` dispatcher, `DOORWAY_SCRIPTS_PATH`, the `DOORWAY_SHELL_INIT` guard, the script library, and the removed vestigial HyDE binaries.
- [**Keybindings Reference**](Keybindings-Reference.md) — the binding system: `hl.bind` shape, the `[Group\|Sub]` description contract that feeds the hint, and how to regenerate a full index.
- [**Hyprland Lua API Cheatsheet**](Hyprland-Lua-API-Cheatsheet.md) — every `hl.*` call this repo uses, the exact shape each expects, and what does *not* exist on 0.55.1.
- [**Lua Migration Notes**](Lua-Migration-Notes.md) — why the config is lua, what changed semantically (`repeat` → `repeating`, dispatcher namespacing, the `hl.source` gap), and how to port upstream HyDE `.conf` changes.

## Contributing to the Wiki

- One topic per file. Cross-link liberally.
- Aim for self-contained articles — readers should be able to land on a single page from a search engine and get a useful answer.
- Real examples beat abstract description. If you can paste a real diagnostic output and walk through it, do that.
- Verify any command you reference still works on the pinned Hyprland version (see `flake.nix`).
