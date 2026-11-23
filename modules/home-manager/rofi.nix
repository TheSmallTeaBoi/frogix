{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.rofi;
in
{
  options.frogix."rofi".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "rofi launcher with the vitrina theme";
  };

  config = lib.mkIf cfg.enable {
    # vitrina-styled theme; colours come from ~/.cache/wal/rofi-colors.rasi
    # (pywal template in pywal.nix), so it follows the wallpaper. without pywal
    # that import dangles, so fall back to rofi's stock theme.
    xdg.configFile."rofi/vitrina.rasi" = lib.mkIf config.frogix.pywal.enable {
      text = lib.replaceStrings [ "/home/theo" ] [ config.home.homeDirectory ] (
        builtins.readFile ./rofi-vitrina.rasi
      );
    };

    programs.rofi = {
      enable = true;
      plugins = [
        pkgs.rofi-emoji
        pkgs.rofi-calc
      ];
      theme = if config.frogix.pywal.enable then "~/.config/rofi/vitrina.rasi" else null;
      settings = {
        modi = "drun";
        icon-theme = "Papirus-Dark";
        show-icons = true;
        drun-display-format = "{icon} {name}";
        location = 0;
        disable-history = false;
        hide-scrollbar = true;
        display-drun = "   Apps ";
        display-Network = " 󰤨  Network";
        sidebar-mode = true;
      }
      # rofi only has a terminal when the terminal area is on
      // lib.optionalAttrs config.frogix.kitty.enable { terminal = "kitty"; };
    };
  };
}
