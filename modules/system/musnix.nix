{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.musnix;
in
{
  options.frogix.musnix.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "musnix realtime audio tweaks";
  };

  config = lib.mkIf cfg.enable {
    musnix = {
      enable = true;
    };
  };
}
