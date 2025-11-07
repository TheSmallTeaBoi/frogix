{
  pkgs,
  config,
  ...
}: let
in {
  stylix = {
    enable = true;
    image = config.lib.stylix.pixel "base01";
    # Choose from here https://tinted-theming.github.io/tinted-gallery/
    base16Scheme = "${pkgs.base16-schemes}/share/themes/paraiso.yaml";
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
