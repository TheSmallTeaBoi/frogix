{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.desktop;
in
{
  options.frogix."desktop".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "user desktop entries";
  };

  config = lib.mkIf cfg.enable {
    # the entry launches vesktop, which frogix.vesktop owns — only emit it when
    # that area is on.
    xdg.desktopEntries = lib.mkIf config.frogix.vesktop.enable {
      vesktop = {
        name = "Vesktop";
        exec = "vesktop --enable-features=VaapiIgnoreDriverChecks,VaapiVideoEncoder,VaapiVideoDecoder,UseMultiPlaneFormatForHardwareVideo";
        icon = "vesktop";
        genericName = "Internet Messenger";
        categories = [
          "Network"
          "InstantMessaging"
          "Chat"
        ];
      };
    };
  };
}
