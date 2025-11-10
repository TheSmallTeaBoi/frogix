{
  pkgs,
  config,
  lib,
  ...
}:
{
  specialisation = {
    light-theme.configuration = {
      stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/da-one-paper.yaml";
    };
  };
  stylix = {
    enable = true;
    image = config.lib.stylix.pixel "base01";
    # Choose from here https://tinted-theming.github.io/tinted-gallery/
    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/da-one-sea.yaml";
    fonts = {
      monospace = {
        package = pkgs.maple-mono.NF;
        name = "Maple Mono NF";
      };
      sizes = {
        applications = 10;
        terminal = 10;
      };
    };
    targets = {
      nixvim = {
        transparentBackground = {
          main = true;
          numberLine = true;
          signColumn = true;
        };
      };
    };
  };
}
