{
  config,
  pkgs,
  lib,
  ...
}:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    extraModulePackages = [
      config.boot.kernelPackages.v4l2loopback
    ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1
    '';
    kernel.sysctl = {
      "vm.swappiness" = lib.mkForce 1;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_background_bytes" = 16777216;
      "vm.dirty_bytes" = 50331648;
    };
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
