{
  pkgs,
  lib,
  ...
}:
let
  main_screen = "DP-3";
  secondary_screen = "HDMI-A-1";

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
      pkill -RTMIN+8 waybar
    '';
  };

in
{

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      animations = {
        enabled = true;
        fade_in = {
          duration = 300;
          bezier = "easeOutQuint";
        };
        fade_out = {
          duration = 300;
          bezier = "easeOutQuint";
        };
      };

      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 6;
        }
      ];
      input-field = [
        {
          monitor = "";
          size = "20%, 5%";
          outline_thickness = 3;
          inner_color = "rgba(0, 0, 0, 0.0)";

          outer_color = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          check_color = "rgba(00ff99ee) rgba(ff6633ee) 120deg";
          fail_color = "rgba(ff6633ee) rgba(ff0066ee) 40deg";

          font_color = "rgb(143, 143, 143)";
          fade_on_empty = false;
          rounding = 15;

          position = "0, -20";
          halign = "center";
          valign = "center";
        }
      ];
    };
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

      output = [
        {
          _args = [ main_screen ];
          mode = "1920x1080@180";
          scale = 1.0;
          position._props = {
            x = 0;
            y = 0;
          };
          focus-at-startup = { };
          # variable-refresh-rate = { };
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
            preset-column-widths = {
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

        # OpenCode
        {
          _args = [
            "opencode"
            "serve"
            "--port"
            "4096"
            "--hostname"
            "0.0.0.0"
          ];
        }

        # Run pywal after awww-daemon is already up
        {
          _args = [
            "${pkgs.bash}/bin/bash"
            "-c"
            "until ${pkgs.awww}/bin/awww query >/dev/null 2>&1 && [ -S /run/user/$(id -u)/emacs/server ]; do sleep 0.2; done && set-wal \"$(find /storage/Walls/ | shuf -n 1)\""
          ];
        }
        { _args = [ "hyprlock --grace 0" ]; }
        {
          _args = [
            "${pkgs.bash}/bin/bash"
            "-c"
            "until [ -f ~/.cache/wal/colors.css ]; do sleep 0.2; done && ${pkgs.waybar}/bin/waybar"
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
        { _args = [ "qutebrowser" ]; }
        { _args = [ "vesktop" ]; }
        {
          _args = [
            "${pkgs.easyeffects}/bin/easyeffects"
            "--gapplication-service"
          ];
        }
      ];

      workspace = [
        {
          _args = [ "browser" ];
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
          geometry-corner-radius = 10;
          clip-to-geometry = true;
          background-effect = {
            blur = true;
          };
        }
        {
          match._props.is-active = false;
        }
        {
          match._props.app-id = "steam";
          open-on-workspace = "terminal";
          open-focused = false;
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
          match._props.app-id = "gamescope";
          open-on-output = main_screen;
        }
        {
          match._props.app-id = "vesktop";
          open-on-workspace = "discord";
          open-focused = false;
        }
        {
          match._props.app-id = "qute";
          open-on-workspace = "browser";
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
      ];

      binds = {
        "Mod+Tab" = {
          focus-monitor-next = { };
        };
        "Mod+Control+Tab" = {
          move-window-to-monitor-next = { };
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
        "Mod+Shift+W" = {
          spawn._args = [
            "sh"
            "-c"
            "set-wal $(find /storage/Walls/ | shuf -n 1)"
          ];
        };
        "Mod+O" = {
          spawn._args = [
            "emacs"
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
            "+5"
            "--max-volume"
            "100"
          ];
        };
        "XF86AudioLowerVolume" = {
          spawn._args = [
            "pulsemixer"
            "--change-volume"
            "-5"
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
          on-timeout = "niri msg action power-off-monitors";
        }
      ];
    };
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        reload_style_on_change = true;
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
        reload_style_on_change = true;
        height = 15;
        output = "${secondary_screen}";
        modules-left = [ "niri/workspaces" ];
        modules-center = [ "niri/window" ];
        modules-right = [
          "custom/mic"
          "cpu"
          "memory"
        ];
        "niri/window" = {
          separate-outputs = true;
        };
        "custom/mic" = {
          "exec" = "${get-muted}/bin/get-muted";
          "interval" = 1;
          "signal" = 8;
          "on-click" = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          "return-type" = "json";
        };
      };
    };
    style =
      lib.mkAfter # css
        ''
          @import url("file:///home/theo/.cache/wal/waybar.css");

          * {
              background: @background;
              color: @foreground;
              border: none;
              border-radius: 0;
              font-size: 10px;
              min-height: 12px;
              padding: 0 2px;
              margin: 1px 0;
          }

          tooltip {
              border: 1px solid @color4;
          }

          #workspaces button {
               padding: 0 5px;
               border-bottom: 3px solid transparent;
               border-top: 3px solid transparent;
          }

          #workspaces button.active,
          #workspaces button.focused {
               border-bottom: 3px solid @color4;
               border-top: 3px solid @color4;
          }

          #workspaces button.urgent {
               border-bottom: 3px solid @color1;
               border-top: 3px solid @color1;
          }

          #workspaces button.visible {
               border-bottom: 3px solid @color2;
               color: @foreground;
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
