{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.droidcam;
in
{
  options.frogix.droidcam.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "droidcam webcam + dconf";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      droidcam = {
        enable = true;
      };
      dconf = {
        enable = true;
      };
    };
  };
}
