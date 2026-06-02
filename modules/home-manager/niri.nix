{
  pkgs,
  config,
  lib,
  ...
}:
let
  main_screen = "DP-3";
  secondary_screen = "HDMI-A-1";
in
{

  wayland.windowManager.niri = {
    enable = true;
    settings = {

      prefer-no-csd = { };
      cursor.xcursor-size = 8;

      environment = {
        LIBVA_DRIVER_NAME = "nvidia";
        XDG_SESSION_TYPE = "wayland";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };

      output = [
        {
          _args = [ main_screen ];
          mode = "1920x1080@180";
          scale = 1.0;
          position._props = {
            x = 0;
            y = 0;
          };
          variable-refresh-rate = { };
        }
        {
          _args = [ secondary_screen ];
          mode = "1366x768@60";
          scale = 1.0;
          position._props = {
            x = -768;
            y = -50;
          };
          transform = "270";

          # Niri works like shit with vertical screens 🥀
          layout = {
            default-column-width = {
              proportion = 1.0;
            };
            always-center-single-column = { };
          };
        }
      ];

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
      };

      layout = {
        gaps = 10;
        border = {
          width = 3;
          inactive-color = "#00000000";
        };
        focus-ring.off = { };
      };

      spawn-at-startup = [
        { _args = [ "${pkgs.swaylock-fancy}/bin/swaylock-fancy" ]; }
        { _args = [ "${pkgs.waybar}/bin/waybar" ]; }
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
        { _args = [ "firefox" ]; }
        { _args = [ "vesktop" ]; }
        { _args = [ "${pkgs.mako}/bin/mako" ]; }
        {
          _args = [
            "${pkgs.glances}/bin/glances"
            "-w"
            "--disable-plugin"
            "diskio,connections"
          ];
        }
        {
          _args = [
            "${pkgs.easyeffects}/bin/easyeffects"
            "--gapplication-service"
          ];
        }
        { _args = [ "${pkgs.sunshine}/bin/sunshine" ]; }
      ];

      workspace = [
        {
          _args = [ "firefox" ];
          open-on-output = main_screen;
        }
        {
          _args = [ "discord" ];
          open-on-output = secondary_screen;
        }
        {
          _args = [ "terminal" ];
          open-on-output = secondary_screen;
        }
      ];

      window-rule = [
        {
          geometry-corner-radius = 5;
          clip-to-geometry = true;
        }
        {
          match._props.app-id = "steam";
          open-on-workspace = "terminal";
          open-focused = false;
        }
        {
          match._props.app-id = "vesktop";
          open-on-workspace = "discord";
          open-focused = false;
        }
        {
          match._props.app-id = "firefox";
          open-on-workspace = "firefox";
          open-focused = false;
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
      ];

      # Direct keybind mappings (no `.action` structures)
      binds = {
        "Mod+Tab" = {
          focus-monitor-next = { };
        };
        "Mod+Return" = {
          spawn._args = [ "kitty" ];
        };
        "Mod+Shift+P" = {
          toggle-window-floating = { };
        };
        "Mod+C" = {
          spawn-sh._args = [ "rofi -show calc -modi calc -no-show-match -no-sort | wl-copy" ];
        };
        "Mod+D" = {
          spawn._args = [
            "rofi"
            "-show"
            "drun"
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
        "Mod+M" = {
          spawn._args = [
            "${pkgs.rofi-pulse-select}/bin/rofi-pulse-select"
            "sink"
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
            "kitty"
            "--class"
            "clipse"
            "-e"
            "${pkgs.clipse}/bin/clipse"
          ];
        };
        "Mod+T" = {
          close-window = { };
        };
        "Mod+Period" = {
          spawn._args = [
            "rofi"
            "-modi"
            "emoji"
            "-show"
            "emoji"
          ];
        };
        "Print" = {
          spawn._args = [
            "${pkgs.grimblast}/bin/grimblast"
            "copy"
            "area"
          ];
        };
        "Shift+Print" = {
          spawn._args = [
            "${pkgs.grimblast}/bin/grimblast"
            "copy"
            "output"
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
      listener = [
        {
          timeout = 500;
          on-timeout = "${pkgs.swaylock-fancy}/bin/swaylock-fancy -t 'Hello, Theo'";
        }
        {
          timeout = 1500;
          on-timeout = "niri msg action power-off-monitors";
        }
      ];
    };
  };

  services.hyprpaper = {
    enable = true;
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 15;
        output = "!${secondary_screen}";
        modules-left = [ "niri/workspaces" ];
        modules-center = [
          "niri/window"
          "custom/waybar-mpris"
        ];
        modules-right = [
          "pulseaudio"
          "clock"
        ];
        "niri/window" = {
          separate-outputs = true;
        };
        "custom/waybar-mpris" = {
          "return-type" = "json";
          "exec" = "waybar-mpris --position --autofocus --pause '' --play '' --separator '  '";
          "on-click" = "waybar-mpris --send toggle";
          "on-click-right" = "waybar-mpris --send player-next";
          "on-scroll-up" = "waybar-mpris --send next";
          "on-scroll-down" = "waybar-mpris --send prev";
          "escape" = true;
          "hide-empty-text" = true;
        };
      };
      secondaryBar = {
        layer = "top";
        position = "top";
        height = 15;
        output = "${secondary_screen}";
        modules-left = [ "niri/workspaces" ];
        modules-center = [ "niri/window" ];
        modules-right = [
          "cpu"
          "memory"
        ];
        "niri/window" = {
          separate-outputs = true;
        };
      };
    };
    style =
      lib.mkAfter # css
        ''
          * {
              background: ${config.lib.stylix.colors.withHashtag.base00};
              color: ${config.lib.stylix.colors.withHashtag.base05};
              border: none;
              border-radius: 0;
              font-size: 10px;
              min-height: 12px;
              padding: 0 2px;
              margin: 1px 0;
          }

          tooltip {
              border: 1px solid ;
          }

          #workspaces button {
               padding: 0 5px;
               border-bottom: 3px solid transparent;
               border-top: 3px solid transparent;
          }

          #workspaces button.active,
          #workspaces button.focused {
               border-bottom: 3px solid ;
               border-top: 3px solid;
          }

          #workspaces button.urgent {
               border-bottom: 3px solid;
               border-top: 3px solid;
          }

          #workspaces button.visible {
               border-bottom: 3px solid;
               color: ${config.lib.stylix.colors.withHashtag.base05};
          }

          label.module{
              padding: 0 10px;
              border-radius: 5px;
          }

          #window {
              border-radius: 5px;
              padding: 0 10px;
              margin: 0 5px;
          }

          window#waybar.empty #window {
              background-color: transparent;
          }

          #clock { margin: 0 2px; }
          #pulseaudio { margin: 0 2px; }
          #cpu { margin: 0 2px; }
          #memory { margin: 0 2px; }
        '';
  };
}
