{...}: {
  xdg.desktopEntries = {
    steam = {
      name = "Steam";
      genericName = "Game Store";
      exec = "steam -no-cef-sandbox";
      icon = "steam";
      terminal = false;
      categories = ["Application"];
    };
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
}
