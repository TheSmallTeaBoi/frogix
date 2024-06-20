{...}: {
  programs.kitty = {
    enable = true;
    shellIntegration.enableFishIntegration = true;
    font.name = "FiraCode Nerd Font Mono";
    theme = "Catppuccin-Mocha";
    settings = {
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
