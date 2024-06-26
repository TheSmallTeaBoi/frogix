{...}: {
  xdg.configFile."/home/theo/.config/polybar/" = {
    source = ./polybar;
    recursive = true;
  };
}
