{pkgs, ...}: let
  wallpaper = ./wallpaper.png; # Change this to change the wallpaper.
in {
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
      "$mod" = "SUPER";
      monitor = [
        "DP-2, 1920x1080@60, 0x0, 1"
        "HDMI-A-1, 1366x768@60, auto-left, 1, transform, 3"
        ", preferred, auto, 1"
      ];

      decoration = {
        rounding = 10;
      };

      general = {
        border_size = 3;
        gaps_out = 10;
        "col.active_border" = "0xf38ba8ff";
        animation = [
          "workspaces, 1, 2.5, easeOutQuart"
          "windows, 1, 2.5, easeOutQuart, slide"
          "fade, 1, 2, easeOutQuart"
        ];
      };

      curves = {
        bezier = "easeOutQuart, 0.25, 1, 0.5, 1";
      };

      bindm = [
        # mouse movements
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      input = {
        repeat_delay = 180;
        repeat_rate = 60;
        force_no_accel = true;
      };

      env = [
      ];

      exec-once = [
        "sleep 1 && waybar"
        "nicotine -n"
        "clipse -listen"
        "firefox"
        "vesktop"
        "mako"
      ];

      windowrulev2 = [
        "workspace 2 silent, class:(vesktop)"
        "workspace 1 silent, class:(firefox)"
        "float,class:(clipse)"
        "size 622 652,class:(clipse)"
      ];

      workspace = [
        "1, monitor:DP-2"
        "2, monitor:HDMI-A-1"
        "3, monitor:HDMI-A-1"
      ];

      bind =
        [
          "$mod, Return, exec, kitty"
          "$mod, R, exec, kitty --class clipse -e 'clipse'"
          "$mod, D, exec, rofi -show drun"

          "$mod, T, killactive"
          "$mod, TAB, workspace, previous"
          "$mod, J, cyclenext"
          "$mod, K, cyclenext, prev"
          "$mod, P, togglefloating"
          "$mod, F, fullscreen"

          ", Print, exec, ${pkgs.grimblast}/bin/grimblast copy area"
          "SHIFT, Print, exec, ${pkgs.grimblast}/bin/grimblast copy output"
        ]
        ++ (
          # Workspaces
          builtins.concatLists (builtins.genList (i: let
              ws = i + 1;
            in [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
              "$mod CONTROL, code:1${toString i}, movetoworkspace, ${toString ws}"
            ])
            9)
        );
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = ["${wallpaper}"];
      wallpaper = [",${wallpaper}"];
    };
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 15;
        output = "DP-2";
        modules-left = ["hyprland/workspaces"];
        modules-center = ["hyprland/window" "custom/waybar-mpris"];
        modules-right = ["pulseaudio" "clock"];

        "hyprland/window" = {
          separate-outputs = true;
        };

        "hyprland/workspaces" = {
          persistent-workspaces = {
            "HDMI-A-1" = [2 3];
            "DP-2" = [1];
          };
        };

        "custom/waybar-mpris" = {
          "return-type" = "json";
          "exec" = "waybar-mpris --position --autofocus --pause '' --play '' --separator '  '";
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
        output = "HDMI-A-1";
        modules-left = ["hyprland/workspaces"];
        modules-center = ["hyprland/window"];
        modules-right = ["cpu" "memory"];

        "hyprland/window" = {
          separate-outputs = true;
        };

        "hyprland/workspaces" = {
          persistent-workspaces = {
            "HDMI-A-1" = [2 3];
            "DP-2" = [1];
          };
        };
      };
    };
    style =
      #css
      ''
        * {
          background: transparent;
          border: none;
             border-radius: 0;
             font-family: Roboto, Helvetica, Arial, sans-serif;
             font-size: 13px;
             min-height: 16px;
          padding: 0 2px;
          margin: 1px 0;
        }


        tooltip {
           background: rgb(30, 30, 46);
           border: 1px solid rgb(30, 30, 46);
        }
        tooltip label {
           color: rgb(205, 214, 244);
        }

        #workspaces button {
             padding: 0 5px;
             background: rgb(30, 30, 46);
             color: rgb(205, 214, 244);
             border-bottom: 3px solid transparent;
             border-top: 3px solid transparent;
        }

        #workspaces button.active {
             background: rgb(49, 50, 68);
             border-bottom: 3px solid rgb(203, 166, 247);
             border-top: 3px solid rgb(203, 166, 247);
             color: rgb(205, 214, 244);
        }

        #workspaces button.urgent {
             background: rgb(49, 50, 68);
             border-bottom: 3px solid rgb(243, 139, 168);
             border-top: 3px solid rgb(243, 139, 168);
             color: rgb(205, 214, 244);
        }

        #workspaces button.visible {
             background: rgb(49, 50, 68);
             border-bottom: 3px solid rgb(203, 166, 247);
             color: rgb(205, 214, 244);
        }

        label.module{
            padding: 0 10px;
            background: rgb(30, 30, 46);
            color: rgb(205, 214, 244);
            border-radius: 5px;
        }

        #window {
            background: rgb(30, 30, 46);
            color: rgb(205, 214, 244);
            border-radius: 5px;
            padding: 0 10px;
            margin: 0 5px;
        }

        window#waybar.empty #window {
            background-color: transparent;
        }

        #clock {
             background-color: rgb(137, 180, 250);
             color: rgb(30, 30, 46);
             margin: 0 2px;
        }

        #pulseaudio {
             background-color: rgb(243, 139, 168);
             color: rgb(30, 30, 46);
             margin: 0 2px;
        }

        #cpu {
             background-color: rgb(203, 166, 247);
             color: rgb(30, 30, 46);
             margin: 0 2px;
        }

        #memory {
             background-color: rgb(243, 139, 168);
             color: rgb(30, 30, 46);
             margin: 0 2px;
        }

        @keyframes blink {
             to {
                 background-color: rgb(205, 214, 244);
                 color: black;
             }
         }

      '';
  };
}
