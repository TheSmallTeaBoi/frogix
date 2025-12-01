{
  pkgs,
  config,
  lib,
  ...
}:
let
  # Change these to whatever screens you want.
  # Get them with `hyprctl monitors`
  main_screen = "WDX DP";
  secondary_screen = "BNQ BenQ G920HDA 25904485019";

in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    plugins = [
      pkgs.hyprlandPlugins.hypr-dynamic-cursors
      pkgs.hyprlandPlugins.hyprexpo
      pkgs.hyprlandPlugins.hyprbars
    ];

    settings = {
      "$mod" = "SUPER";
      monitor = [
        "desc:${main_screen}, 1920x1080@180, 0x0, 1, vrr, 1"
        "desc:${secondary_screen}, 1366x768@60, -768x-50, 1, transform, 3"
        ", preferred, auto, 1"
      ];

      plugin = {
        dynamic-cursors = {
          enabled = true;
          mode = "stretch";
          shake.enabled = false;
        };
        hyprbars = {
          bar_height = 20;
          bar_color = "rgb(${config.lib.stylix.colors.base00})";
          col.text = "rgb(${config.lib.stylix.colors.base05})";
          inactive_button_color = "rgb(${config.lib.stylix.colors.base00})";
          bar_text_size = 8;
          bar_text_font = config.stylix.fonts.sansSerif.name;
          bar_button_padding = 12;
          bar_padding = 12;
          bar_precedence_over_border = true;
          on_double_click = "hyprctl dispatch fullscreen 1";
          hyprbars-button = [
            "rgb(${config.lib.stylix.colors.base08}), 10, , hyprctl dispatch killactive"
            "rgb(${config.lib.stylix.colors.base0A}), 10, , hyprctl dispatch fullscreen 1"
          ];
        };
      };

      xwayland = {
        force_zero_scaling = true;
      };

      device = {
        name = "hid-256c:006e";
        output = "desc:${main_screen}";
      };

      misc = {
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
      };

      decoration = {
        rounding = 5;
        blur = {
          enabled = false;
        };
      };

      general = {
        allow_tearing = true;
        border_size = 3;
        gaps_out = [
          0
          10
          10
          10
        ];
        # "col.active_border" = "0xf38ba8ff";
        "col.inactive_border" = lib.mkForce "0x00000000";
        animation = [
          "workspaces, 1, 2.5, easeOutQuart"
          "windows, 1, 2.5, easeOutQuart, popin"
          "windowsMove, 1, 2.5, easeOutQuart, slide"
          "fade, 1, 2, easeOutQuart"
        ];
        snap = {
          enabled = true;
        };
      };

      cursor = {
        enable_hyprcursor = true;
        no_hardware_cursors = true;
        # allow_dumb_copy = false;
      };

      curves = {
        bezier = "easeOutQuart, 0.25, 1, 0.5, 1";
      };

      input = {
        repeat_delay = 180;
        repeat_rate = 60;
        kb_options = "compose:menu";
        force_no_accel = true;
      };

      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "XDG_SESSION_TYPE,wayland"
        "GBM_BACKEND,nvidia-drm"
        " __GLX_VENDOR_LIBRARY_NAME,nvidia"
        "WLR_RENDERER_ALLOW_SOFTWARE,false"
        "HYPRCURSOR_SIZE,16"
        "XCURSOR_SIZE,16"
      ];

      exec-once = [
        "${pkgs.swaylock-fancy}/bin/swaylock-fancy"
        "${pkgs.waybar}/bin/waybar"

        # Change this to your "primary" screen.
        "${pkgs.xorg.xrandr}/bin/xrandr --output DP-3 --primary"

        "kill (${pkgs.lsof}/bin/lsof -t -i:10420)"
        "sleep 15 && nicotine -s"
        "${pkgs.clipse}/bin/clipse -listen"
        "firefox"
        "vesktop"
        "${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr"
        "${pkgs.mako}/bin/mako"
        "${pkgs.glances}/bin/glances -w --disable-plugin diskio,connections"
        "${pkgs.easyeffects}/bin/easyeffects -l Voice --gapplication-service"
      ];

      windowrulev2 = [
        "workspace 3 silent, class:(steam)"
        "workspace 2 silent, class:(vesktop)"
        "workspace 1 silent, class:(firefox)"

        # Feishin
        "float, class:(feishin)"
        "center 1, floating:1, class:(feishin)"
        # If the window is even a pixel wider than it is tall, it'll go into
        # the horizontal layout
        "size 900 899, class:(feishin)"

        "float, class:(clipse)"
        "float, class:(floating)"
        "size 622 652, class:(clipse)"
        "noblur, class:^(plugdata)$"

        # Smart gaps
        "bordersize 0, floating:0, onworkspace:w[tv1]"
        "rounding 0, floating:0, onworkspace:w[tv1]"
        "bordersize 0, floating:0, onworkspace:f[1]"
        "rounding 0, floating:0, onworkspace:f[1]"

        # Only show title bars on floating windows.
        "plugin:hyprbars:nobar, ^floating:0"
        "size <800 <600, class:.*"
      ];

      workspace = [
        "1, monitor:desc:${main_screen}"
        "2, monitor:desc:${secondary_screen}"
        "3, monitor:desc:${secondary_screen}"

        # Smart gaps
        "w[tv1], gapsout:0, gapsin:0"
        "f[1], gapsout:0, gapsin:0"
      ];

      bindm = [
        # mouse movements
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bind = [
        "$mod, Return, exec, kitty"

        "$mod, C, exec, rofi -show calc -modi calc -no-show-match -no-sort | wl-copy"
        "$mod, D, exec, rofi -show drun"
        "$mod, E, exec, nemo" # File manager
        "$mod, F, fullscreen"
        "$mod, S, fullscreen, 1"
        "$mod, J, cyclenext"
        "$mod, K, cyclenext, prev"
        "$mod, L, exec, feishin"
        "$mod, M, exec, ${pkgs.rofi-pulse-select}/bin/rofi-pulse-select sink"
        "$mod, P, togglefloating"
        "$mod SHIFT, P, workspaceopt, allfloat"
        "$mod, R, exec, kitty --class clipse -e '${pkgs.clipse}/bin/clipse'"
        "$mod, T, killactive"

        "$mod, Q, hyprexpo:expo, toggle"

        "$mod, TAB, workspace, previous"
        "$mod, Period, exec, rofi -modi emoji -show emoji"

        ",XF86AudioLowerVolume, exec, ${pkgs.pulsemixer}/bin/pulsemixer --change-volume -5"
        ",XF86AudioRaiseVolume, exec, ${pkgs.pulsemixer}/bin/pulsemixer --change-volume +5 --max-volume 100"

        ",XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"

        ", Print, exec, ${pkgs.grimblast}/bin/grimblast copy area"
        "SHIFT, Print, exec, ${pkgs.grimblast}/bin/grimblast copy output"
      ]
      ++ (
        # Workspaces
        builtins.concatLists (
          builtins.genList (
            i:
            let
              ws = i + 1;
            in
            [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
              "$mod CONTROL, code:1${toString i}, movetoworkspace, ${toString ws}"
            ]
          ) 9
        )
      );
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      listener = [
        {
          timeout = 300;
          on-timeout = "${pkgs.swaylock-fancy}/bin/swaylock-fancy -t 'Hello, Theo'";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "sleep 3; hyprctl dispatch dpms on";
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
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [
          "hyprland/window"
          "custom/waybar-mpris"
        ];
        modules-right = [
          "pulseaudio"
          "clock"
        ];

        "hyprland/window" = {
          separate-outputs = true;
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
        output = "${secondary_screen}";
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "cpu"
          "memory"
        ];

        "hyprland/window" = {
          separate-outputs = true;
        };
      };
    };
    style =
      lib.mkAfter
        #css
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

          #workspaces button.active {
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

          #clock {
               margin: 0 2px;
          }

          #pulseaudio {
               margin: 0 2px;
          }

          #cpu {
               margin: 0 2px;
          }

          #memory {
               margin: 0 2px;
          }
        '';
  };
}
