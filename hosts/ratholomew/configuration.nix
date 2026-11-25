{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "ratholomew"; # Define your hostname.
  system.stateVersion = "23.11"; # Did you read the comment?

  # Impermanent tmpfs root on top of the existing ext4 SSD partition.
  # /dev/disk/by-label/nixos already has /nix, /var/lib, /etc and /home/theo
  # at its top level, so mounting it at /persist and bind-mounting /persist/nix
  # to /nix needs no file migration and lets earlier systemd-boot generations
  # roll back cleanly to the old non-impermanent ext4 root.
  fileSystems."/" = lib.mkForce {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=8G"
      "mode=755"
    ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/persist/nix";
    fsType = "none";
    neededForBoot = true;
    depends = [ "/persist" ];
    options = [ "bind" ];
  };

  programs.firefox.enable = true;

  # the frogix module suite. module defaults are universal; this block is
  # where ratholomew differs from them.
  frogix = {
    enable = true;
    user = "theo";

    core = {
      timeZone = "America/Buenos_Aires";
      fonts = with pkgs; [
        # maple-mono.NF ships with core (rice font) — only extra fonts go here

        noto-fonts
        noto-fonts-lgc-plus
        google-fonts
      ];
      iconPackages = with pkgs; [
        numix-icon-theme-circle
        colloid-icon-theme
      ];
      java.enable = true;
    };

    nix = {
      caches."https://cache.nixos-cuda.org" =
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=";
      permittedInsecurePackages = [
        "qutebrowser-3.7.0"
      ];
      # was false (docs slow generations) — jerrito needs man pages + `man -k` (mandb)
      documentation = true;
    };

    networkd = {
      interfaces = [ "enp38s0" ];
      firewall = false;
    };

    # the editor/browser env vars are machine choices (the module leaves them
    # unset by default): this host runs emacs + qutebrowser
    shell = {
      editor = "emacsclient -c";
      browser = "qutebrowser";
    };

    pi.enable = true;
    "computer-use-linux".enable = true;

    services = {
      navidrome.musicFolder = "/storage/Music/";
      navidrome.address = "0.0.0.0";
      syncthing.devices = {
        Phone = "WCFUTSH-VU6QZOM-SJEHLLF-OFRDX3T-PWPHBX6-XNRV3VZ-AQZWC6X-36A5OAV";
        JTB = "MHKUJWR-YK2YZ2X-2C6AJRB-HEG6YBJ-FTL6PEA-ZGDLMOF-NL43P2P-6RDXKAY";
        "Jin's Phone" = "JHQQYZL-7WPU4G4-2XAPPAP-273XKST-DFG463C-4IWV6WH-BN6Y7VO-2XJ7VAW";
        Manage = "LK5X5SY-RRTT6BP-MSDUACH-YX24N6H-4QRXMZC-WWTB7TF-7VPISRE-AY45UAH";
      };
      syncthing.folders = {
        Obsidian = "/storage/Personal/obsidian";
        Org = "/storage/Personal/Org";
        "z7ezp-ya3ym" = "/storage/musik/02 Projects/collab/";
        "wargame-lore" = "/storage/Personal/wargame/";
      };
    };

    romm = {
      libraryDir = "/storage/Roms";
      biosDir = "/storage/Bios";
      resourcesDir = "/storage/RommResources/resources";
      useTosec = true;
    };

    torbox.enable = true;
    "torbox-music-sync".enable = true;
    "torbox-music-sync".musicDir = "/storage/Music";

    display.autoLogin = true;

    # Populate /etc/shadow declaratively from sops so tmpfs root reboots never
    # lock out login/sudo (key: user_password_hash in modules/system/secrets/secrets.yaml).
    users.hashedPasswordSecret = "user_password_hash";

    impermanence = {
      enable = true;
      persistLogs = true;

      user = {
        directories = [
          ".barony"
          ".config"
          ".gemini"
          {
            directory = ".gnupg";
            mode = "0700";
          }
          ".local/share/7DaysToDie"
          ".local/share/Beam Eye Tracker"
          ".local/share/BeamNG"
          ".local/share/Cemu"
          ".local/share/LookPilot"
          ".local/share/PrismLauncher"
          ".local/share/Steam"
          ".local/share/Valve Corporation"
          ".local/share/aspyr-media"
          ".local/share/automodpack"
          ".local/share/azahar-emu"
          ".local/share/binding of isaac rebirth"
          ".local/share/com.nesbox.tic"
          ".local/share/direnv"
          ".local/share/dolphin-emu"
          ".local/share/easyeffects"
          ".local/share/eden"
          ".local/share/fish"
          {
            directory = ".local/share/keyrings";
            mode = "0700";
          }
          ".local/share/net.lutris.Lutris"
          ".local/share/nicotine"
          ".local/share/qutebrowser"
          ".local/share/reshade"
          ".local/share/rofi"
          ".local/share/umu"
          ".local/share/xodus-nexus"
          ".local/share/yuzu"
          ".local/share/zoxide"
          ".local/state/Beyond All Reason"
          ".local/state/beammp"
          ".local/state/lazygit"
          ".local/state/theotown"
          ".local/state/wireplumber"
          ".parsec"
          ".parsec-persistent"
          ".pi"
          {
            directory = ".ssh";
            mode = "0700";
          }
          ".steam"
          ".wine"
          "Flashpoint"
          "frogix"
        ];

        files = [
          ".claude.json"
          ".git-credentials"
        ];
      };
    };
  };

  # host service choices — plain NixOS options, deliberately NOT frogix.*
  # toggles (services with no frogix-specific value are enabled directly;
  # see docs/architecture.md "module contract")
  programs.droidcam.enable = true;
  programs.dconf.enable = true;
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "theo" ];
  virtualisation.libvirtd = {
    enable = true;
    # x86_64 VMs only — drops ~600 MiB of non-x86 QEMU target emulators
    qemu.package = pkgs.qemu_kvm;
  };
  virtualisation.spiceUSBRedirection.enable = true;

  programs.nano.enable = false;

  programs.jerrito.enable = true;

  home-manager.users.theo = {
    frogix.home.stateVersion = "23.11";
    frogix.screens = {
      main = "DP-4";
      left = "HDMI-A-1";
      right = "HDMI-A-3";

      # logical (post-transform) widths; niri.nix computes the x offsets in
      # left -> main -> right order
      autoLayout.widths = {
        left = 768; # 1366x768 rotated 270
        main = 1920; # 1920x1080
        right = 1366; # 1366x768
      };

      outputs = [
        {
          _args = [ "DP-4" ];
          mode = "1920x1080@180";
          scale = 1.0;
          focus-at-startup = { };
          # variable-refresh-rate = { };
        }
        {
          _args = [ "HDMI-A-1" ];
          mode = "1366x768@59.79";
          scale = 1.0;
          position._props.y = -50; # taller than main: poke above the top edge
          transform = "270";

          # Niri works like shit with vertical screens 🥀
          layout = {
            default-column-width.proportion = 1.0;
            preset-column-widths.proportion = 1.0;
            always-center-single-column = { };
          };
        }
        {
          _args = [ "HDMI-A-3" ];
          mode = "1366x768@59.79";
          scale = 1.0;
          position._props.y = 312; # ride the bottom edge
        }
      ];
    };

    # HDMI-A-3 cannot be DPMS-blanked (it comes back in the wrong mode), so
    # leave it powered on; hyprlock's black background covers it at idle.
    frogix.niri.keepOnOutputs = [ "HDMI-A-3" ];

    frogix.wallpapersDir = "/storage/Walls";
    frogix.audio.mixerElement = "Emotiva Little Ego";
    frogix.beets.libraryDir = "/storage/Music/";
    frogix.beets.convertDest = "/storage/music-lossier/";
    # host service choices, hm side (not frogix.* toggles):
    services.easyeffects = {
      enable = true;
      preset = "Voice Moondrop";
    };
    programs.lazygit.enable = true;
    programs.zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
    };
    frogix.git.email = "theoiturri@tutanota.com";
    frogix.git.name = "TheSmallTeaBoi";
    frogix.iamb.matrixId = "@thesmallteaboi:matrix.org";
    frogix.sunshine.output = "DP-3";
    frogix.emacs.orgDirectory = "/storage/Personal/Org/";

    programs.qutebrowser.quickmarks = {
      # Social
      whatsapp = "https://web.whatsapp.com/";
      element = "https://app.element.io";
      telegram = "https://web.telegram.org";
      reddit = "https://reddit.com";

      # Entertainment
      youtube = "https://youtube.com";
      ytm = "https://music.youtube.com";
      twitch = "https://twitch.tv";
      netflix = "https://netflix.com";

      # Piracy & media
      torbox = "https://torbox.app";
      archive = "https://archive.org";
      annas = "https://shadowlibraries.github.io/DirectDownloads/AnnasArchive";
      fmhy = "https://fmhy.net";
      bunkr = "https://balbums.st";

      # Development
      github = "https://github.com";
      gitlab = "https://gitlab.com";

      # AI
      aistudio = "https://aistudio.google.com";
      claude = "https://claude.ai";
      chatgpt = "https://chatgpt.com";
      deepseek = "https://chat.deepseek.com";

      # Productivity
      gmail = "https://mail.google.com";
      drive = "https://drive.google.com";
      translate = "https://translate.google.com";
      linguee = "https://www.linguee.com";

      # Others
      marketplace = "https://www.facebook.com/marketplace";
    };
  };
}
