{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.mako = {
    enable = false;
    extraConfig = ''
      default-timeout=7500
      text-alignment=center
      anchor=top-center
      outer-margin=5
      include=~/.cache/wal/mako-colors

      [mode=do-not-disturb]
      invisible=1
    '';
  };
}
