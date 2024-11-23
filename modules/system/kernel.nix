{
  config,
  pkgs,
  ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
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
  };

  powerManagement.cpuFreqGovernor = "performance";
}
