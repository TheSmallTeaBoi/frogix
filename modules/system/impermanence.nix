# Declarative state persistence for ephemeral (tmpfs / rollback) root
# filesystems via nix-community/impermanence.
#
# Opt-in (default = false): impermanence requires matching host disk/mount
# configuration (a persistent volume marked neededForBoot = true, plus an
# ephemeral root) and a declarative user password so /etc/shadow resets do
# not lock out login/sudo. Keep hardware/disk mounts strictly in hosts/<name>/.
{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.impermanence;
  user = config.frogix.user;
  userCfg = config.users.users.${user};
  hasDeclarativePassword =
    userCfg.hashedPasswordFile != null
    || userCfg.hashedPassword != null
    || userCfg.initialHashedPassword != null
    || userCfg.initialPassword != null;
  isTmpfsRoot = (config.fileSystems."/".fsType or null) == "tmpfs";
in
{
  options.frogix.impermanence = {
    # deliberate break from the default-to-frogix.enable contract: enabling
    # impermanence requires a host-configured persistent mount (neededForBoot)
    # and a declarative user password; defaulting on would break non-impermanent
    # hosts and the VM.
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        persist only declared system and user state under persistPath using
        nix-community/impermanence (NixOS bind mounts, not Home Manager
        symlinks). auto-persists state for enabled frogix/system services,
        redirects sops-nix's age key and sshd host keys into persistPath, and
        caps journald/coredump usage. host disk mounts (/, /persist, /nix) stay
        in hosts/<name>/
      '';
    };

    persistPath = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "mountpoint of the persistent filesystem (must have neededForBoot = true in the host's fileSystems)";
    };

    hideMounts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "pass x-gvfs-hide to bind mounts so file managers do not list every persisted path as a separate volume";
    };

    persistLogs = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "persist /var/log across reboots (journald is capped by journalMaxUse so logs cannot fill the persistent disk)";
    };

    journalMaxUse = lib.mkOption {
      type = lib.types.str;
      default = "500M";
      description = "systemd-journald storage cap (SystemMaxUse when persistLogs is on, RuntimeMaxUse when off)";
    };

    coredumpMaxUse = lib.mkOption {
      type = lib.types.str;
      default = "500M";
      description = "systemd-coredump storage cap under /var/lib/systemd/coredump";
    };

    extraDirectories = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
      description = "additional system directories to persist under persistPath (strings or impermanence directory attrsets)";
    };

    extraFiles = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
      description = "additional system files to persist under persistPath (strings or impermanence file attrsets)";
    };

    user = {
      directories = lib.mkOption {
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
        default = [ ];
        description = ''
          directories relative to frogix.user's home directory to persist via
          NixOS bind mounts (environment.persistence.<persistPath>.users.<user>)
          so apps doing atomic writes do not break
        '';
      };

      files = lib.mkOption {
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
        default = [ ];
        description = "files relative to frogix.user's home directory to persist via NixOS bind mounts";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !isTmpfsRoot || !config.frogix.users.enable || hasDeclarativePassword;
        message = ''
          frogix.impermanence: root (/) is tmpfs, which wipes /etc/shadow on reboot,
          but ${user} has no declarative password configured. Set
          frogix.users.hashedPasswordSecret (or hashedPasswordFile) so login/sudo
          are not locked out after reboot.
        '';
      }
    ];

    # sops-nix runs during early activation before user bind mounts exist;
    # read the age key directly from persistent storage. priority 900 beats the
    # option default while still letting a host set an explicit path.
    frogix.sops.ageKeyFile = lib.mkIf config.frogix.sops.enable (
      lib.mkOverride 900 "${cfg.persistPath}/home/${user}/.config/sops/age/keys.txt"
    );

    # Point sshd host keys directly into persistPath instead of bind-mounting
    # /etc/ssh (which also holds NixOS-managed /etc/static/ssh/* symlinks) or
    # individual files (which would pre-create empty files before ssh-keygen).
    services.openssh.hostKeys = lib.mkIf config.services.openssh.enable (
      lib.mkDefault [
        {
          type = "rsa";
          bits = 4096;
          path = "${cfg.persistPath}/etc/ssh/ssh_host_rsa_key";
        }
        {
          type = "ed25519";
          path = "${cfg.persistPath}/etc/ssh/ssh_host_ed25519_key";
        }
        {
          type = "mldsa44-ed25519";
          path = "${cfg.persistPath}/etc/ssh/ssh_host_mldsa44_ed25519_key";
        }
      ]
    );

    # Cap journald and coredumps so neither /var/log nor /var/lib/systemd
    # (nor tmpfs RAM when persistLogs = false) grows without bound.
    services.journald.settings.Journal =
      if cfg.persistLogs then
        { SystemMaxUse = lib.mkDefault cfg.journalMaxUse; }
      else
        { RuntimeMaxUse = lib.mkDefault cfg.journalMaxUse; };

    systemd.coredump.settings.Coredump = {
      MaxUse = lib.mkDefault cfg.coredumpMaxUse;
    };

    environment.persistence.${cfg.persistPath} = {
      hideMounts = cfg.hideMounts;

      files = [
        "/etc/machine-id"
      ]
      ++ cfg.extraFiles;

      directories = [
        # NixOS UID/GID maps and declarative user tracking — critical so
        # dynamic system IDs never shift across reboots.
        "/var/lib/nixos"
        "/var/lib/systemd"
      ]
      ++ lib.optional cfg.persistLogs "/var/log"
      ++ lib.optional config.hardware.bluetooth.enable "/var/lib/bluetooth"
      ++ lib.optional config.networking.wireless.iwd.enable "/var/lib/iwd"
      ++ lib.optional config.services.tailscale.enable "/var/lib/tailscale"
      ++ lib.optional config.services.displayManager.sddm.enable "/var/lib/sddm"
      ++ lib.optional config.services.infract.enable "/var/lib/infract"
      ++ lib.optional config.services.mysql.enable "/var/lib/mysql"
      ++ lib.optional config.services.postgresql.enable "/var/lib/postgresql"
      ++ lib.optional config.services.navidrome.enable "/var/lib/navidrome"
      ++ lib.optionals config.services.romm.enable [
        "/var/lib/romm"
        "/var/lib/redis-romm"
      ]
      ++ lib.optional config.virtualisation.libvirtd.enable "/var/lib/libvirt"
      ++ lib.optional config.frogix."torbox-music-sync".enable "/var/lib/torbox-music-sync"
      ++ lib.optional (
        config.frogix.gaming.enable || config.services.logmein-hamachi.enable
      ) "/var/lib/logmein-hamachi"
      ++ cfg.extraDirectories;

      users.${user} = {
        directories = cfg.user.directories;
        files = cfg.user.files;
      };
    };
  };
}
