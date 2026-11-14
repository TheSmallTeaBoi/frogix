{ pkgs, ... }:
{
  # vitrina-styled theme; colours come from ~/.cache/wal/rofi-colors.rasi
  # (pywal template in pywal.nix), so it follows the wallpaper.
  xdg.configFile."rofi/vitrina.rasi".source = ./rofi-vitrina.rasi;

  programs.rofi = {
    enable = true;
    plugins = [
      pkgs.rofi-emoji
      pkgs.rofi-calc
    ];
    theme = "~/.config/rofi/vitrina.rasi";
    extraConfig = {
      modi = "run,drun,window";
      icon-theme = "Oranchelo";
      show-icons = true;
      terminal = "kitty";
      drun-display-format = "{icon} {name}";
      location = 0;
      disable-history = false;
      hide-scrollbar = true;
      display-drun = "   Apps ";
      display-run = "   Run ";
      display-window = " 﩯  Window";
      display-Network = " 󰤨  Network";
      sidebar-mode = true;
    };
  };
}
