{
  inputs,
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

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  services.libinput = {
    enable = true;

    # all my homies love mouse acceleration
    # but the libinput one is useless, doesn't get recognized by
    # games that use raw input, which makes sense but isn't what
    # a gamer wants.
    # for the actual config, chech `./yeetmouse.nix`
    mouse = {
      accelProfile = "flat";
      middleEmulation = false;
    };
  };

  services.displayManager = {
    sddm.enable = true;
    sddm.theme = "catppuccin";
    sddm.wayland.enable = true;
    defaultSession = "hyprland";
    autoLogin = {
      enable = true;
      user = "theo";
    };
  };
}
