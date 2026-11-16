{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.frogix.boot;
in
{
  options.frogix.boot.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "frogix boot: latest kernel, ntsync, quiet splash, systemd-boot, memlock ulimit and performance governor";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      kernelModules = [
        "ntsync"
        "uinput"
      ];
      extraModulePackages = [
        config.boot.kernelPackages.v4l2loopback
      ];
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1
      '';
      kernel.sysctl = {
        "vm.swappiness" = lib.mkDefault 1;
        "vm.page-cluster" = 0;
      };
      kernelParams = [
        "quiet"
        "threadirqs"
        "mitigations=off"
      ];
      loader.timeout = 0;

      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      initrd.checkJournalingFS = false; # fsck seems to always fail, for whatever reason.
    };

    security.pam.loginLimits = [
      {
        domain = "@users";
        type = "-";
        item = "memlock";
        value = "unlimited";
      }
    ];

    powerManagement.cpuFreqGovernor = "performance";
  };
}
