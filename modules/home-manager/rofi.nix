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
    # (pywal template in pywal.nix), so it follows the wallpaper.
    xdg.configFile."rofi/vitrina.rasi".text =
      lib.replaceStrings [ "/home/theo" ] [ config.home.homeDirectory ]
        (builtins.readFile ./rofi-vitrina.rasi);

    programs.rofi = {
      enable = true;
      plugins = [
        pkgs.rofi-emoji
        pkgs.rofi-calc
      ];
      theme = "~/.config/rofi/vitrina.rasi";
      settings = {
        modi = "drun";
        icon-theme = "Oranchelo";
        show-icons = true;
        terminal = "kitty";
        drun-display-format = "{icon} {name}";
        location = 0;
        disable-history = false;
        hide-scrollbar = true;
        display-drun = "   Apps ";
        display-Network = " 󰤨  Network";
        sidebar-mode = true;
      };
    };
  };
}
