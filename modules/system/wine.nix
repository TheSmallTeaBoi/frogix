{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.wine;
in
{
  options.frogix.wine.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "wine (wow64) + winetricks";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # single wow64 build supporting both 32- and 64-bit Windows apps (multiple
      # wine builds in systemPackages collide on /bin/wine and bloat the store)
      wineWow64Packages.stable
      winetricks
    ];
  };
}
