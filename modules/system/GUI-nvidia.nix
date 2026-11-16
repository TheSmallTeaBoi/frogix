{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix."GUI-nvidia";
in
{
  options.frogix."GUI-nvidia".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "nvidia graphics stack, sddm autologin and niri session defaults";
  };
  options.frogix."GUI-nvidia".autoLogin = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "autologin the frogix user on the sddm niri session (off by default)";
  };

  config = lib.mkIf cfg.enable {
    # Enable Theme
    environment.variables = {
      NIXOS_OZONE_WL = "1";
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      MOZ_DISABLE_RDD_SANDBOX = "1";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
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
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

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
        "media.av1.enabled" = true;
      };

    programs.niri = {
      enable = true;
    };

    services.libinput = {
      enable = true;

      # all my homies love mouse acceleration
      # but the libinput one is useless, doesn't get recognized by
      # games that use raw input, which KINDA makes sense but isn't what
      # a gamer wants.
      mouse = {
        accelProfile = "flat";
        middleEmulation = false;
      };
    };

    services.displayManager = {
      sddm.enable = true;
      sddm.wayland.enable = true;
      defaultSession = "niri";
      autoLogin = {
        enable = cfg.autoLogin;
        user = config.frogix.user;
      };
    };
  };
}
