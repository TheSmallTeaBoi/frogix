{config, pkgs,...}:
{
  boot = {
    extraModulePackages = [
      config.boot.kernelPackages.v4l2loopback
    ];
    kernel.sysctl = {
      "vm.swappiness" = 200;
    };
    kernelParams = [
      "quiet"
    ];
  };
}
