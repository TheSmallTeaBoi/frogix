{
  config,
  pkgs,
  ...
}:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod;
    extraModulePackages = [
      config.boot.kernelPackages.v4l2loopback
    ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1
    '';
    kernelParams = [
      "quiet"
    ];
    loader.timeout = 0;

    # Use the systemd-boot EFI boot loader.
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd.checkJournalingFS = false; # fsck seems to always fail, for whatever reason.
  };

  powerManagement.cpuFreqGovernor = "performance";
}
