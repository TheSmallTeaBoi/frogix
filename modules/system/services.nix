{
  pkgs,
  lib,
  config,
  ...
}:
{
  systemd.services.navidrome = {
    # Otherwise it starts before the music library gets mounted
    after = [ "home-theo-Data.mount" ];
    requires = [ "home-theo-Data.mount" ];
    serviceConfig = {
      ProtectHome = lib.mkForce "read-only";
      EnvironmentFile = config.sops.secrets.navidrome_env.path;
    };
  };

  systemd.oomd.enable = false;

  services = {
    # This is needed for Vial and plover
    udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    '';

    # Drive mounting
    gvfs = {
      enable = true;
      package = pkgs.gvfs;
    };

    udisks2.enable = true;

    # Does anyone know how to only apply this to SSDs?
    fstrim.enable = true;

    ratbagd.enable = true;

    mysql = {
      enable = true;
      package = pkgs.mariadb;
    };

    tailscale.enable = true;

    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      acceleration = "cuda";
    };

    navidrome = {
      enable = true;
      settings = {
        MusicFolder = "/home/theo/Data/Music/";
        Address = "0.0.0.0";
      };
    };

    gnome.gnome-keyring.enable = true;

    dbus = {
      enable = true;
      implementation = "broker";
    };

    # Enable sound.
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # Enable the OpenSSH daemon.
    openssh.enable = true;

    earlyoom.enable = true;

    # Syncthing
    syncthing = {
      enable = true;
      user = "theo";
      dataDir = "/home/theo/Documents";
      configDir = "/home/theo/.config/syncthing";
      overrideDevices = true; # overrides any devices added or deleted through the WebUI
      overrideFolders = true; # overrides any folders added or deleted through the WebUI
      settings = {
        devices = {
          "Phone" = {
            id = "WCFUTSH-VU6QZOM-SJEHLLF-OFRDX3T-PWPHBX6-XNRV3VZ-AQZWC6X-36A5OAV";
          };
          "JTB" = {
            id = "MHKUJWR-YK2YZ2X-2C6AJRB-HEG6YBJ-FTL6PEA-ZGDLMOF-NL43P2P-6RDXKAY";
          };
          "Jin's Phone" = {
            id = "JHQQYZL-7WPU4G4-2XAPPAP-273XKST-DFG463C-4IWV6WH-BN6Y7VO-2XJ7VAW";
          };
        };
        folders = {
          "Books" = {
            path = "/home/theo/Data/Books/";
            devices = [ "Phone" ];
            ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          };
          "Obsidian" = {
            path = "/home/theo/Data/Personal/obsidian";
            devices = [ "Phone" ];
            ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          };
          "z7ezp-ya3ym" = {
            path = "/home/theo/Rattus/musik/02 Projects/collab/";
            devices = [ "JTB" ];
            ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          };
          "wargame-lore" = {
            path = "/home/theo/Data/Personal/wargame/";
            devices = [ "Jin's Phone" ];
            ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          };
        };
      };
    };
  };
}
