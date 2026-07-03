{
  description = "DOORway - Hyprland Desktop Environment for HALLway OS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hyprland = {
      # Unpinned 2026-06-30: tracks latest Hyprland main now that the pango fix
      # for hyprgraphics' TextResource.hpp landed upstream (Hyprland and
      # hyprland-guiutils both declare pango in their Nix buildInputs). Re-pin to
      # a known-good rev here if main ever breaks the build again.
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      hyprland,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # DOORway runtime dependencies
      doorwayDeps =
        pkgs: with pkgs; [
          # Core Hyprland ecosystem
          pkgs.hyprland # explicit: 'hyprland' resolves to flake input via outer scope, not pkgs.hyprland
          hyprlock
          hypridle
          hyprpaper

          # UI components
          anyrun # app launcher (Super+A); replacing rofi — see TODO.md migration
          rofi # dmenu-style picker backend for ~20 script flows until migrated

          # Utilities
          grim
          slurp
          satty
          cliphist
          awww

          # System integration
          brightnessctl
          ddcutil # DDC/CI brightness for external monitors — Brightness.qml probes
          # `ddcutil detect` at shell start and falls back to brightnessctl (laptop
          # backlights only) when absent. Requires i2c access from nixosModules.default.
          wlopm # zwlr_output_power_manager_v1 — used by hypridle DPMS listener
          playerctl
          pamixer
          cava # console audio visualizer — real FFT spectrum for the QuickShell Cava service + hyprlock
          libnotify
          # gnome-keyring: provided by nixosModules.default (services.gnome.gnome-keyring.enable
          # + security.pam.services.greetd.enableGnomeKeyring) — not needed in home packages
          polkit_gnome # Polkit auth agent (declarative in Pass 6)

          # Applets (system tray daemons started by startup.lua)
          wl-clipboard # wl-paste for cliphist text/image clipboard watch
          udiskie # removable media tray applet
          networkmanagerapplet # nm-applet --indicator
          blueman # blueman-applet bluetooth tray

          # Terminal
          kitty

          # Optional
          hyprsunset

          # Initiative II — QuickShell shell + matugen color theming
          quickshell # QML/Qt6 desktop shell toolkit
          matugen # Material You color generation from wallpaper

          # Weather fetch script (doorway-pirateweather.py uses requests)
          (python3.withPackages (ps: [ ps.requests ]))
          inotify-tools # inotifywait for doorway-matugen-watcher
          material-symbols # Google Material Symbols variable font (used by MaterialSymbol.qml)
          # Nerd Fonts — declared by name in doorway.fonts (bar/menu/groupbar, monospace,
          # workspace glyphs) but never packaged, so fc-match fell back to DejaVu Sans and
          # Nerd glyphs rendered as blank/incorrect boxes. nixpkgs is nixos-unstable, so the
          # dotted `nerd-fonts.*` namespace is correct.
          nerd-fonts.jetbrains-mono # "JetBrainsMono Nerd Font" — bar/menu/groupbar + workspace glyphs
          nerd-fonts.caskaydia-cove # "CaskaydiaCove Nerd Font Mono" — monospace default
          nerd-fonts.symbols-only # "Symbols Nerd Font" — symbol-range fallback coverage
          departure-mono # "Departure Mono" — DOORway signature retro pixel-mono display font
        ];

      # Development dependencies
      devDeps =
        pkgs: with pkgs; [
          # Shell
          shellcheck
          shfmt

          # Nix
          nil # Nix LSP
          nixfmt # Nix formatter

          # Python
          python3
          ruff # Python linter/formatter

          # General
          git
          direnv

          # MCP server runtimes (Claude Code)
          nodejs # provides npx for @modelcontextprotocol/server-github
          uv # provides uvx for mcp-server-git
        ];

      # Home Manager module definition
      doorwayModule =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.doorway;
          configDir = "${self}/Configs";

          # Shared template for DOORway long-running services. All graphical-
          # session-dependent services use Type=exec, ExitType=cgroup, the
          # app-graphical.slice, and the graphical-session.target lifecycle.
          # Callers supply description + execStart (and optionally execStartPre,
          # documentation). See TODO.md Phase 9 Pass 2 design decisions.
          mkDoorwayService =
            {
              description,
              execStart,
              execStartPre ? null,
              execCondition ? null,
              conditionPathExistsGlob ? null,
              documentation ? null,
            }:
            {
              Unit = {
                Description = description;
                After = [ "graphical-session.target" ];
                PartOf = [ "graphical-session.target" ];
              }
              // lib.optionalAttrs (documentation != null) {
                Documentation = documentation;
              }
              // lib.optionalAttrs (conditionPathExistsGlob != null) {
                ConditionPathExistsGlob = conditionPathExistsGlob;
              };
              Service = {
                Type = "exec";
                ExitType = "cgroup";
                Slice = "app-graphical.slice";
                Restart = "always";
                RestartSec = 1;
                ExecStart = execStart;
              }
              // lib.optionalAttrs (execStartPre != null) {
                ExecStartPre = execStartPre;
              }
              // lib.optionalAttrs (execCondition != null) {
                ExecCondition = execCondition;
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };

          # Oneshot variant for session-bootstrap actions: portal restart,
          # config initialization, etc. RemainAfterExit=true so graphical-
          # session.target sees them as "active" not "exited" after completion.
          # Watches ~/.cache/doorway/wall.set for symlink replacement (ln -fs
          # uses rename(2) → inotify fires moved_to). Runs matugen to generate
          # Material You color files, then signals Hyprland to reload so
          # dynamic.lua picks up the new hyprland-colors.lua via dofile().
          matugenWatcherScript = pkgs.writeShellScript "matugen-watcher" ''
            set -euo pipefail
            WALL="''${XDG_CACHE_HOME:-$HOME/.cache}/doorway/wall.set"
            WATCH_DIR="$(dirname "$WALL")"

            run_matugen() {
              local wp
              wp="$(readlink -f "$WALL")" || return
              [[ -f "$wp" ]] || return
              ${pkgs.matugen}/bin/matugen image --source-color-index 0 "$wp"
              # Reload Hyprland so dynamic.lua re-dofiles hyprland-colors.lua.
              # Fails silently outside a live session (e.g. on first nixos-rebuild).
              ${pkgs.hyprland}/bin/hyprctl reload 2>/dev/null || true
            }

            # Run once at service start for the already-set wallpaper.
            run_matugen || true

            # ln -fs fires moved_to on the parent dir; watch for wall.set.
            ${pkgs.inotify-tools}/bin/inotifywait \
              -m -q -e moved_to,create --format '%f' "$WATCH_DIR" |
            while IFS= read -r fname; do
              [[ "$fname" == "wall.set" ]] || continue
              run_matugen || true
            done
          '';

          # Returns a home.activation entry that copies (not symlinks) a file,
          # making it writable at runtime. Merge the result into home.activation.
          # Example: home.activation = mkMutableHomeFile { path = ".config/foo/bar"; source = ./bar; };
          mkMutableHomeFile =
            {
              path,
              source,
              mode ? "0644",
            }:
            let
              name = "mkMutable-" + builtins.replaceStrings [ "/" "." ] [ "-" "_" ] path;
            in
            {
              "${name}" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                install -Dm${mode} "${source}" "$HOME/${path}"
              '';
            };

          mkDoorwayOneshot =
            {
              description,
              execStart,
              after ? [ ],
              documentation ? null,
            }:
            {
              Unit = {
                Description = description;
                After = [ "graphical-session.target" ] ++ after;
                PartOf = [ "graphical-session.target" ];
              }
              // lib.optionalAttrs (documentation != null) {
                Documentation = documentation;
              };
              Service = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = execStart;
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };
        in
        {
          options.doorway = {
            enable = lib.mkEnableOption "DOORway Hyprland configuration";

            monitor = lib.mkOption {
              type = lib.types.str;
              default = ",preferred,auto,1";
              example = "HDMI-A-1,1920x1080@100,0x0,1";
              description = "Primary monitor configuration";
            };

            extraMonitors = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [ "DP-1,2560x1440@144,1920x0,1" ];
              description = "Additional monitor configurations";
            };

            keyboard = lib.mkOption {
              type = lib.types.str;
              default = "us";
              description = "Keyboard layout";
            };

            installPackages = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Install DOORway dependencies";
            };

            cursor = {
              package = lib.mkOption {
                type = lib.types.package;
                default = pkgs.oreo-cursors-plus;
                description = "Nix package providing the cursor theme files.";
              };
              name = lib.mkOption {
                type = lib.types.str;
                default = "oreo_spark_pink_cursors";
                example = "oreo_blue_cursors";
                description = ''
                  Cursor theme name as it appears under share/icons/ in the cursor package.
                  All 38 oreo-cursors-plus variants: oreo_{black,blue,grey,pink,purple,red,teal,white}_cursors
                  (plain), oreo_spark_{blue,green,light_pink,lime,orange,pink,purple,red,violet}_cursors
                  (animated), and oreo_spark_*_bordered_cursors (animated with outline).
                '';
              };
              size = lib.mkOption {
                type = lib.types.ints.positive;
                default = 24;
                description = "Cursor size in pixels.";
              };
            };

            shell = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                  Enable the DOORway QuickShell UI shell.
                  Leave false until Phase 12 cutover (top bar parity with waybar).
                  When true, starts doorway-quickshell.service after graphical-session.target.
                '';
              };
            };

            idle = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable the DOORway idle daemon (hypridle).";
              };
              timeouts = {
                dim = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 60;
                  description = "Seconds of idle before dimming the display.";
                };
                lock = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 120;
                  description = "Seconds of idle before locking the session.";
                };
                dpms = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 300;
                  description = "Seconds of idle before turning off the display (DPMS).";
                };
                suspend = lib.mkOption {
                  type = lib.types.nullOr lib.types.ints.positive;
                  default = 500;
                  description = "Seconds of idle before suspending. Set to null to disable suspend entirely.";
                };
              };
            };

            fonts = {
              ui = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = "Cantarell";
                  description = "UI font family (dialogs, GTK apps, general text). Maps to FONT + DOCUMENT_FONT in variables.lua.";
                };
                size = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 10;
                  description = "UI font size in points.";
                };
              };
              monospace = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = "CaskaydiaCove Nerd Font Mono";
                  description = "Monospace font family (terminal, code editors). Maps to MONOSPACE_FONT in variables.lua.";
                };
                size = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 9;
                  description = "Monospace font size in points.";
                };
              };
              interface = lib.mkOption {
                type = lib.types.str;
                default = "JetBrainsMono Nerd Font";
                description = "Font for the bar, rofi menus, and Hyprland groupbar. Maps to BAR_FONT, MENU_FONT, GROUPBAR_FONT in variables.lua.";
              };
              sidebar = lib.mkOption {
                type = lib.types.str;
                default = "Cantarell";
                description = ''
                  Font for QuickShell sidebar content (Phase 14 left/right sidebars).
                  A reading font like Spectral or Atkinson Hyperlegible works well here.
                  Set to the same value as fonts.ui.name to keep a unified look.
                '';
              };
            };

            animations = {
              preset = lib.mkOption {
                type = lib.types.enum [
                  "classic"
                  "diablo-1"
                  "diablo-2"
                  "disable"
                  "dynamic"
                  "end4"
                  "fast"
                  "high"
                  "ja"
                  "LimeFrenzy"
                  "me-1"
                  "me-2"
                  "minimal-1"
                  "minimal-2"
                  "moving"
                  "optimized"
                  "standard"
                  "theme"
                  "vertical"
                ];
                default = "standard";
                example = "fast";
                description = ''
                  Animation preset to load from animations/ in the Hyprland config.
                  Each preset is a self-contained lua file that calls hl.config({ animations = {...} }).
                  "disable" turns off all animations. "fast" is recommended for low-latency gaming.
                '';
              };
            };

            lock = {
              layout = lib.mkOption {
                type = lib.types.enum [
                  "DOORway"
                  "Anurati"
                  "Arfan on Clouds"
                  "greetd"
                  "greetd-wallbash"
                  "IBM Plex"
                  "IMB Xtented"
                  "SF Pro"
                ];
                default = "DOORway";
                example = "Anurati";
                description = ''
                  Hyprlock layout preset. Presets live in ~/.config/hypr/hyprlock/.
                  "DOORway" uses wallbash colors derived from the current wallpaper.
                  "greetd-wallbash" matches the login screen palette.
                '';
              };
            };

            theme = {
              gapsIn = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 3;
                description = "Inner gap between tiled windows in pixels.";
              };
              gapsOut = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 8;
                description = "Outer gap between windows and the screen edge in pixels.";
              };
              borderSize = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 2;
                description = "Window border width in pixels. 0 disables borders entirely.";
              };
              rounding = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 10;
                description = "Window corner rounding radius in pixels. 0 disables rounding.";
              };
              layout = lib.mkOption {
                type = lib.types.enum [
                  "dwindle"
                  "master"
                ];
                default = "dwindle";
                description = ''
                  Default window tiling layout algorithm.
                  "dwindle" splits windows recursively (similar to i3/sway default).
                  "master" keeps one dominant window on the left with a stack on the right.
                '';
              };
              blur = {
                enabled = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Enable background blur behind transparent windows and layers (waybar, rofi, etc.).";
                };
                size = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 6;
                  description = "Blur kernel radius. Larger values are blurrier but more GPU-intensive.";
                };
                passes = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 3;
                  description = "Number of blur passes. More passes produce a smoother, higher-quality blur.";
                };
              };
              iconTheme = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = "Tela-dracula";
                  description = ''
                    Icon theme name as it appears under share/icons/ in the icon theme package.
                    tela-icon-theme variants (each also has -dark and -light suffix):
                    Tela, Tela-black, Tela-blue, Tela-brown, Tela-dracula, Tela-green,
                    Tela-grey, Tela-manjaro, Tela-nord, Tela-orange, Tela-pink,
                    Tela-purple, Tela-red, Tela-ubuntu, Tela-yellow.
                  '';
                };
                package = lib.mkOption {
                  type = lib.types.package;
                  default = pkgs.tela-icon-theme;
                  description = "Nix package providing the icon theme.";
                };
              };
            };

            bar = {
              topLeftIcon = lib.mkOption {
                type = lib.types.str;
                default = "distro";
                description = ''
                  Icon shown in the top-left sidebar button.
                  "distro" auto-detects the running distro (nixos-symbolic, arch-symbolic, etc.).
                  Any other string is used as "<name>-symbolic" and looked up first in the icon
                  theme, then in assets/icons/ (supports both .svg and .png assets).
                '';
              };
            };

            input = {
              numlock = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable NumLock by default on session start.";
              };
              accelProfile = lib.mkOption {
                type = lib.types.enum [
                  "flat"
                  "adaptive"
                  "custom"
                ];
                default = "flat";
                description = ''
                  Mouse acceleration profile.
                  "flat" disables acceleration (raw input — recommended for gaming).
                  "adaptive" applies speed-sensitive acceleration (Hyprland default).
                  "custom" requires additional libinput configuration.
                '';
              };
              naturalScroll = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable natural (reversed) scrolling direction on the touchpad.";
              };
              activeOpacity = lib.mkOption {
                type = lib.types.numbers.between 0.0 1.0;
                default = 0.9;
                description = "Opacity of the focused/active window. 1.0 = fully opaque, 0.0 = invisible.";
              };
              inactiveOpacity = lib.mkOption {
                type = lib.types.numbers.between 0.0 1.0;
                default = 0.75;
                description = "Opacity of unfocused/inactive windows. 1.0 = fully opaque.";
              };
            };

            blueLight = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable the blue-light filter daemon (hyprsunset). Reduces eye strain in the evening.";
              };
              temperature = lib.mkOption {
                type = lib.types.ints.between 1000 10000;
                default = 3500;
                example = 2700;
                description = ''
                  Night-mode color temperature in Kelvin.
                  Lower is warmer/redder: 2700K (incandescent), 3500K (warm white), 5500K (neutral), 6500K (daylight).
                '';
              };
              schedule = {
                dayTime = lib.mkOption {
                  type = lib.types.str;
                  default = "06:00";
                  description = "Time (HH:MM, 24-hour) to restore daylight colors.";
                };
                nightTime = lib.mkOption {
                  type = lib.types.str;
                  default = "21:00";
                  description = "Time (HH:MM, 24-hour) to apply the night-mode temperature.";
                };
                useWeatherTimes = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = ''
                    When true (and doorway.weather.enable is set), use today's actual
                    sunrise/sunset from PirateWeather instead of the fixed dayTime/nightTime.
                    Night light turns on at sunset and off at sunrise, adapting across seasons.
                  '';
                };
              };
            };

            bluetooth = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable the Bluetooth tray applet (blueman-applet). Disable if using a different Bluetooth manager.";
              };
            };

            networkApplet = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable the NetworkManager tray applet (nm-applet --indicator). Disable if using iwgtk or another frontend.";
              };
            };

            removableMedia = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable the removable-media tray applet (udiskie). Provides auto-mount prompts for USB drives and SD cards.";
              };
            };

            weather = {
              enable = lib.mkEnableOption "DOORway PirateWeather bar widget and periodic fetch service";
              zipCode = lib.mkOption {
                type = lib.types.str;
                default = "";
                example = "52240";
                description = "US ZIP code (or postal code if country is set). Geocoded to lat/long via Nominatim on first run; result is cached at ~/.cache/doorway/weather-location.json.";
              };
              updateFrequency = lib.mkOption {
                type = lib.types.ints.positive;
                default = 15;
                description = "How often (in minutes) the systemd timer fires to refresh weather data.";
              };
              pirateWeatherApiKeyFile = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = ''
                  Path to a file containing the PirateWeather API key in systemd EnvironmentFile format:
                    PIRATE_WEATHER_API_KEY=your_key_here
                  With sops-nix in HALLway: osConfig.sops.secrets."pirate_weather_api_key".path
                  Obtain a key at https://pirateweather.net
                '';
              };
              units = lib.mkOption {
                type = lib.types.enum [
                  "us"
                  "si"
                  "ca"
                  "uk2"
                ];
                default = "us";
                description = "'us' = °F/mph, 'si' = °C/m/s, 'ca' = °C/km/h, 'uk2' = °C/mph";
              };
            };
          };

          config = lib.mkIf cfg.enable {
            wayland.windowManager.hyprland = {
              configType = "lua";
              package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
            };

            home.packages = lib.mkIf cfg.installPackages (doorwayDeps pkgs);

            xdg.configFile = {
              # Individual file links instead of a directory symlink, so the
              # generated monitors.lua and userprefs.lua (below) can be placed
              # alongside them — a directory symlink to the Nix store is immutable.
              "hypr/hyprland.lua".source = "${configDir}/.config/hypr/hyprland.lua";
              "hypr/keybindings.lua".source = "${configDir}/.config/hypr/keybindings.lua";
              "hypr/windowrules.lua".source = "${configDir}/.config/hypr/windowrules.lua";
              "hypr/workflows.lua".source = "${configDir}/.config/hypr/workflows.lua";
              "hypr/animations.lua".source = "${configDir}/.config/hypr/animations.lua";
              "hypr/shaders.lua".source = "${configDir}/.config/hypr/shaders.lua";
              "hypr/hypridle.conf".text = ''
                $LOCK_CMD = doorway-shell lockscreen.sh
                $UNLOCK_CMD = sh -c 'sleep 3 && pkill -9 $(doorway-shell lockscreen --get)'

                general {
                    lock_cmd = $LOCK_CMD
                    unlock_cmd = $UNLOCK_CMD
                    ignore_dbus_inhibit = false
                    ignore_systemd_inhibit = false
                }

                listener {
                    timeout = ${toString cfg.idle.timeouts.dim}
                    on-timeout = brightnessctl -s && brightnessctl s 1%
                    on-resume = brightnessctl -r
                }

                listener {
                    timeout = ${toString cfg.idle.timeouts.lock}
                    on-timeout = loginctl lock-session
                }

                listener {
                    timeout = ${toString cfg.idle.timeouts.dpms}
                    on-timeout = wlopm --off '*'
                    on-resume = wlopm --on '*'
                }

                ${lib.optionalString (cfg.idle.timeouts.suspend != null) ''
                  listener {
                      timeout = ${toString cfg.idle.timeouts.suspend}
                      on-timeout = systemctl suspend-then-hibernate
                  }
                ''}

                # hyprlang noerror true
                source = ./hypridle/*
                # hyprlang noerror false
              '';
              "hypr/hyprlock.conf".text = ''
                # DOORway Lock Screen Configuration (generated by Home Manager)
                # Set via doorway.lock.layout in your home config.
                $LAYOUT_PATH=$HOME/.config/hypr/hyprlock/${cfg.lock.layout}.conf
                source = $HOME/.local/share/hypr/hyprlock.conf
              '';
              "hypr/hyprsunset.conf".text = ''
                # DOORway Blue-Light Filter Configuration (generated by Home Manager)
                # Set via doorway.blueLight in your home config.

                # Day profile: restore screen to native colors
                profile {
                    time = ${cfg.blueLight.schedule.dayTime}
                    identity = true
                }

                # Night profile: apply warm temperature
                profile {
                    time = ${cfg.blueLight.schedule.nightTime}
                    temperature = ${toString cfg.blueLight.temperature}
                }
              '';
              "hypr/nvidia.conf".source = "${configDir}/.config/hypr/nvidia.conf";
              "hypr/animations".source = "${configDir}/.config/hypr/animations";
              "hypr/shaders".source = "${configDir}/.config/hypr/shaders";
              "hypr/themes".source = "${configDir}/.config/hypr/themes";
              "hypr/workflows".source = "${configDir}/.config/hypr/workflows";
              "hypr/hyprlock".source = "${configDir}/.config/hypr/hyprlock";
              "rofi".source = "${configDir}/.config/rofi";
              "anyrun".source = "${configDir}/.config/anyrun";
              # Individual links (not a whole-dir symlink) so the QuickShell
              # runtime config.json can live alongside them — ~/.config/doorway
              # must be a real, writable directory.
              "doorway/config.toml".source = "${configDir}/.config/doorway/config.toml";
              "doorway/wallbash".source = "${configDir}/.config/doorway/wallbash";
              "kitty".source = "${configDir}/.config/kitty";

              # Initiative II: QuickShell shell and matugen color theming.
              # quickshell/doorway is whole-dir (QML is source-controlled config).
              # matugen templates are Nix-managed; outputs go to ~/.local/share/matugen/
              # (writable, not Nix-managed) via doorway-matugen-watcher.service.
              "quickshell/doorway".source = "${configDir}/.config/quickshell/doorway";
              "matugen/config.toml".source = "${configDir}/.config/matugen/config.toml";
              "matugen/templates".source = "${configDir}/.config/matugen/templates";

              "hypr/doorway-cursor.lua".text = ''
                -- DOORway Cursor Configuration (generated by Home Manager)
                -- Loaded by variables.lua to sync the Hyprland compositor cursor
                -- with home.pointerCursor. Set via doorway.cursor in your home config.
                return {
                  name = "${cfg.cursor.name}",
                  size = ${toString cfg.cursor.size},
                }
              '';

              "hypr/doorway-fonts.lua".text = ''
                -- DOORway Font Configuration (generated by Home Manager)
                -- Loaded by variables.lua via pcall; falls back to hardcoded defaults on bare installs.
                -- Set via doorway.fonts in your home config.
                return {
                  ui_name   = "${cfg.fonts.ui.name}",
                  ui_size   = ${toString cfg.fonts.ui.size},
                  mono_name = "${cfg.fonts.monospace.name}",
                  mono_size = ${toString cfg.fonts.monospace.size},
                  interface = "${cfg.fonts.interface}",
                  sidebar   = "${cfg.fonts.sidebar}",
                }
              '';

              "hypr/doorway-animation-preset.lua".text = ''
                -- DOORway Animation Preset (generated by Home Manager)
                -- Loaded by animations.lua via pcall; falls back to "standard" on bare installs.
                -- Set via doorway.animations.preset in your home config.
                return { preset = "${cfg.animations.preset}" }
              '';

              "hypr/doorway-theme.lua".text = ''
                -- DOORway Theme Configuration (generated by Home Manager)
                -- Applied at end of defaults.lua via pcall; defaults.lua provides the
                -- static fallback values so bare installs and first-boot work correctly.
                -- Set via doorway.theme in your home config.
                return {
                  gaps_in      = ${toString cfg.theme.gapsIn},
                  gaps_out     = ${toString cfg.theme.gapsOut},
                  border_size  = ${toString cfg.theme.borderSize},
                  rounding     = ${toString cfg.theme.rounding},
                  layout       = "${cfg.theme.layout}",
                  blur_enabled = ${if cfg.theme.blur.enabled then "true" else "false"},
                  blur_size    = ${toString cfg.theme.blur.size},
                  blur_passes  = ${toString cfg.theme.blur.passes},
                }
              '';

              "hypr/monitors.lua".text =
                let
                  parseMon =
                    m:
                    let
                      p = lib.splitString "," m;
                    in
                    ''hl.monitor({ output="${lib.elemAt p 0}", mode="${lib.elemAt p 1}", position="${lib.elemAt p 2}", scale="${lib.elemAt p 3}" })'';
                in
                ''
                  -- DOORway Monitor Configuration (generated by NixOS via Home Manager)
                  ${parseMon cfg.monitor}
                  ${lib.concatStringsSep "\n" (map parseMon cfg.extraMonitors)}
                  hl.monitor({ output="", mode="preferred", position="auto", scale="1" })
                '';

              "hypr/userprefs.lua".text = ''
                -- DOORway User Preferences (generated by Home Manager)
                -- Set via doorway.input and doorway.keyboard in your home config.
                hl.config({
                    input = {
                        kb_layout          = "${cfg.keyboard}",
                        follow_mouse       = 1,
                        accel_profile      = "${cfg.input.accelProfile}",
                        numlock_by_default = ${if cfg.input.numlock then "true" else "false"},
                        touchpad = {
                            natural_scroll = ${if cfg.input.naturalScroll then "true" else "false"},
                        },
                    },
                    decoration = {
                        active_opacity   = ${toString cfg.input.activeOpacity},
                        inactive_opacity = ${toString cfg.input.inactiveOpacity},
                    },
                    misc = {
                        enable_swallow = true,
                        swallow_regex = "(kitty|Alacritty|foot)",
                    },
                })
              '';

            };

            home.file = {
              # Systemd drop-in: restart Hyprland on crash (e.g. HDMI hot-unplug
              # triggers onDisconnect → enterUnsafeState → segfault in 0.55.x).
              # Drop-in merges into UWSM's wayland-wm@hyprland.service without
              # conflicting with its unit definition. Burst limit prevents loops.
              ".config/systemd/user/wayland-wm@hyprland.service.d/crash-restart.conf".text = ''
                [Unit]
                StartLimitBurst=3
                StartLimitIntervalSec=120

                [Service]
                Restart=on-failure
                RestartSec=3
              '';

              ".local/lib/doorway".source = "${configDir}/.local/lib/doorway";
              ".local/share/doorway".source = "${configDir}/.local/share/doorway";
              ".local/share/hypr".source = "${configDir}/.local/share/hypr";
              ".local/bin/doorway-shell" = {
                source = "${configDir}/.local/bin/doorway-shell";
                executable = true;
              };
              ".local/bin/doorwayctl" = {
                source = "${configDir}/.local/bin/doorwayctl";
                executable = true;
              };
              ".local/bin/doorway-ipc" = {
                source = "${configDir}/.local/bin/doorway-ipc";
                executable = true;
              };
            };

            home.sessionPath = [
              "$HOME/.local/bin"
              "$HOME/.local/lib/doorway"
            ];

            # Static toolkit/Wayland env vars — session-wide (all processes, not
            # just Hyprland children). Centralises what was duplicated across env.lua
            # and the UWSM env-hyprland.d script. XCURSOR_* are omitted here;
            # home.pointerCursor below sets them automatically.
            home.sessionVariables = {
              QT_QPA_PLATFORM = "wayland;xcb";
              QT_AUTO_SCREEN_SCALE_FACTOR = "1";
              QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
              QT_QPA_PLATFORMTHEME = "qt6ct";
              MOZ_ENABLE_WAYLAND = "1";
              GDK_SCALE = "1";
              ELECTRON_OZONE_PLATFORM_HINT = "auto";
            };

            # DOORway ships one theme: Wallbash (dynamic colors from wallpaper).
            # The static aspects — GTK theme name, icon theme, cursor, UI font — are
            # declared here. Wallbash generates the actual Wallbash-Gtk theme content
            # at runtime into ~/.local/share/themes/Wallbash-Gtk/ (writable path).
            # Use lib.mkDefault so these can be overridden in the user's flake.
            gtk = {
              enable = true;
              theme.name = lib.mkDefault "Wallbash-Gtk";
              iconTheme = {
                name = cfg.theme.iconTheme.name;
                package = cfg.theme.iconTheme.package;
              };
              # cursorTheme is managed by home.pointerCursor.gtk.enable below.
              font = {
                name = lib.mkDefault "Cantarell";
                size = lib.mkDefault 10;
              };
              # HM 26.05 changed the gtk4.theme default from config.gtk.theme to null.
              # Explicitly keep the legacy inherit so GTK4 apps use Wallbash-Gtk too.
              gtk4.theme = config.gtk.theme;
            };

            # Cursor: sets XCURSOR_THEME + XCURSOR_SIZE session-wide, writes
            # ~/.local/share/icons/default/index.theme, and syncs gtk.cursorTheme.
            # Replaces the manual Xresources + icon-symlink writes in theme.switch.sh.
            home.pointerCursor = {
              name = cfg.cursor.name;
              size = cfg.cursor.size;
              package = cfg.cursor.package;
              gtk.enable = true;
            };

            # Static GNOME interface settings not already covered by gtk.enable.
            # color-scheme is declared as prefer-dark (single Wallbash theme default).
            # Dynamic dark/light from wallpaper lightness can be revisited in Pass 12.
            dconf.settings = {
              "org/gnome/desktop/interface" = {
                color-scheme = lib.mkDefault "prefer-dark";
              };
            };

            # All DOORway long-running services and session-bootstrap oneshots.
            # Replaced the HyDE-era runtime-imperative pattern (launch-unit.sh +
            # variables.lua's app() helper birthing units at session start, both
            # deleted in Pass 7). See TODO.md Phase 9 for the migration history.
            systemd.user.services = {
              doorway-text-clipboard = mkDoorwayService {
                description = "DOORway clipboard text watcher (cliphist)";
                execStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
              };

              doorway-image-clipboard = mkDoorwayService {
                description = "DOORway clipboard image watcher (cliphist)";
                execStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
              };

              doorway-network-manager-applet = lib.mkIf cfg.networkApplet.enable (mkDoorwayService {
                description = "DOORway NetworkManager tray applet";
                execStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
              });

              doorway-removable-media-applet = lib.mkIf cfg.removableMedia.enable (mkDoorwayService {
                description = "DOORway removable-media tray applet (udiskie)";
                execStart = "${pkgs.udiskie}/bin/udiskie --no-automount --smart-tray";
              });

              doorway-bluetooth-applet = lib.mkIf cfg.bluetooth.enable (mkDoorwayService {
                description = "DOORway Bluetooth tray applet (blueman)";
                execStart = "${pkgs.blueman}/bin/blueman-applet";
              });

              # doorway-notifications (dunst) removed in Phase 15 — QuickShell's
              # NotificationServer (Notifications.qml) registers on org.freedesktop.Notifications.

              # battery-notify reclassified to app-graphical.slice in Pass 4: it
              # uses notify-send → quickshell, which is graphical-session-only.
              doorway-battery-notify = mkDoorwayService {
                description = "DOORway low-battery notification watcher";
                execStart = "%h/.local/lib/doorway/batterynotify.sh";
                # Desktops have no battery; without this the watcher crash-loops
                # into start-limit-hit at every session start.
                conditionPathExistsGlob = "/sys/class/power_supply/BAT*";
              };

              # wallpaper.sh bootstraps via `eval $(doorway-shell init)` — needs
              # PATH to include ~/.local/bin (propagated via systemctl --user
              # import-environment from startup.lua's SYSTEMD_SHARE_PICKER).
              doorway-wallpaper = mkDoorwayOneshot {
                description = "DOORway wallpaper daemon";
                execStart = "%h/.local/lib/doorway/wallpaper.sh --start --global";
              };

              doorway-idle = lib.mkIf cfg.idle.enable (mkDoorwayService {
                description = "DOORway idle daemon (hypridle)";
                documentation = "https://wiki.hypr.land/Hypr-Ecosystem/hypridle/";
                execStart = "${pkgs.hypridle}/bin/hypridle";
              });

              doorway-blue-light-filter = lib.mkIf cfg.blueLight.enable (mkDoorwayService {
                description = "DOORway blue-light filter (hyprsunset)";
                documentation = "https://wiki.hypr.land/Hypr-Ecosystem/hyprsunset/";
                execStart = "${pkgs.hyprsunset}/bin/hyprsunset";
              });

              doorway-polkit-auth = mkDoorwayService {
                description = "DOORway polkit authentication agent (polkit-gnome)";
                execStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
                # A graphical-session restart can leave the previous agent alive;
                # a second registration fails hard ("agent already exists") and the
                # unit crash-loops. Skip cleanly when an agent is already serving.
                execCondition = "${pkgs.bash}/bin/bash -c '! ${pkgs.procps}/bin/pgrep -x polkit-gnome-au >/dev/null'";
              };

              doorway-config-bootstrap = mkDoorwayOneshot {
                description = "DOORway config initialization (oneshot at session start)";
                # The doorway-config Go binary still defaults its input to the
                # upstream $XDG_CONFIG_HOME/hyde/config.toml path; point it at the
                # DOORway TOML explicitly until the binary is rebuilt.
                execStart = "%h/.local/lib/doorway/doorway-config --no-startup -input %h/.config/doorway/config.toml";
              };

              # Watches ~/.cache/doorway/wall.set for changes and runs matugen
              # to regenerate Material You color files for Hyprland + QuickShell.
              # Starts alongside all other graphical-session services; the initial
              # run on service start handles the wallpaper set before first change.
              doorway-matugen-watcher = {
                Unit = {
                  Description = "DOORway matugen wallpaper color watcher";
                  After = [ "graphical-session.target" ];
                  PartOf = [ "graphical-session.target" ];
                };
                Service = {
                  Type = "exec";
                  ExecStart = "${matugenWatcherScript}";
                  Restart = "on-failure";
                  RestartSec = 5;
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
              };

              # QuickShell UI shell — gated by doorway.shell.enable.
              # ExecStartPost creates by-id/ipc.sock → the live instance socket.
              # Workaround: qs ipc resolves the instance ID from lock file content,
              # but QS 0.3.0 uses raw fcntl locks on an empty file, so the ID reads
              # as "" and the client looks for by-id/ipc.sock (missing the subdir).
              doorway-quickshell = lib.mkIf cfg.shell.enable (
                lib.mkMerge [
                  (mkDoorwayService {
                    description = "DOORway QuickShell (QML-based UI shell)";
                    execStart = "${pkgs.quickshell}/bin/quickshell -c %h/.config/quickshell/doorway";
                    # Every quickshell launch leaves a by-id/<id>/ log dir behind
                    # and nothing ever reclaims them — a Restart=always crash loop
                    # once piled up 5k+ dirs and filled the 587M tmpfs. Pruning
                    # here (runs on every restart, including each crash-loop
                    # cycle) bounds the pile to ~10 min of churn. A concurrent
                    # nested dev instance (qs -p …) older than that loses its
                    # logs/socket but keeps running — acceptable for a dev tool.
                    execStartPre = "${pkgs.writeShellScript "qs-prune-stale" ''
                      QS=/run/user/$(id -u)/quickshell
                      [ -d "$QS/by-id" ] || exit 0
                      find "$QS/by-id" -mindepth 1 -maxdepth 1 -type d -mmin +10 -exec rm -rf {} +
                    ''}";
                  })
                  (
                    let
                      # Resolve THIS instance's runtime dir from the fds it holds
                      # open (log.log, instance.lock). "Newest socket wins" raced
                      # against concurrent instances: a nested `qs -p` launched
                      # around restart time could win, leaving the symlink on a
                      # socket that dies with the dev instance.
                      qsIpcSymlink = pkgs.writeShellScript "qs-ipc-symlink" ''
                        QS=/run/user/$(id -u)/quickshell
                        for _ in $(seq 30); do
                          dir=$(readlink /proc/$MAINPID/fd/* 2>/dev/null | grep -m1 -o "$QS/by-id/[^/]*")
                          if [ -n "$dir" ] && [ -S "$dir/ipc.sock" ]; then
                            ln -sfn "$dir/ipc.sock" "$QS/by-id/ipc.sock"
                            exit 0
                          fi
                          sleep 0.5
                        done
                        echo "qs-ipc-symlink: no ipc.sock for MAINPID=$MAINPID after 15s" >&2
                        exit 1
                      '';
                    in
                    {
                      Service.Environment = [
                        "QML_IMPORT_PATH=${pkgs.qt6.qt5compat}/lib/qt-6/qml"
                      ];
                      Service.ExecStartPost = "${qsIpcSymlink}";
                    }
                  )
                ]
              );

              # Fetch weather from PirateWeather; fired by doorway-weather-fetch.timer.
              # API key arrives via EnvironmentFile (sops secret, not hardcoded).
              doorway-weather-fetch = lib.mkIf cfg.weather.enable {
                Unit = {
                  Description = "DOORway PirateWeather data fetch";
                  After = [ "network-online.target" ];
                };
                Service = {
                  Type = "oneshot";
                  ExecStart = "%h/.local/lib/doorway/doorway-pirateweather.py";
                  Environment = [
                    "PIRATE_WEATHER_ZIP=${cfg.weather.zipCode}"
                    "PIRATE_WEATHER_UNITS=${cfg.weather.units}"
                  ];
                }
                // lib.optionalAttrs (cfg.weather.pirateWeatherApiKeyFile != "") {
                  EnvironmentFile = cfg.weather.pirateWeatherApiKeyFile;
                };
              };
            };

            systemd.user.timers = lib.mkIf cfg.weather.enable {
              doorway-weather-fetch = {
                Unit.Description = "DOORway PirateWeather periodic fetch timer";
                Timer = {
                  OnBootSec = "1min";
                  OnUnitActiveSec = "${toString cfg.weather.updateFrequency}min";
                  Persistent = true;
                };
                Install.WantedBy = [ "timers.target" ];
              };
            };

            # Transitional (2026-07): ~/.config/doorway used to be deployed as one
            # whole-dir store symlink. HM's orphan cleanup keeps it (the path still
            # exists in the new generation — now as a real directory), and link
            # creation then fails with EROFS trying to back up files inside the
            # stale read-only symlink. Delete the old symlink so linkGeneration can
            # materialize the real dir. No-op once migrated; remove after soak.
            home.activation.doorwayDirDelink = lib.mkIf cfg.enable (
              lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
                if [ -L "$HOME/.config/doorway" ]; then
                  run rm "$HOME/.config/doorway"
                fi
              ''
            );

            # Seed the QuickShell night-light schedule into config.json so Nix options
            # actually drive Hyprsunset.qml (which bypasses hyprsunset.conf entirely).
            # Runs at every nixos-rebuild switch; user UI edits reset on next rebuild.
            # Must run after linkGeneration: that's the step that replaces the old
            # whole-dir ~/.config/doorway store symlink with a real writable dir —
            # both entries are after writeBoundary and the tie-break ran this first
            # (EROFS on the 2026-07-02 switch).
            home.activation.doorwayJsonConfig = lib.mkIf cfg.enable (
              lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] (
                let
                  nightTime = cfg.blueLight.schedule.nightTime;
                  dayTime = cfg.blueLight.schedule.dayTime;
                  useWeather = lib.boolToString cfg.blueLight.schedule.useWeatherTimes;
                  topLeftIcon = cfg.bar.topLeftIcon;
                in
                ''
                  config_file="$HOME/.config/doorway/config.json"
                  mkdir -p "$(dirname "$config_file")"
                  # One-shot migration from the pre-rebrand ii path. The old
                  # directory is left in place for rollback; remove it in a
                  # later cleanup sweep.
                  old_config="$HOME/.config/illogical-impulse/config.json"
                  if [ ! -f "$config_file" ] && [ -f "$old_config" ]; then
                    cp "$old_config" "$config_file"
                  fi
                  [ -f "$config_file" ] || echo '{}' > "$config_file"
                  tmp="$(${pkgs.coreutils}/bin/mktemp)"
                  ${pkgs.jq}/bin/jq \
                    --arg from "${nightTime}" \
                    --arg to "${dayTime}" \
                    --argjson useWeather ${useWeather} \
                    --arg topLeftIcon "${topLeftIcon}" \
                    '.light.night.from = $from | .light.night.to = $to | .light.night.useWeatherTimes = $useWeather | .bar.topLeftIcon = $topLeftIcon' \
                    "$config_file" > "$tmp" && mv "$tmp" "$config_file"
                ''
              )
            );
          };
        };

    in
    {
      # NixOS system-level module — registers Hyprland session, enables UWSM,
      # XWayland, and xdg-desktop-portal-hyprland. Owns the Hyprland version pin.
      # Usage in HALLway flake: add `inputs.doorway.nixosModules.default` to the
      # nixosSystem modules list (no specialArgs threading required).
      nixosModules.default =
        { pkgs, lib, ... }:
        {
          # ── Hyprland session ────────────────────────────────────────────────
          # Registers the UWSM-wrapped Hyprland session, enables XWayland,
          # and pins the Hyprland version from DOORway's flake.lock.
          programs.hyprland = {
            enable = true;
            withUWSM = true;
            xwayland.enable = true;
            package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
          };

          # UPower backs the shell's Battery service (Quickshell.Services.UPower).
          # Without the daemon the QML module logs D-Bus warnings on every start;
          # with it, desktops simply report no laptop battery (widget stays hidden)
          # and peripheral batteries (mouse/keyboard) become visible as a bonus.
          services.upower.enable = true;

          # ── Display manager: greetd + regreet ───────────────────────────────
          # cage: minimal Wayland compositor that hosts only the greeter.
          # regreet: GTK4 greeter — user list, password entry, session picker.
          # Hosts may override programs.regreet.settings (e.g. background.path).
          services.gnome.gnome-keyring.enable = true;

          services.greetd = {
            enable = true;
            settings.default_session = {
              command = "${pkgs.cage}/bin/cage -s -- ${pkgs.regreet}/bin/regreet";
              user = "greeter";
            };
          };

          programs.regreet = {
            enable = true;
            settings = {
              background.fit = "Cover";
              GTK.application_prefer_dark_theme = true;
            };
          };

          # Prevent console spam on the greetd TTY.
          systemd.services.greetd.serviceConfig = {
            Type = "idle";
            StandardInput = "tty";
            StandardOutput = "tty";
            StandardError = "journal";
            TTYReset = true;
            TTYVHangup = true;
            TTYVTDisallocate = true;
          };

          # Unlock the GNOME keyring automatically on PAM login via greetd.
          security.pam.services.greetd.enableGnomeKeyring = true;

          # ── DDC/CI monitor brightness ───────────────────────────────────────
          # Loads i2c-dev so ddcutil (in doorwayDeps) can talk to external
          # monitors. The uaccess tag grants the active logind seat user an ACL
          # on /dev/i2c-* — no per-user i2c group membership needed in hosts.
          hardware.i2c.enable = true;
          services.udev.extraRules = ''
            KERNEL=="i2c-[0-9]*", TAG+="uaccess"
          '';

          # ── KDE application discovery (Dolphin "Open With") ─────────────────
          # KService builds its application database (sycoca) by parsing the XDG
          # menu spec, not by scanning share/applications directly. Plasma ships
          # plasma-applications.menu; outside Plasma nothing provides
          # /etc/xdg/menus/applications.menu, so KDE apps index zero
          # applications — Dolphin's "Open With" comes up empty for every file
          # type. KF6 kservice no longer ships a fallback menu, so provide the
          # minimal spec: index every installed .desktop entry.
          # (Portals are not involved in this path — programs.hyprland already
          # wires xdg-desktop-portal-hyprland with hyprland;gtk routing.)
          environment.etc."xdg/menus/applications.menu".text = ''
            <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
            <Menu>
                <Name>Applications</Name>
                <DefaultAppDirs/>
                <DefaultDirectoryDirs/>
                <Include>
                    <All/>
                </Include>
            </Menu>
          '';
        };

      # Home Manager module (the main export)
      # Usage in HALLway flake:
      #   inputs.doorway.url = "github:MarkusBitterman/DOORway";
      #   ...
      #   imports = [ inputs.doorway.homeManagerModules.default ];
      #   doorway.enable = true;
      homeManagerModules = {
        default = doorwayModule;
        doorway = doorwayModule;
      };

      # Hyprland package re-export for downstream consumers that want to reference
      # DOORway's pinned version without importing the full NixOS module.
      packages = forAllSystems (system: {
        hyprland = hyprland.packages.${system}.hyprland;
      });

      # Development shell with all Hyprland packages
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "doorway-dev";
            buildInputs = (doorwayDeps pkgs) ++ (devDeps pkgs);
            shellHook = ''
              echo "DOORway Development Shell"
              echo "All Hyprland packages available."
              echo ""
              echo "  shellcheck Configs/.local/lib/doorway/*.sh  - Lint shell scripts"
              echo "  nixfmt flake.nix           - Format Nix"
              echo ""
              echo "Testing Hyprland:"
              echo "  hyprctl reload             - Live-reload config (inside any Hyprland session)"
              echo "  start-hyprland             - Start nested Hyprland (WAYLAND SESSION ONLY)"
              echo "    NOTE: Requires a running Wayland compositor (e.g. XFCE Wayland session)."
              echo "    Keyboard is dead in nested mode (libseat cannot open /dev/input)."
              echo "    Use for visual checks only; native login required for keybinding tests."
              echo ""
              echo "Flake-based deploy workflow (DOORway → HALLway):"
              echo "  DOORway is a flake input — changes must be committed AND pushed"
              echo "  before HALLway can see them. Local uncommitted changes are invisible."
              echo "  1. git commit && git push              (in this repo)"
              echo "  2. nix flake update doorway          (in HALLway repo)"
              echo "  3. sudo nixos-rebuild switch --flake ~/Developments/HALLway/#2600AD"
              echo ""
              echo "Debugging startup failures:"
              echo "  cat /run/user/\$(id -u)/hypr/*/hyprland.log | grep -v 'DEBUG from aquamarine'"
              echo "    Lua config errors appear here; exec_once failures do NOT."
              echo "  journalctl --user -b -n 200 | grep -iE '(quickshell|doorway|hypr)'"
              echo "    Daemon crashes from exec_once land here."
              echo "  doorway-shell app -u test.scope -t scope -- echo ok"
              echo "    Sanity check: verifies app2unit.sh is findable in PATH."
              echo ""
              # Mimic what env.lua injects before exec_once so doorway-shell app works
              # directly from this dev shell or an XFCE Wayland terminal.
              export PATH="$HOME/.local/lib/doorway:$PATH"
              export XDG_SESSION_DESKTOP=Hyprland
              export XDG_CURRENT_DESKTOP=Hyprland
              echo "  (PATH includes ~/.local/lib/doorway — doorway-shell app works here)"
              echo ""
            '';
          };
        }
      );

      # Expose the dependency list for HALLway to import
      lib.doorwayDeps = doorwayDeps;
    };
}
