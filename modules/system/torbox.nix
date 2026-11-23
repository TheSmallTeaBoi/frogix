{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.frogix.torbox;
  mountPoint = cfg.mountPoint;
  confDir = "/run/rclone-torbox";
  confFile = "${confDir}/rclone.conf";
  userSecret = config.sops.secrets.torbox_webdav_user.path;
  passSecret = config.sops.secrets.torbox_webdav_pass.path;

  # Build the rclone.conf at runtime from the two plaintext sops secrets.
  # Obscure the password via stdin so the plaintext never appears in
  # /proc/<pid>/cmdline.
  genConf = pkgs.writeShellApplication {
    name = "torbox-rclone-conf";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.rclone
    ];
    text = ''
      umask 077
      mkdir -p ${lib.escapeShellArg confDir}
      u=$(tr -d '\r\n' < ${lib.escapeShellArg userSecret})
      obscured=$(tr -d '\r\n' < ${lib.escapeShellArg passSecret} | rclone obscure -)
      tmp="${confFile}.tmp"
      printf '[torbox]\ntype = webdav\nurl = https://webdav.torbox.app\nvendor = other\nuser = %s\npass = %s\n' \
        "$u" "$obscured" > "$tmp"
      chown root:users ${lib.escapeShellArg confDir} "$tmp"
      chmod 750 ${lib.escapeShellArg confDir}
      chmod 640 "$tmp"
      mv -f "$tmp" ${lib.escapeShellArg confFile}
    '';
  };
in
{
  options.frogix.torbox = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "TorBox WebDAV rclone mount";
    };
    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/torbox";
      description = "where the webdav remote is mounted";
    };
  };

  config = lib.mkIf cfg.enable {
    # torbox builds its rclone config from the sops secrets torbox_webdav_user
    # / torbox_webdav_pass, so sops has to be on.
    assertions = [
      {
        assertion = config.frogix.sops.enable;
        message = "frogix.torbox: the rclone remote is built from the sops secrets `torbox_webdav_user` / `torbox_webdav_pass`, so frogix.sops has to be on.";
      }
    ];

    environment.systemPackages = [ pkgs.rclone ];

    systemd.services.torbox-webdav = {
      description = "TorBox WebDAV mount (rclone)";
      after = [
        "network-online.target"
        "sops-nix.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "notify";
        TimeoutStartSec = "30s";
        Environment = [ "PATH=/run/wrappers/bin:/run/current-system/sw/bin" ];
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg mountPoint}"
        ]
        ++ lib.optionals config.frogix.sops.enable [ (lib.getExe genConf) ];
        ExecStart =
          "${pkgs.rclone}/bin/rclone mount torbox: ${lib.escapeShellArg mountPoint}"
          + " --config ${confFile}"
          + " --vfs-cache-mode full"
          + " --vfs-cache-max-size 10G"
          + " --vfs-cache-max-age 24h"
          + " --dir-cache-time 15m"
          + " --cache-dir /var/cache/rclone/torbox"
          + " --allow-other"
          + " --umask 022"
          + " --file-perms 0644"
          + " --dir-perms 0755";
        ExecStopPost = "-/run/wrappers/bin/fusermount3 -uz ${lib.escapeShellArg mountPoint}";
        Restart = "on-failure";
        RestartSec = "10s";
        RuntimeDirectory = "rclone-torbox";
        RuntimeDirectoryMode = "0750";
        CacheDirectory = "rclone/torbox";
        # Note: do NOT enable mount-namespace directives (PrivateTmp,
        # ProtectSystem, ProtectKernelTunables, etc.) here — rclone mount must
        # publish /mnt/torbox into the host mount namespace.
        LockPersonality = true;
      };
    };
  };
}
