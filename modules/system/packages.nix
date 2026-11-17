{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.frogix.packages;

  # a pack follows the master switch unless it is toggled itself
  pack =
    description:
    lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      inherit description;
    };
in
{
  options.frogix.packages = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "the frogix package sets (packs below follow this master switch)";
    };

    terminal = pack "core CLI tools (fetch, browse, clipboard, av wrangling, compression)";
    rice = pack "ricing CLI (pywal, rofi)";
    coding = pack "dev tooling (nix-alien, devenv, secret/keyring CLIs)";
    keyboard = pack "QMK firmware tooling (the Vial GUI lives in frogix.vial)";
    gui = pack "personal GUI apps (obsidian, calibre, warpinator, obs, pandoc)";
    music = pack "music listening/library tools (production plugins live in frogix.musicMaking)";
    piracy = pack "aria2 + stremio :)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      nixpkgs.config.allowUnfree = true;
    })

    (lib.mkIf cfg.terminal {
      environment.systemPackages = with pkgs; [
        clipse
        wl-clipboard
        wtype
        fzf
        ripgrep
        # neofetch # They deprecated my boy
        fastfetch
        wget
        git
        pulsemixer
        bottom
        eza
        micro
        file
        ranger # Mostly for qutebrowser to be honest.
        yt-dlp
        rclone
        ffmpeg
        brightnessctl
        playerctl
        picotts
        bubblewrap
        mp3val
        flac

        # compressed stuff
        unar
        p7zip

        # Misc
        btrfs-progs # btrfs my beloved
      ];
    })

    (lib.mkIf cfg.rice {
      environment.systemPackages = with pkgs; [
        pywal16
        psmisc
        rofi
      ];
    })

    (lib.mkIf cfg.coding {
      environment.systemPackages = with pkgs; [
        inputs.nix-alien.packages.x86_64-linux.nix-alien

        devenv
        gnome-keyring
        sops
      ];
    })

    (lib.mkIf cfg.keyboard {
      environment.systemPackages = with pkgs; [
        qmk
        qmk-udev-rules
      ];
    })

    (lib.mkIf cfg.gui {
      environment.systemPackages = with pkgs; [
        obsidian # Moving to org, keeping it for older notes, just for some time.
        pandoc
        warpinator
        appimage-run
        calibre

        # Art?
        obs-studio
      ];
    })

    (lib.mkIf cfg.music {
      environment.systemPackages = with pkgs; [
        nicotine-plus
        picard
        mpv
        feishin
      ];
    })

    (lib.mkIf cfg.piracy {
      environment.systemPackages = with pkgs; [
        # Piracy stuff :)
        aria2
        stremio-linux-shell
      ];
    })
  ];
}
