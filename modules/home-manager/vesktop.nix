{ ... }:
{
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
}
