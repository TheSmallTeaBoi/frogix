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
    musicPlayer = lib.mkOption {
      type = lib.types.submodule {
        options = {
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.feishin;
            defaultText = lib.literalExpression "pkgs.feishin";
            description = "the player package the music pack installs";
          };
          command = lib.mkOption {
            type = lib.types.str;
            default = "feishin";
            description = "executable niri spawns on Mod+L (a bare name resolves against the installed package)";
          };
          appId = lib.mkOption {
            type = lib.types.str;
            default = "feishin";
            description = "Wayland app-id niri matches to float the player window";
          };
        };
      };
      default = { };
      description = ''
        which music player the music pack installs and niri launches on
        Mod+L; switch it per host (package, launch command, and window app-id)
      '';
    };
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
        inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien

        devenv
        gnome-keyring
        sops
      ];
    })

    (lib.mkIf cfg.keyboard {
      environment.systemPackages = with pkgs; [
        qmk
      ];
      services.udev.packages = [ pkgs.qmk-udev-rules ];
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
        beets
        cfg.musicPlayer.package
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
