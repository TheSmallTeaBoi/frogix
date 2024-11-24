{pkgs, ...}: {
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-blue-compact+normal";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = ["blue"];
        tweaks = ["normal"];
        size = "standard";
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
    name = "catppuccin-mocha-dark-cursors";
    gtk.enable = true;
    x11.enable = true;
    size = 8;
    package = pkgs.catppuccin-cursors.mochaDark;
  };
}
