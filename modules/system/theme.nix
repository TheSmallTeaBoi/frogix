{
  pkgs,
  config,
  lib,
  ...
}:
{
  stylix = {
    enable = true;
    image = config.lib.stylix.pixel "base01";
    # Choose from here https://tinted-theming.github.io/tinted-gallery/
    base16Scheme = "${pkgs.base16-schemes}/share/themes/da-one-sea.yaml";
    fonts = {

      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };

      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };

      monospace = {
        package = pkgs.maple-mono.NF;
        name = "Maple Mono NF";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
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
