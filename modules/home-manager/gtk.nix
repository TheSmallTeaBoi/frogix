{ pkgs, ... }:
{
  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
        gtk-cursor-theme-size=8
      '';
    };
    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
        gtk-cursor-theme-size=8
      '';
    };
  };
  home.pointerCursor = {
    name = "catppuccin-mocha-light-cursors";
    gtk.enable = true;
    x11.enable = true;
    size = 8;
    package = pkgs.catppuccin-cursors.mochaLight;
  };
  qt = {
    enable = true;
  };
}
