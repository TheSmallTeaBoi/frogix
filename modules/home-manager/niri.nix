{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.frogix.niri;
  screens = config.frogix.screens;
  main_screen = screens.main;
  left_screen = screens.left;
  right_screen = screens.right;

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

in
{
  options.frogix."niri".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "the full niri rice: compositor config, keybinds, hypridle/hyprlock";
  };

  config = lib.mkIf cfg.enable {

    # hyprlock: config is pywal-rendered (modules/home-manager/pywal.nix) and
    # symlinked in there, so the lock screen follows the wallpaper. the PAM
    # service comes from modules/system/services.nix.
    home.packages = [ pkgs.hyprlock ];

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
            entryFor =
              n:
              lib.findFirst (o: builtins.head (o._args or [ "" ]) == n) null screens.outputs;
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
                (acc: role:
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
            injectPosition = o:
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
          lib.mkIf (screens.outputs != [ ] || left_screen != null || main_screen != null || right_screen != null)
            (map injectPosition (withRoles ++ others));

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
          { _args = [ "${pkgs.awww}/bin/awww-daemon" ]; }
          {
            _args = [
              "input-remapper-control"
              "--command"
              "autoload"
            ];
          }

          # Run pywal after awww-daemon is already up
          {
            _args = [
              "${pkgs.bash}/bin/bash"
              "-c"
              "until ${pkgs.awww}/bin/awww query >/dev/null 2>&1 && [ -S /run/user/$(id -u)/emacs/server ]; do sleep 0.2; done && set-wal \"$(find ${config.frogix.wallpapersDir} -type f | shuf -n 1)\""
            ];
          }
          { _args = [ "hyprlock --grace 0" ]; }
          {
            _args = [
              "${pkgs.bash}/bin/bash"
              "-c"
              "until [ -f ~/.cache/wal/colors.json ]; do sleep 0.2; done && ${pkgs.quickshell}/bin/quickshell -p ${config.xdg.configHome}/vitrina"
            ];
          }
          {
            _args = [
              "sh"
              "-c"
              "kill $(${pkgs.lsof}/bin/lsof -t -i:10420) || true"
            ];
          }
          {
            _args = [
              "sh"
              "-c"
              "sleep 15 && nicotine -s"
            ];
          }
          {
            _args = [
              "${pkgs.clipse}/bin/clipse"
              "-listen"
            ];
          }
          # QTWEBENGINE_REMOTE_DEBUGGING: loopback-only devtools port; ricecdp.py
          # uses it to flip prefers-color-scheme on live pages without a restart.
          {
            _args = [
              "${pkgs.bash}/bin/bash"
              "-c"
              "QTWEBENGINE_REMOTE_DEBUGGING=9222 exec ${pkgs.qutebrowser}/bin/qutebrowser"
            ];
          }
          { _args = [ "vesktop" ]; }
          {
            _args = [
              "${pkgs.easyeffects}/bin/easyeffects"
              "--gapplication-service"
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
            match._props.app-id = "vesktop";
            open-on-workspace = ""; # discord
            open-focused = false;
          }
          {
            match._props.app-id = "qute";
            open-on-workspace = "󰖟"; # browser
            open-focused = false;
            open-maximized = true;
          }
          {
            match._props.app-id = "feishin";
            open-floating = true;
            default-column-width = {
              fixed = 900;
            };
            default-window-height = {
              fixed = 899;
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
        ++ lib.optionals (right_screen != null) [
          {
            match._props.app-id = "steam";
            open-on-output = right_screen;
            open-focused = false;
          }
        ];

        hotkey-overlay.skip-at-startup = true;

        binds = {
          # vitrina hotkey reminder (replaces niri's built-in overlay bind)
          "Mod+Shift+Slash" = {
            spawn-sh._args = [
              "if [ -e /run/user/1000/vitrina-hotkeys ]; then rm -f /run/user/1000/vitrina-hotkeys; else touch /run/user/1000/vitrina-hotkeys; fi"
            ];
          };
          "Mod+Tab" = {
            focus-monitor-next = { };
          };
          "Mod+Grave" = {
            focus-monitor-previous = { };
          };
          "Mod+Control+Tab" = {
            move-window-to-monitor-next = { };
          };
          "Mod+Control+Grave" = {
            move-window-to-monitor-previous = { };
          };
          "Mod+Return" = {
            spawn._args = [ "kitty" ];
          };
          "Mod+Shift+P" = {
            toggle-window-floating = { };
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
          "Mod+L" = {
            spawn._args = [ "feishin" ];
          };
          "Mod+Shift+W" = {
            spawn._args = [
              "sh"
              "-c"
              "set-wal $(find /storage/Walls/ | shuf -n 1)"
            ];
          };
          "Mod+Shift+L" = {
            spawn._args = [
              "rice-mode"
              "toggle"
            ];
          };
          "Mod+O" = {
            spawn._args = [
              "emacsclient"
              "-c"
            ];
          };
          "Mod+P" = {
            toggle-window-floating = { };
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
          "Mod+T" = {
            close-window = { };
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
          "XF86MonBrightnessUp" = {
            spawn._args = [ "vitrina-bright" "up" ];
          };
          "XF86MonBrightnessDown" = {
            spawn._args = [ "vitrina-bright" "down" ];
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
        listener = [
          {
            timeout = 500;
            on-timeout = "${pkgs.bash}/bin/bash -c 'hyprlock --grace 120; set-wal $(find /storage/Walls/ | shuf -n 1)'";
          }
          {
            timeout = 1500;
            on-timeout = "${pkgs.bash}/bin/bash -c 'niri msg output ${main_screen} off${
              lib.optionalString (left_screen != null) "; niri msg output ${left_screen} off"
            }'";
            on-resume = "${pkgs.bash}/bin/bash -c 'niri msg output ${main_screen} on${
              lib.optionalString (left_screen != null) "; niri msg output ${left_screen} on"
            }'";
          }
        ];
      };
    };

  };
}
