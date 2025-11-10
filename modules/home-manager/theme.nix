{ ... }:
{
  stylix = {
    targets = {
      firefox = {
        profileNames = [ "theo" ];
        colorTheme.enable = true;
      };
      vencord.enable = true;
      vesktop.enable = true;
      waybar.addCss = false;
    };
  };
}
