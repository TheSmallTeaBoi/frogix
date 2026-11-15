{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.gaming;
in
{
  options.frogix.gaming.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "gamemode + gpu-screen-recorder";
  };

  config = lib.mkIf cfg.enable {
    programs.gpu-screen-recorder.enable = true;
    programs.gamemode.enable = true;
  };
}
