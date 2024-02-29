{inputs, config, pkgs, user, ...}:
{
  home.username = "theo";
  home.homeDirectory = "/home/theo";  
  home.stateVersion = "23.11";

  home.file."/home/theo/Documents/wallpapers/solidcolor.png" = {
    enable = true; # disable this if you want to add your own wallpaper
    source = ./wallpaper.png; # or change this
  };
}

