{
  pkgs,
  lib,
  config,
  nixosConfig ? null,
  ...
}:
let
  cfg = config.frogix.niri;
  screens = config.frogix.screens;
  main_screen = screens.main;
  left_screen = screens.left;
  right_screen = screens.right;

  # outputs hypridle DPMS-blanks at its timeout: every declared screen except
  # the ones the host opts out (see keepOnOutputs below).
  powerOffOutputs = builtins.filter (s: s != null && !builtins.elem s cfg.keepOnOutputs) [
    main_screen
    left_screen
    right_screen
  ];

  get-muted = pkgs.writeShellApplication {
    name = "get-muted";
    runtimeInputs = with pkgs; [
      wireplumber
      gnugrep
    ];
    text = ''
      if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
          printf '{"text":"󰍭","class":"muted","tooltip":"Microphone muted"}'
      else
          printf '{"text":"󰍬","class":"live","tooltip":"Microphone live"}'
      fi
    '';
  };

  set-muted = pkgs.writeShellApplication {
    name = "set-muted";
    runtimeInputs = with pkgs; [
      wireplumber
    ];
    text = ''
      wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    '';
  };

  # the player is a nixos-side choice (frogix.packages.musicPlayer), so read it
  # through nixosConfig; standalone home-manager eval (the docs pass) has no
  # nixosConfig, and a host without the music pack has no player to wire up.
  music =
    if nixosConfig != null && nixosConfig.frogix.packages.music then
      nixosConfig.frogix.packages.musicPlayer
    else
      null;

  # the editor is a nixos-side choice (frogix.shell.editor); emacs stays the
  # fallback so hosts that never set it keep launching emacsclient.
  editor =
    if nixosConfig != null && nixosConfig.frogix.shell.editor != null then
      nixosConfig.frogix.shell.editor
    else if config.frogix.emacs.enable then
      "emacsclient -c"
    else
      null;

