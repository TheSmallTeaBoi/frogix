{
  pkgs,
  lib,
  config,
  ...
}:
{
  systemd.services.navidrome = {
    # Otherwise it starts before the music library gets mounted
    after = [ "storage.mount" ];
    requires = [ "storage.mount" ];
    serviceConfig.PrivateUsers = lib.mkForce false;
    serviceConfig = {
      RootDirectory = lib.mkForce "";
      ProtectHome = lib.mkForce "read-only";
      EnvironmentFile = config.sops.secrets.navidrome_env.path;
    };
  };

  systemd.oomd.enable = false;

  security.pam.services.sddm.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.hyprlock = { };

  services = {
    infract = {
      enable = true;
      environment = {
        INFRACT_CONVERTER = "SINPUT";
      };
    };

    udev.extraRules =
      # Udev
      ''
        # This is needed for Vial and plover
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
        KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"

        # Allows Sunshine to access /dev/uinput
        KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
        # Allows Sunshine to access /dev/uhid
        KERNEL=="uhid", TAG+="uaccess"

        # Joypads
        KERNEL=="hidraw*" ATTRS{name}=="Sunshine PS5 (virtual) pad" MODE="0660", TAG+="uaccess"
        SUBSYSTEMS=="input", ATTRS{name}=="Sunshine X-Box One (virtual) pad", MODE="0660", TAG+="uaccess"
        SUBSYSTEMS=="input", ATTRS{name}=="Sunshine gamepad (virtual) motion sensors", MODE="0660", TAG+="uaccess"
        SUBSYSTEMS=="input", ATTRS{name}=="Sunshine Nintendo (virtual) pad", MODE="0660", TAG+="uaccess"

        # Chirp
        SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", MODE="0666"

        # Alpakka controller
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="045e", MODE="0660", GROUP="plugdev", SYMLINK+="webusb", TAG+="uaccess"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="0170", MODE="0660", GROUP="plugdev", SYMLINK+="webusb", TAG+="uaccess"
      '';

    # Drive mounting
    gvfs = {
      enable = true;
      package = pkgs.gvfs;
    };

    udisks2.enable = true;

    # Does anyone know how to only apply this to SSDs?
    fstrim.enable = true;

    # Bluetooth
    blueman.enable = true;

    mysql = {
      enable = true;
      package = pkgs.mariadb;
    };

    tailscale.enable = true;

    sunshine = {
      enable = true;
      # Start with the graphical session; it never gets socket-activated
      autoStart = true;
      package = pkgs.sunshine.override { cudaSupport = true; };
    };

    input-remapper.enable = true;

    navidrome = {
      enable = true;
      settings = {
        MusicFolder = "/storage/Music/";
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

      # Emotiva Little Ego+ (usb-20ee:0020): 44.1..384 kHz, S32_LE/DSD.
      # Quantum 64 measured stable 2026-11-13 (DAC hw period 32 @48k, 16 at
      # force-quantum 32, zero kernel usb-audio errors). Bump to 128/256 if
      # xruns crackle — this is the one latency knob.
      # Graph pinned at 96k (2026-11-13): vesktop holds a resident 48k output
      # stream that vetoes auto rate-switching while active, so the DAC sat at
      # 48k whenever discord ran. Pinned 96k = DAC always 24-bit/96k; 48k
      # sources resample at exact 2.0 ratio (quality 14). allowed-rates still
      # lets a 176.4/192k stream re-clock the graph when no 48k anchor is up.
      extraConfig = {
        pipewire."92-hires-clock" = {
          "context.properties" = {
            "default.clock.rate" = 96000;
            "default.clock.allowed-rates" = [
              44100
              48000
              88200
              96000
              176400
              192000
              352800
              384000
            ];
            "default.clock.quantum" = 64;
            "default.clock.max-quantum" = 2048;
            "default.clock.min-quantum" = 32;
            "resample.quality" = 14;
          };
        };
        pipewire-pulse."92-pulse-f32" = {
          "pulse.properties" = {
            "pulse.default.format" = "F32";
            "pulse.default.rate" = 48000;
          };
        };
      };

      wireplumber.extraConfig."92-emotiva-s32le" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { node.name = "~alsa_output\\.usb-Emotiva.*"; }
            ];
            actions.update-props = {
              "audio.format" = "S32_LE";
            };
          }
        ];
      };
    };

    # Enable the OpenSSH daemon.
    openssh.enable = true;

    earlyoom.enable = true;

    # Syncthing
    syncthing = {
      enable = false;
      user = "theo";
      dataDir = "/home/theo/Documents";
      configDir = "/home/theo/.config/syncthing";
      overrideDevices = false;
      overrideFolders = false;
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
          "Manage" = {
            id = "LK5X5SY-RRTT6BP-MSDUACH-YX24N6H-4QRXMZC-WWTB7TF-7VPISRE-AY45UAH";
          };
        };
        folders = {
          "Obsidian" = {
            path = "/storage/Personal/obsidian";
            devices = [ "Phone" ];
            ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          };
          "Org" = {
            path = "/storage/Personal/Org";
            devices = [ "Phone" ];
            ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          };
          "z7ezp-ya3ym" = {
            path = "/storage/musik/02 Projects/collab/";
            devices = [ "JTB" ];
            ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          };
          "wargame-lore" = {
            path = "/storage/Personal/wargame/";
            devices = [ "Jin's Phone" ];
            ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          };
        };
      };
    };
  };
}
