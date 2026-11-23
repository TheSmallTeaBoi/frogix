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
      kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      kernelModules = [
        "ntsync"
        "bfq"
      ];
      extraModulePackages = [
        config.boot.kernelPackages.v4l2loopback
      ];
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1
      '';
      kernel.sysctl = {
        # zram swaps in RAM (compressed) rather than disk, so a high swappiness
        # lets the kernel compress cold anonymous pages instead of evicting hot
        # page cache; priority 90 beats musnix's default (10) while still
        # letting a host mkForce override it.
        "vm.swappiness" = lib.mkOverride 90 (if config.zramSwap.enable then 150 else 10);
        "vm.page-cluster" = 0;
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 125;
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };
      kernelParams = [
        "quiet"
        "threadirqs"
      ];
      loader.timeout = lib.mkDefault 0;

      loader = {
        systemd-boot = {
          enable = lib.mkDefault true;
          configurationLimit = lib.mkDefault 20;
        };
        efi.canTouchEfiVariables = lib.mkDefault true;
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

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

    # BFQ keeps spinning HDDs responsive under concurrent background scans
    # (plocate, beets, romm) without affecting SSDs/NVMe.
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    '';

    # sched_ext latency-aware desktop/gaming scheduler (Linux 6.12+); falls
    # back cleanly to EEVDF if ever unloaded.
    services.scx-loader = {
      enable = lib.mkDefault true;
      config = {
        default_sched = lib.mkDefault "scx_lavd";
        default_mode = lib.mkDefault "Auto";
      };
    };
  };
}
