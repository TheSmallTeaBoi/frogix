{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.core;
in
{
  options.frogix.core = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "desktop machine defaults: timezone, zram, fonts, qt, peripheral hardware";
    };
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "UTC";
      description = "system timezone";
    };
    zram = {
      memoryPercent = lib.mkOption {
        type = lib.types.int;
        default = 50;
        description = "zram swap size as percent of RAM";
      };
      algorithm = lib.mkOption {
        type = lib.types.str;
        default = "zstd";
        description = "zram compression algorithm";
      };
    };
    fonts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        noto-fonts
        noto-fonts-color-emoji
      ];
      description = "extra system font packages (the rice's Maple Mono NF ships regardless — kitty/vitrina/emacs/qt hard-code it)";
    };
    iconPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "icon theme packages installed system-wide";
    };
    java.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "programs.java for the desktop";
    };
  };

  config = lib.mkIf cfg.enable {
    time.timeZone = cfg.timeZone;

    # I love zram.
    zramSwap = {
      enable = true;
      memoryPercent = cfg.zram.memoryPercent;
      algorithm = cfg.zram.algorithm;
    };

    programs.java.enable = cfg.java.enable;

    fonts.packages = cfg.fonts ++ [
      # the rice font — every consumer (kitty, vitrina, emacs/doom, hyprlock,
      # qt5/6ct) hard-codes "Maple Mono NF", so it must exist on every host
      pkgs.maple-mono.NF
    ];

    qt.enable = true;

    environment.systemPackages = cfg.iconPackages;

    hardware.uinput.enable = true;
    hardware.bluetooth.enable = true;
    hardware.opentabletdriver.enable = true;

    # home-manager refuses to activate when a *.backupFileExtension backup from
    # a previous activation already exists and an app has rewritten the live
    # file since (vesktop settings, qutebrowser quickmarks, mimeapps, ...).
    # sweep the stale backups right before the HM unit runs so activation can
    # always take a fresh one. apps keep rewriting; HM keeps deploying; nobody
    # wedges.
    systemd.services."hm-backup-sweep" = {
      description = "clear stale home-manager *.back files before activation";
      before = [ "home-manager-${config.frogix.user}.service" ];
      wantedBy = [ "home-manager-${config.frogix.user}.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = config.frogix.user;
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "hm-backup-sweep";
            runtimeInputs = with pkgs; [ findutils ];
            text = ''
              find "$HOME/.config" -maxdepth 3 -name '*.back' -type f -delete
            '';
          }
        );
      };
    };
  };
}
