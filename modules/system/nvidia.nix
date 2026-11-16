{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.nvidia;
in
{
  options.frogix.nvidia.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "nvidia graphics stack: driver + vaapi env (firefox hw-accel prefs apply if a host enables firefox)";
  };

  config = lib.mkIf cfg.enable {
    environment.variables = {
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

    # firefox hw-accel prefs for the nvidia stack. firefox itself is a host
    # choice now (add programs.firefox.enable to the host, HM or NixOS side) —
    # these only take effect when the NixOS-side firefox is enabled, since
    # `preferences` writes into the wrapped system package
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
  };
}
