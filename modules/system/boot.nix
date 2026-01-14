{
  config,
  pkgs,
  lib,
  ...
}:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = [
      config.boot.kernelPackages.v4l2loopback
    ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1
    '';
    kernel.sysctl = {
      "vm.swappiness" = lib.mkForce 1;
      "vm.page-cluster" = 0;
    };
    kernelParams = [
      "quiet"
      "threadirqs"
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
