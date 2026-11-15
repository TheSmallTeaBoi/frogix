{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.home;
in
{
  options.frogix."home" = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "home-manager identity for the frogix user (username and homeDirectory come from the wrapper)";
    };
    stateVersion = lib.mkOption {
      type = lib.types.str;
      description = "home-manager stateVersion: the NixOS release this machine was FIRST installed on";
    };
  };

  config = lib.mkIf cfg.enable {
    home.stateVersion = cfg.stateVersion;
  };
}
