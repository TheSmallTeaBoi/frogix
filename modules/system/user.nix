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
      description = "define the frogix.user account (password is set with passwd)";
    };
    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "wheel"
        "input"
        "uinput"
        "audio"
        "gamemode"
        "bluetooth"
      ];
      description = ''
        groups the primary user is a member of. the groups must exist —
        disabling a module that owns one (e.g. gaming and "gamemode") means
        removing it here too
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${config.frogix.user} = {
      isNormalUser = true;
      extraGroups = cfg.extraGroups;
    };
  };
}
