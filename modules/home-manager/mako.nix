{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.mako;
in
{
  options.frogix."mako".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "mako notification daemon config (daemon itself stays disabled)";
  };

  config = lib.mkIf cfg.enable {
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
  };
}
