{ pkgs, ... }:
{
  gtk = {
    enable = true;

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk2.extraConfig = "gtk-application-prefer-dark-theme = true\n";

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-size = 8;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-size = 8;
    };
  };

  # GTK4 / libadwaita reads settings.ini directly + dconf color-scheme.
  # Without both of these, GTK4 apps stay light even with prefer-dark set.
  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=1
    gtk-theme-name=adw-gtk3-dark
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-size=8
  '';

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark";
      color-scheme = "prefer-dark";
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
