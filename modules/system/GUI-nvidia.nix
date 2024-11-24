{
  config,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services.xserver.videoDrivers = ["nvidia"];

  # nvidia configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  # Enable the X11 windowing system, sddm and set the default session as awesome
  services.xserver = {
    enable = true;
    dpi = 96;
    upscaleDefaultCursor = true;
    xkb = {
      layout = "us";
      options = "compose:menu";
    };
    autoRepeatDelay = 250;
    autoRepeatInterval = 30;

    # enable awesomewm
    windowManager.awesome = {
      enable = true;
      luaModules = with pkgs.luaPackages; [
        luarocks
        luadbi-mysql
      ];
    };
  };

  services.libinput = {
    enable = true;

    # all my homies hate mouse acceleration
    mouse = {
      accelProfile = "flat";
      middleEmulation = false;
    };
  };

  # qt use gtk theme
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita";
  };

  services.displayManager = {
    sddm.enable = true;
    sddm.theme = "catppuccin";
    defaultSession = "none+awesome";
    autoLogin = {
      enable = true;
      user = "theo";
    };
  };
}
