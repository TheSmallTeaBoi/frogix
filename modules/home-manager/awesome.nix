{inputs, outputs, pkgs, ...}:
{
  xdg.configFile."/home/theo/.config/awesome/" = {
    source = ./awesome;
    recursive = true;
  };
}

