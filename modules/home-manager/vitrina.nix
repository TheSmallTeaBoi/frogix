{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.vitrina;

  # brightness via DDC/CI (this box has no sysfs backlight — brightnessctl
  # was adjusting a scrolllock led). the shadow value file drives the
  # vitrina OSD; setvcp runs async so the keys feel instant.
  vitrina-bright = pkgs.writeShellApplication {
    name = "vitrina-bright";
    runtimeInputs = [ pkgs.ddcutil ];
    text = ''
      f=/run/user/$(id -u)/vitrina-bright
      if [ -s "$f" ]; then
        v=$(cat "$f")
      else
        v=$(ddcutil getvcp 10 --brief 2>/dev/null | awk '{print $4}' | head -1)
        case "$v" in ""|*[!0-9]*) v=50;; esac
      fi
      case "$1" in
        up) v=$((v + 10));;
        down) v=$((v - 10));;
      esac
      [ "$v" -gt 100 ] && v=100
      [ "$v" -lt 0 ] && v=0
      ddcutil setvcp 10 "$v" >/dev/null 2>&1 &
      printf '%s' "$v" > "$f"
    '';
  };

  # night light switch: toggles the wlsunset user unit, then reports the
  # real unit state to the island via the flag file
  vitrina-nightlight = pkgs.writeShellApplication {
    name = "vitrina-nightlight";
    text = ''
      f=/run/user/$(id -u)/vitrina-nightlight
      if systemctl --user is-active --quiet wlsunset; then
        systemctl --user stop wlsunset
        rm -f "$f"
      else
        systemctl --user start wlsunset
        touch "$f"
      fi
    '';
  };
in
{
  options.frogix."vitrina".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "quickshell shell packages + config";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = lib.mkIf (config.frogix.screens.main != null) {
      FROGIX_MAIN_SCREEN = config.frogix.screens.main;
    };
    home.packages = [
      pkgs.quickshell
      pkgs.playerctl
      pkgs.pulseaudio
      pkgs.ddcutil
      pkgs.wlsunset
      vitrina-bright
      vitrina-nightlight
    ];

    # night light: unit exists but never autostarts — the island toggle
    # (or systemctl --user start wlsunset) owns it. coords: cordoba.
    systemd.user.services.wlsunset = {
      Unit.Description = "Night light (color temperature schedule)";
      Service = {
        ExecStart = "${pkgs.wlsunset}/bin/wlsunset -l -31.42 -L -64.18";
        Restart = "on-failure";
      };
    };

    xdg.configFile."vitrina" = {
      source = ./vitrina;
      recursive = true;
    };
  };
}
