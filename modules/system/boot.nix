{
  config,
  pkgs,
  ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest; # I live in the edge
    extraModulePackages = [
      config.boot.kernelPackages.v4l2loopback
    ];
    kernel.sysctl = {
      "vm.swappiness" = 200;
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
