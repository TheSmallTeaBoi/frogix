{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.frogix.services;
in
{
  options.frogix.services = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "core service stack (navidrome, syncthing, pipewire, sunshine, dbus)";
    };
    vialSerial = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "serial fragment matched by the Vial udev rule (null = no vial rule)";
    };
    navidrome = {
      musicFolder = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "navidrome library root (null = nixpkgs default)";
      };
      address = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "navidrome listen address (0.0.0.0 exposes it to the network)";
      };
    };
    syncthing = {
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/home/${config.frogix.user}/Documents";
        description = "syncthing default sync dir";
      };
      configDir = lib.mkOption {
        type = lib.types.str;
        default = "/home/${config.frogix.user}/.config/syncthing";
        description = "syncthing config dir";
      };
      devices = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "syncthing device name -> device id";
      };
      folders = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "syncthing folder label -> path";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # rtkit is optional but recommended
    security.rtkit.enable = true;
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
          ${lib.optionalString (cfg.vialSerial != null)
            "KERNEL==\"hidraw*\", SUBSYSTEM==\"hidraw\", ATTRS{serial}==\"*${cfg.vialSerial}*\", MODE=\"0660\", GROUP=\"users\", TAG+=\"uaccess\", TAG+=\"udev-acl\""
          }
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
          Address = cfg.navidrome.address;
        }
        // lib.optionalAttrs (cfg.navidrome.musicFolder != null) {
          MusicFolder = cfg.navidrome.musicFolder;
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
        # jack.enable is deprecated (global LD_LIBRARY_PATH impurity); JACK apps
        # should run through the pw-jack wrapper from pipewire.jack instead.

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
        user = config.frogix.user;
        dataDir = cfg.syncthing.dataDir;
        configDir = cfg.syncthing.configDir;
        overrideDevices = false;
        overrideFolders = false;
        settings = {
          devices = builtins.mapAttrs (name: id: { inherit id; }) cfg.syncthing.devices;
          folders = {
            "Obsidian" = {
              path = cfg.syncthing.folders."Obsidian";
              devices = [ "Phone" ];
              ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
            };
            "Org" = {
              path = cfg.syncthing.folders."Org";
              devices = [ "Phone" ];
              ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
            };
            "z7ezp-ya3ym" = {
              path = cfg.syncthing.folders."z7ezp-ya3ym";
              devices = [ "JTB" ];
              ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
            };
            "wargame-lore" = {
              path = cfg.syncthing.folders."wargame-lore";
              devices = [ "Jin's Phone" ];
              ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
            };
          };
        };
      };
    };
  };
}
