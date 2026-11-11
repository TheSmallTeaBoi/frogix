{
  pkgs,
  lib,
  config,
  ...
}:
let
  mountPoint = "/mnt/torbox";
  confDir = "/run/rclone-torbox";
  confFile = "${confDir}/rclone.conf";
  userSecret = config.sops.secrets.torbox_webdav_user.path;
  passSecret = config.sops.secrets.torbox_webdav_pass.path;

  # Build the rclone.conf at runtime from the two plaintext sops secrets.
  # rclone config create obscures the password automatically.
  genConf = pkgs.writeShellScript "torbox-rclone-conf" ''
    set -euo pipefail
    mkdir -p ${confDir}
    chmod 700 ${confDir}
    u=$(cat ${userSecret})
    p=$(cat ${passSecret})
    rm -f ${confFile}
    ${pkgs.rclone}/bin/rclone config create --config ${confFile} torbox webdav \
      url https://webdav.torbox.app vendor other user "$u" pass "$p"
    chown root:users ${confFile}
    chmod 640 ${confFile}
  '';
in
{
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
        "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
        genConf
      ];
      ExecStart =
        "${pkgs.rclone}/bin/rclone mount torbox: ${mountPoint}"
        + " --config ${confFile}"
        + " --vfs-cache-mode full"
        + " --dir-cache-time 15m"
        + " --cache-dir /var/cache/rclone/torbox"
        + " --allow-other"
        + " --umask 022"
        + " --file-perms 0644"
        + " --dir-perms 0755";
      ExecStopPost = "-/run/wrappers/bin/fusermount3 -uz ${mountPoint}";
      Restart = "on-failure";
      RestartSec = "10s";
      RuntimeDirectory = "rclone-torbox";
      CacheDirectory = "rclone/torbox";
    };
  };
}
