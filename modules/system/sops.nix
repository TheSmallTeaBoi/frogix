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
      secrets =
        lib.optionalAttrs config.frogix.services.enable {
          navidrome_env = {
            owner = config.services.navidrome.user;
          };
        }
        // lib.optionalAttrs config.frogix.romm.enable {
          romm_env = {
            owner = config.services.romm.user;
          };
        }
        // lib.optionalAttrs config.frogix.torbox.enable {
          torbox_webdav_user = {
            owner = "root";
          };
          torbox_webdav_pass = {
            owner = "root";
          };
        };
    };
  };
}
