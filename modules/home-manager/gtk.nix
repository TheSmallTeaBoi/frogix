{pkgs, ...}: {
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-latte-blue-compact+normal";
      package = pkgs.catppuccin-gtk.override {
        variant = "latte";
        accents = ["blue"];
        tweaks = ["normal"];
        size = "compact";
      };
    };

    iconTheme = {
      name = "Papirus-Light";
      package = pkgs.catppuccin-papirus-folders;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=0
      '';
    };
    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=0
      '';
    };
  };
  home.pointerCursor = {
    name = "catppuccin-latte-dark-cursors";
    gtk.enable = true;
    x11.enable = true;
    size = 16;
    package = pkgs.catppuccin-cursors.latteDark;
  };
}
