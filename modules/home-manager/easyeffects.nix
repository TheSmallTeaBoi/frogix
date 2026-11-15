{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.easyeffects;
in
{
  options.frogix."easyeffects".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "easyeffects with a default preset";
  };

  options.frogix.easyeffects.preset = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "easyeffects preset applied on start (null = leave unset)";
  };

  config = lib.mkIf cfg.enable {
    services.easyeffects = {
      enable = true;
      preset = lib.mkIf (cfg.preset != null) cfg.preset;
    };
  };
}
