{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.vesktop;
in
{
  options.frogix."vesktop".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "vesktop with hw accel and arRPC";
  };

  config = lib.mkIf cfg.enable {
    programs.vesktop = {
      enable = true;
      settings = {
        discordBranch = "stable";
        tray = false;
        minimizeToTray = false;
        hardwareVideoAcceleration = true;
        disableMinSize = true;
        arRPC = true;
        enabledThemes = [ "custom.css" ];
      };
    };
  };
}
