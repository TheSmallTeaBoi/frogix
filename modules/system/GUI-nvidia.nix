{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # nvidia configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  # Firefox hardware acceleration.
  environment.variables.LIBVA_DRIVER_NAME = "nvidia";
  environment.variables.MOZ_DISABLE_RDD_SANDBOX = "1";

  programs.firefox.preferences =
    let
      ffVersion = config.programs.firefox.package.version;
    in
    {
      "media.ffmpeg.vaapi.enabled" = lib.versionOlder ffVersion "137.0.0";
      "media.hardware-video-decoding.force-enabled" = lib.versionAtLeast ffVersion "137.0.0";
      "media.rdd-ffmpeg.enabled" = lib.versionOlder ffVersion "97.0.0";

      "gfx.x11-egl.force-enabled" = true;
      "widget.dmabuf.force-enabled" = true;

      # Set this to true if your GPU supports AV1.
      #
      # This can be determined by reading the output of the
      # `vainfo` command, after the driver is enabled with
      # the environment variable.
      "media.av1.enabled" = false;
    };

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  services.libinput = {
    enable = true;

    # all my homies love mouse acceleration
    # but the libinput one is useless, doesn't get recognized by
    # games that use raw input, which KINDA makes sense but isn't what
    # a gamer wants.
    # for the actual config, chech `./yeetmouse.nix`
    mouse = {
      accelProfile = "flat";
      middleEmulation = false;
    };
  };

  services.displayManager = {
    sddm.enable = true;
    sddm.wayland.enable = true;
    defaultSession = "hyprland";
    autoLogin = {
      enable = true;
      user = "theo";
    };
  };
}
