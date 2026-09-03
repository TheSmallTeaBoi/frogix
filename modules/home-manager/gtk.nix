{ pkgs, config, ... }:
{
  gtk = {
    enable = true;

    theme.name = "FlatColor";

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-size = 8;
    };

    gtk4 = {
      theme = null;
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-cursor-theme-size = 8;
      };
    };

  };
  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Ice";
    gtk.enable = true;
    x11.enable = true;
    size = 8;
    package = pkgs.bibata-cursors;
  };
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };
}
