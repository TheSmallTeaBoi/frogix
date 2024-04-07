{ 
  config,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

  # Enable cuda, cuda my beloved
  #nixpkgs.config.cudaSupport = true;

  environment.systemPackages = with pkgs; [
    cudatoolkit
  ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  # nvidia configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };


  # Enable the X11 windowing system, sddm and set the default session as awesome
  services.xserver = {
    enable = true;
    displayManager = {
      sddm.enable = true;
      sddm.theme = "catppuccin";
      defaultSession = "none+awesome";
      autoLogin = {
        enable = true;
        user = "theo";
      };
    };

    libinput = {
      enable = true;

      # all my homies hate mouse acceleration
      mouse = {
        accelProfile = "flat";
      };
    };
    xkb.layout = "us";
    

  # enable awesomewm
  windowManager.awesome = {
    enable = true;
    luaModules = with pkgs.luaPackages; [
      luarocks
      luadbi-mysql
      ];
    };
  };

}
