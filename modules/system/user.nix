{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.users;
in
{
  options.frogix.users = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "define the frogix.user account (password is set with passwd unless hashedPasswordSecret / hashedPasswordFile is configured)";
    };
    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "wheel"
        "input"
        "uinput"
        "audio"
        "bluetooth"
      ]
      ++ lib.optional config.frogix.gaming.enable "gamemode";
      defaultText = lib.literalExpression ''[ "wheel" "input" "uinput" "audio" "bluetooth" ] ++ lib.optional config.frogix.gaming.enable "gamemode"'';
      description = ''
        groups the primary user is a member of ("gamemode" is added
        automatically when frogix.gaming is enabled)
      '';
    };
    hashedPasswordSecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        name of a sops-nix secret holding the salted password hash for
        frogix.user (generate with `mkpasswd -m yescrypt`). declared with
        neededForUsers = true and wired into users.users.<user>.hashedPasswordFile
        so /etc/shadow is populated declaratively on every boot (required when
        running an ephemeral/tmpfs root). requires frogix.sops; exclusive with
        hashedPasswordFile
      '';
    };
    hashedPasswordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        path to a file containing the salted password hash for frogix.user
        (alternative to hashedPasswordSecret for hosts not storing the hash in
        sops). exclusive with hashedPasswordSecret
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.hashedPasswordSecret == null || cfg.hashedPasswordFile == null;
        message = "frogix.users: hashedPasswordSecret and hashedPasswordFile are mutually exclusive — set only one.";
      }
      {
        assertion = cfg.hashedPasswordSecret == null || config.frogix.sops.enable;
        message = "frogix.users: hashedPasswordSecret reads from sops-nix, so frogix.sops has to be on.";
      }
    ];

    sops.secrets = lib.mkIf (config.frogix.sops.enable && cfg.hashedPasswordSecret != null) {
      ${cfg.hashedPasswordSecret}.neededForUsers = true;
    };

    users.users.${config.frogix.user} = {
      isNormalUser = true;
      extraGroups = cfg.extraGroups;
    }
    // lib.optionalAttrs (cfg.hashedPasswordSecret != null && config.frogix.sops.enable) {
      hashedPasswordFile = config.sops.secrets.${cfg.hashedPasswordSecret}.path;
    }
    // lib.optionalAttrs (cfg.hashedPasswordFile != null) {
      hashedPasswordFile = cfg.hashedPasswordFile;
    };
  };
}
