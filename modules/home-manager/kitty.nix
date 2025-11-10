{ config, ... }:
let
  fontName = config.stylix.fonts.monospace.name;
in
{
  programs.kitty = {
    enable = true;
    shellIntegration.enableFishIntegration = true;
    settings = {
      shell_integration = "no-cursor";
      cursor_blink_interval = "0.5 ease-in-out";

      italic_font = "${fontName} Italic";
      bold_italic_font = "${fontName} Bold Italic";
      bold_font = "${fontName} Bold";

      enable_audio_bell = false;
      confirm_os_window_close = 0;
      window_padding_width = 18;
      tab_bar_min_tabs = 2;
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "angled";
      tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
    };
    # some sort of race condition with kitty and starship
    # https://github.com/kovidgoyal/kitty/issues/4476#issuecomment-1013617251
    shellIntegration.enableBashIntegration = false;
  };
}