in
{
  options.frogix."niri".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "the full niri rice: compositor config, keybinds, hypridle/hyprlock";
  };

  options.frogix."niri".keepOnOutputs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      declared screens hypridle must not DPMS-blank at its timeout. every
      other declared screen (main, left, right) is powered off and back on
      with the rest. a host whose monitor cannot be blanked — it returns in
      the wrong mode, or the output drop reflows the layout — lists it here;
      hyprlock's black background then covers that screen instead of
      blanking it.
    '';
  };

  config = lib.mkIf cfg.enable {

    # hyprlock: config is pywal-rendered (modules/home-manager/pywal.nix) and
    # symlinked in there, so the lock screen follows the wallpaper. the PAM
    # service comes from modules/system/services.nix.
    home.packages = [ pkgs.hyprlock ];

    # pywal renders the hyprlock config (it is a wal template, symlinked in
    # pywal.nix). when pywal is off there is nothing to symlink, so land a
    # plain config here — otherwise hyprlock would start with no config at all.
    xdg.configFile = lib.mkIf (!config.frogix.pywal.enable) {
      "hypr/hyprlock.conf".text = ''
        general {
            hide_cursor = true
        }

        background {
            monitor =
            color = rgba(000000ff)
        }

        input-field {
            monitor =
            size = 340, 50
            rounding = 12
            outline_thickness = 1
            inner_color = rgba(ffffffff)
            outer_color = rgba(000000ff)
            font_color = rgba(000000ff)
            placeholder_text = Password
            fade_on_empty = false
        }
      '';
    };

    wayland.windowManager.niri = {
      enable = true;
      settings = {

        include = [ "~/.cache/wal/niri-colors.kdl" ];

        prefer-no-csd = { };
        cursor = {
          xcursor-size = 8;
          hide-after-inactive-ms = 1000;
        };
        environment = {
          LIBVA_DRIVER_NAME = "nvidia";
          XDG_SESSION_TYPE = "wayland";
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        };

        # emit output nodes in left -> main -> right order (also the
        # focus-at-startup priority), then any screens the host wrote beyond
        # the three roles. a named screen without a host entry gets a bare
        # placeholder node so it still lands in the arrangement.
        #
        # positions: niri's auto-placement sorts unpositioned outputs by NAME,
        # which would put e.g. "DP-4" leftmost even when it is the main
        # screen — so the arrangement must be explicit. when the host declares
        # autoLayout.widths (logical, post-scale/transform), x offsets are
        # computed cumulatively in role order and y defaults to 0 (top
        # aligned); anything the host wrote under position wins.
        output =
          let
            roleOrder = builtins.filter (s: s != null) [
              left_screen
              main_screen
              right_screen
            ];
            entryFor = n: lib.findFirst (o: builtins.head (o._args or [ "" ]) == n) null screens.outputs;
            withRoles = map (
              n:
              let
                host = entryFor n;
              in
              if host != null then host else { _args = [ n ]; }
            ) roleOrder;
            others = builtins.filter (
              o: !builtins.elem (builtins.head (o._args or [ "" ])) roleOrder
            ) screens.outputs;

            autoX = lib.optionalAttrs (screens.autoLayout != null) (
              builtins.foldl'
                (
                  acc: role:
                  if screens ? ${role} && screens.${role} != null && screens.autoLayout.widths ? ${role} then
                    acc
                    // {
                      ${screens.${role}} = acc.prev;
                      prev = acc.prev + screens.autoLayout.widths.${role};
                    }
                  else
                    acc
                )
                {
                  prev = 0;
                }
                [
                  "left"
                  "main"
                  "right"
                ]
            );
            injectPosition =
              o:
              let
                name = builtins.head (o._args or [ "" ]);
                computed = lib.optionalAttrs (autoX ? ${name}) {
                  x = autoX.${name};
                  y = 0;
                };
              in
              if computed == { } then
                o
              else if o ? position then
                o
                // {
                  position = o.position // {
                    _props = computed // (o.position._props or { });
                  };
                }
              else
                o // { position._props = computed; };
          in
          lib.mkIf (
            screens.outputs != [ ] || left_screen != null || main_screen != null || right_screen != null
          ) (map injectPosition (withRoles ++ others));

        input = {
          keyboard = {
            xkb = {
              options = "compose:menu";
            };
            repeat-delay = 180;
            repeat-rate = 60;
          };
          mouse = {
            accel-profile = "flat";
          };
          focus-follows-mouse = { };
          warp-mouse-to-focus = { };
          workspace-auto-back-and-forth = { };
        };

        spawn-at-startup = [
          {
            _args = [
              "input-remapper-control"
              "--command"
              "autoload"
            ];
          }
          # spawn-at-startup does not run through a shell: each list entry is one
          # argv token, so this must be split into real arguments (the old
          # single "hyprlock --grace 0" string was exec'd as one binary name and
          # silently never launched).
          {
            _args = [
              "${pkgs.hyprlock}/bin/hyprlock"
              "--grace"
              "0"
            ];
          }
          {
            _args = [
              "sh"
              "-c"
              "kill $(${pkgs.lsof}/bin/lsof -t -i:10420) || true"
            ];
          }
          # bare names: these apps belong to frogix.packages / the host, so
          # niri resolves them from PATH instead of force-building them here.
          # a missing one just no-ops.
          {
            _args = [
              "sh"
              "-c"
              "sleep 15 && nicotine -s"
            ];
          }
          {
            _args = [
              "clipse"
              "-listen"
            ];
          }
        ]
        # wallpaper + palette belong to pywal (it owns awww and set-wal)
        ++ lib.optionals config.frogix.pywal.enable [
          { _args = [ "${pkgs.awww}/bin/awww-daemon" ]; }
          # Run pywal after awww-daemon is already up
          {
            _args = [
              "${pkgs.bash}/bin/bash"
              "-c"
              "until ${pkgs.awww}/bin/awww query >/dev/null 2>&1 && [ -S /run/user/$(id -u)/emacs/server ]; do sleep 0.2; done && set-wal \"$(find ${config.frogix.wallpapersDir} -type f | shuf -n 1)\""
            ];
          }
        ]
        ++ lib.optionals config.frogix.vitrina.enable [
          {
            _args = [
              "${pkgs.bash}/bin/bash"
              "-c"
              "until [ -f ~/.cache/wal/colors.json ]; do sleep 0.2; done && ${pkgs.quickshell}/bin/quickshell -p ${config.xdg.configHome}/vitrina"
            ];
          }
        ]
        ++ lib.optionals config.frogix.vesktop.enable [ { _args = [ "vesktop" ]; } ]
        ++ lib.optionals config.services.easyeffects.enable [
          {
            _args = [
              "easyeffects"
              "--gapplication-service"
            ];
          }
        ]
        ++ lib.optionals config.frogix.qutebrowser.enable [
          # QTWEBENGINE_REMOTE_DEBUGGING: loopback-only devtools port; ricecdp.py
          # uses it to flip prefers-color-scheme on live pages without a restart.
          {
            _args = [
              "${pkgs.bash}/bin/bash"
              "-c"
              "QTWEBENGINE_REMOTE_DEBUGGING=9222 exec ${pkgs.qutebrowser}/bin/qutebrowser"
            ];
          }
        ];

        workspace = lib.mkIf (left_screen != null) [
          {
            _args = [ "󰖟" ]; # browser
            open-on-output = main_screen;
          }
          {
            _args = [ "" ]; # discord
            open-on-output = left_screen;
          }
        ];

        window-rule = [
          {
            # flat look: no compositor blur on windows
            geometry-corner-radius = 14;
            clip-to-geometry = true;
          }
          {
            match._props.is-active = false;
          }
          {
            match._props = {
              app-id = "steam";
              title = "r#\"^notificationtoasts_\d+_desktop$\"#";
            };
            default-floating-position = {
              _props.x = 10;
              _props.y = 10;
              _props.relative-to = "bottom-right";
            };
          }
          {
            match._props.app-id = "clipse";
            open-floating = true;
            default-column-width = {
              fixed = 622;
            };
            default-window-height = {
              fixed = 652;
            };
          }
          {
            match._props.app-id = "floating";
            open-floating = true;
          }
        ]
        ++ lib.optionals (music != null) [
          {
            match._props.app-id = music.appId;
            open-floating = true;
            default-column-width = {
              fixed = 900;
            };
            default-window-height = {
              fixed = 899;
            };
          }
        ]
        ++ lib.optionals config.frogix.vesktop.enable [
          {
            match._props.app-id = "vesktop";
            open-on-workspace = ""; # discord
            open-focused = false;
          }
        ]
        ++ lib.optionals config.frogix.qutebrowser.enable [
          {
            match._props.app-id = "qute";
            open-on-workspace = "󰖟"; # browser
            open-focused = false;
            open-maximized = true;
          }
        ]
        ++ lib.optionals (right_screen != null) [
          {
            match._props.app-id = "steam";
            open-on-output = right_screen;
            open-focused = false;
          }
        ];

        hotkey-overlay.skip-at-startup = true;

        binds = {
          # next/previous cycle monitors in niri's sorted_outputs order, which
          # sorts by make/model/serial then connector NAME — not by physical
          # position (niri.rs reposition_outputs). with DP-4 main + HDMI-A-*
          # sides, Tab moved LEFT and Grave RIGHT. the *direction* actions are
          # the only ones that compare actual output geometry, so bind to those
          # instead (2026-11-24).
          "Mod+Tab" = {
            focus-monitor-right = { };
          };
          "Mod+Grave" = {
            focus-monitor-left = { };
          };
          "Mod+Control+Tab" = {
            move-window-to-monitor-right = { };
          };
          "Mod+Control+Grave" = {
            move-window-to-monitor-left = { };
          };
          "Mod+Shift+P" = {
            toggle-window-floating = { };
          };
          # Launch the XDG default browser's desktop entry (qutebrowser when
          # frogix.qutebrowser is on) with no URL, so existing tabs are kept.
          "Mod+B" = {
            spawn._args = [
              "${pkgs.bash}/bin/bash"
              "-c"
              "exec ${lib.getExe' pkgs.gtk3 "gtk-launch"} \"$(${lib.getExe' pkgs.xdg-utils "xdg-settings"} get default-web-browser)\""
            ];
          };
          "Mod+E" = {
            spawn._args = [ "nemo" ];
          };
          "Mod+F" = {
            fullscreen-window = { };
          };
          "Mod+S" = {
            maximize-column = { };
          };
          "Mod+J" = {
            focus-window-down-or-column-right = { };
          };
          "Mod+K" = {
            focus-window-up-or-column-left = { };
          };
          "Mod+P" = {
            toggle-window-floating = { };
          };
          "Mod+T" = {
            close-window = { };
          };

          "Super+WheelScrollUp" = {
            _props.cooldown-ms = 150;
            focus-workspace-up = { };
          };

          "Super+WheelScrollDown" = {
            _props.cooldown-ms = 150;
            focus-workspace-down = { };
          };

          "Super+WheelScrollLeft" = {
            _props.cooldown-ms = 150;
            focus-column-left = { };
          };

          "Super+WheelScrollRight" = {
            _props.cooldown-ms = 150;
            focus-column-right = { };
          };

          "Print" = {
            screenshot = { };
          };

          "Shift+Print" = {
            screenshot-screen._props.write-to-disk = false;
          };
          "Control+Print" = {
            screenshot-window._props.write-to-disk = false;
          };

          "Super+Shift+Print" = {
            screenshot-screen = { };
          };
          "Super+Control+Print" = {
            screenshot-window = { };
          };

          "XF86AudioPlay" = {
            spawn._args = [
              "playerctl"
              "play-pause"
            ];
          };
          "XF86AudioRaiseVolume" = {
            spawn._args = [
              "pulsemixer"
              "--change-volume"
              "+1"
              "--max-volume"
              "100"
            ];
          };
          "XF86AudioLowerVolume" = {
            spawn._args = [
              "pulsemixer"
              "--change-volume"
              "-1"
              "--max-volume"
              "100"
            ];
          };

          #    F17
          "Alt+XF86Launch8" = {
            spawn._args = [
              (lib.getExe set-muted)
            ];
          };

          "Mod+Left" = {
            focus-column-left = { };
          };
          "Mod+Right" = {
            focus-column-right = { };
          };
          "Mod+Shift+Left" = {
            move-column-left = { };
          };
          "Mod+Shift+Right" = {
            move-column-right = { };
          };
          "Mod+Shift+J" = {
            move-window-down = { };
          };
          "Mod+Shift+K" = {
            move-window-up = { };
          };
          "Mod+BracketLeft" = {
            consume-or-expel-window-left = { };
          };
          "Mod+BracketRight" = {
            consume-or-expel-window-right = { };
          };
          "Mod+Minus" = {
            set-column-width._args = [ "-10%" ];
          };
          "Mod+Equal" = {
            set-column-width._args = [ "+10%" ];
          };
          "Mod+Prior" = {
            focus-workspace-up = { };
          };
          "Mod+Next" = {
            focus-workspace-down = { };
          };
          "Mod+Ctrl+Prior" = {
            move-window-to-workspace-up = { };
          };
          "Mod+Ctrl+Next" = {
            move-window-to-workspace-down = { };
          };
          "XF86AudioNext" = {
            spawn._args = [
              "playerctl"
              "next"
            ];
          };
          "XF86AudioPrev" = {
            spawn._args = [
              "playerctl"
              "previous"
            ];
          };
          "XF86AudioMute" = {
            spawn._args = [
              "wpctl"
              "set-mute"
              "@DEFAULT_AUDIO_SINK@"
              "toggle"
            ];
          };
          "XF86AudioMicMute" = {
            spawn._args = [
              (lib.getExe set-muted)
            ];
          };

        }
        # apps owned by other frogix areas: the bind only exists when that
        # area is on, so niri never launches (or force-builds) what is not there
        // lib.optionalAttrs (music != null) {
          "Mod+L" = {
            spawn._args = [ music.command ];
          };
        }
        // lib.optionalAttrs config.frogix.kitty.enable {
          "Mod+Return" = {
            spawn._args = [ "kitty" ];
          };
        }
        // lib.optionalAttrs (editor != null) {
          "Mod+O" = {
            spawn-sh._args = [ editor ];
          };
        }
        // lib.optionalAttrs config.frogix.pywal.enable {
          "Mod+Shift+W" = {
            spawn._args = [
              "sh"
              "-c"
              "set-wal $(find ${config.frogix.wallpapersDir} -type f | shuf -n 1)"
            ];
          };
          "Mod+Shift+L" = {
            spawn._args = [
              "rice-mode"
              "toggle"
            ];
          };
        }
        // lib.optionalAttrs config.frogix.vitrina.enable {
          # vitrina hotkey reminder (replaces niri's built-in overlay bind)
          "Mod+Shift+Slash" = {
            spawn-sh._args = [
              "if [ -e /run/user/1000/vitrina-hotkeys ]; then rm -f /run/user/1000/vitrina-hotkeys; else touch /run/user/1000/vitrina-hotkeys; fi"
            ];
          };
          "Mod+C" = {
            spawn._args = [
              "${pkgs.quickshell}/bin/qs"
              "-p"
              "${config.xdg.configHome}/vitrina"
              "ipc"
              "call"
              "vitrina"
              "launcher"
              "calc"
            ];
          };
          "Mod+D" = {
            spawn._args = [
              "${pkgs.quickshell}/bin/qs"
              "-p"
              "${config.xdg.configHome}/vitrina"
              "ipc"
              "call"
              "vitrina"
              "launcher"
              "apps"
            ];
          };
          "Mod+R" = {
            spawn._args = [
              "${pkgs.quickshell}/bin/qs"
              "-p"
              "${config.xdg.configHome}/vitrina"
              "ipc"
              "call"
              "vitrina"
              "launcher"
              "clipboard"
            ];
          };
          "Mod+Period" = {
            spawn._args = [
              "${pkgs.quickshell}/bin/qs"
              "-p"
              "${config.xdg.configHome}/vitrina"
              "ipc"
              "call"
              "vitrina"
              "launcher"
              "emoji"
            ];
          };
          "Mod+W" = {
            spawn._args = [
              "${pkgs.quickshell}/bin/qs"
              "-p"
              "${config.xdg.configHome}/vitrina"
              "ipc"
              "call"
              "vitrina"
              "launcher"
              "windows"
            ];
          };
          "Mod+N" = {
            spawn._args = [ "vitrina-nightlight" ];
          };
          "XF86MonBrightnessUp" = {
            spawn._args = [
              "vitrina-bright"
              "up"
            ];
          };
          "XF86MonBrightnessDown" = {
            spawn._args = [
              "vitrina-bright"
              "down"
            ];
          };
        }
        // (builtins.listToAttrs (
          builtins.concatLists (
            builtins.genList (
              i:
              let
                ws = i + 1; # integer workspace index
                key = toString (i + 1);
              in
              [
                {
                  name = "Mod+${key}";
                  value = {
                    focus-workspace._args = [ ws ];
                  };
                }
                {
                  name = "Mod+Ctrl+${key}";
                  value = {
                    move-column-to-workspace._args = [ ws ];
                  };
                }
              ]
            ) 9
          )
        ));
      };

    };

    services.hypridle = {
      enable = true;
      settings = {
        # niri has no hyprland-lock-notify-v1, so hypridle cannot wait for the
        # locker to be up. lock_cmd/before_sleep_cmd still fire on the logind
        # lock/before-sleep signals as a best-effort safety net; the island's
        # suspend action uses vitrina-lock-suspend, which is deterministic.
        general = {
          lock_cmd = "pidof hyprlock || hyprlock --no-fade-in";
          before_sleep_cmd = if config.frogix.vitrina.enable then "vitrina-lock" else "hyprlock --grace 0";
          after_sleep_cmd = "niri msg action power-on-monitors";
          inhibit_sleep = 1;
        };
        listener = [
          {
            timeout = 500;
            on-timeout = "${pkgs.bash}/bin/bash -c 'hyprlock --grace 120${lib.optionalString config.frogix.pywal.enable "; set-wal $(find ${config.frogix.wallpapersDir} -type f | shuf -n 1)"}'";
          }
        ]
        ++ lib.optional (powerOffOutputs != [ ]) {
          timeout = 1500;
          on-timeout = "${pkgs.bash}/bin/bash -c '${
            lib.concatMapStringsSep "; " (o: "niri msg output ${o} off") powerOffOutputs
          }'";
          on-resume = "${pkgs.bash}/bin/bash -c '${
            lib.concatMapStringsSep "; " (o: "niri msg output ${o} on") powerOffOutputs
          }'";
        };
      };
    };

  };
}
