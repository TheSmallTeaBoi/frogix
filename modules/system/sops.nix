{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.sops;
in
{
  options.frogix.sops.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "sops-nix with the frogix secret set (age key at ~/.config/sops/age/keys.txt, generated on demand)";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ./secrets/secrets.yaml;
      age = {
        keyFile = "/home/${config.frogix.user}/.config/sops/age/keys.txt";
        generateKey = true;
      };
      secrets = {
        navidrome_env = {
          owner = config.services.navidrome.user;
        };
        romm_env = {
          owner = config.services.romm.user;
        };
        torbox_webdav_user = {
          owner = "root";
        };
        torbox_webdav_pass = {
          owner = "root";
        };
        # hermes_env / hermes_dashboard_token removed 2026-09-21 together with
        # the hermes stack; encrypted leftovers in secrets.yaml can be pruned
        # by hand with `sops secrets/secrets.yaml` if wanted.
      };
    };
  };
}
