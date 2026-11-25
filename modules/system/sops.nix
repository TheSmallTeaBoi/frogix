{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.sops;
in
{
  options.frogix.sops = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "sops-nix with the frogix secret set (age key generated on demand)";
    };
    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.frogix.user}/.config/sops/age/keys.txt";
      description = ''
        path to the age private key used by sops-nix during early activation.
        frogix.impermanence redirects this automatically under persistPath so
        decryption runs before user bind mounts exist
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ./secrets/secrets.yaml;
      age = {
        keyFile = cfg.ageKeyFile;
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
