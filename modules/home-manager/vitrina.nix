{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    quickshell
    playerctl
    pulseaudio
  ];

  xdg.configFile."vitrina" = {
    source = ./vitrina;
    recursive = true;
  };
}
