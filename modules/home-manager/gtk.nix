{pkgs, ...}: {
  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Latte-Compact-Blue-Dark";
      package = pkgs.catppuccin-gtk.override {
        variant = "latte";
        accents = ["blue"];
        tweaks = ["normal"];
        size = "compact";
      };
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };
  home.pointerCursor = {
    name = "Catppuccin-Latte-Light-Cursors";
    gtk.enable = true;
    x11.enable = true;
    size = 16;
    package = pkgs.catppuccin-cursors.latteLight;
  };
}
