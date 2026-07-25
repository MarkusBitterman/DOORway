# DOORway Testing Guide

DOORway is NixOS-only. The upstream HyDE install-script workflow does not apply.

## Quick Sanity Checks

After any change to shell scripts or `flake.nix`:

```bash
# 1. Lint shell scripts:
shellcheck Configs/.local/lib/doorway/*.sh

# 2. Validate the Hyprland Lua config from SOURCE (no rebuild needed):
XDG_DATA_HOME=$PWD/Configs/.local/share \
  Hyprland --verify-config -c $PWD/Configs/.config/hypr/hyprland.lua

# 3. Check the deployed QuickShell surface for new warnings:
journalctl --user -u doorway-quickshell.service -b --no-pager | grep -vE "DEBUG|INFO"
```

`nix develop` sets the PATH and XDG env vars needed for script testing.

---

## Testing Without Logging Out

### Hyprland (nested)

Use an XFCE Wayland session as the outer compositor. From a terminal there:

```bash
# Recommended — sets env automatically:
nix develop

# Or export manually:
export PATH="$HOME/.local/lib/doorway:$PATH"
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CURRENT_DESKTOP=Hyprland
```

| Goal | Method | Caveats |
|------|--------|---------|
| Visual checks (bar, wallpaper) | `start-hyprland` | Keyboard dead in nested mode — expected |
| Keybinding tests | TTY login (`Ctrl+Alt+F2`) | Full native session required |
| GPU / DRM features | TTY login | Needs real KMS backend |
| Config parse | `Hyprland --verify-config` | Can run anywhere |
| exec-once behavior | Native login | Startup daemons are declarative systemd units — also testable via `systemctl --user` |

> ⚠️ `start-hyprland` only works inside a running Wayland compositor.
> libseat's builtin backend cannot open `/dev/input/*` in nested mode — keyboard
> input will be completely dead. This is expected, not a DOORway bug.

### QuickShell (nested instance against the working tree)

Run a second shell instance directly from the repo — no rebuild needed. Borrow the
env from the deployed service (it carries Nix store paths your shell doesn't have):

```bash
systemctl --user show doorway-quickshell.service -p Environment
QML_IMPORT_PATH=<from-service> qs -p ~/Developments/DOORway/Configs/.config/quickshell/doorway
```

Caveats (see CLAUDE.md for the full story):

- The nested instance overlaps the deployed one at identical coordinates — stop
  `doorway-quickshell.service` before screenshotting with `grim`.
- Hot reload masks cold-start bugs (first-paint color capture, init races).
  Always verify with a fresh instance launch.
- DOORway Lock has a dedicated harness: `DOORWAY_LOCK_TEST=1 qs -p <repo config>`
  (Ctrl+L lock, Ctrl+N shader, Ctrl+U unlock — real PAM, zero lockout risk).

---

## Debugging a Hyprland Session

### Empty desktop (no bar, no wallpaper, no daemons)

```bash
# Step 0 — parse the config (catches most failures without a session):
Hyprland --verify-config

# Step 1 — check the Hyprland log (stdout is disabled after init):
cat /run/user/$(id -u)/hypr/*/hyprland.log | grep -v "DEBUG from aquamarine"

# Step 2 — check the declarative user services (daemons no longer launch via exec-once):
systemctl --user --failed
journalctl --user -b -n 200 | grep -iE "(quickshell|doorway|hypr)"
```

### After a rebuild deploys changes

Log into a native Hyprland session (or restart the user services) and verify:

- QuickShell bar renders: `systemctl --user status doorway-quickshell.service`
- Wallpaper appears
- `notify-send test` triggers a QuickShell notification popup
- `Super + Q` closes a focused window (keybindings are always registered)

Remember to `systemctl --user restart doorway-quickshell.service` after a switch —
Home Manager does not reliably restart user services.

---

## NixOS Rebuild Workflow

DOORway deploys through HALLway's flake.lock — **local changes are invisible
until pushed**:

```bash
# In DOORway:
git commit && git push

# In HALLway (~/Developments/HALLway):
nix flake update doorway
nix run .   # auto-detects the host and runs the matching switch command
```

---

## What Gets Tested

| Test | Tool | What it catches |
|------|------|----------------|
| Lua parse | `Hyprland --verify-config` | Syntax errors, nil `hl.*` API calls, type mismatches |
| Shell lint | `shellcheck Configs/.local/lib/doorway/*.sh` | Shell script bugs |
| QML surface | journal warning diff before/after deploy | Dead imports, missing icons, orphaned service references |
| Runtime startup | Native Hyprland login / `systemctl --user` | Service crashes, env problems |

> **Note:** QML failure modes are silent by design — placeholder textures load
> "successfully" and scanners "ignore" broken imports. The journal is the primary
> diagnostic instrument, not the screen. See CLAUDE.md § Working with logs.
