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
        "bluetooth"
      ]
      ++ lib.optional config.frogix.gaming.enable "gamemode";
      defaultText = lib.literalExpression ''[ "wheel" "input" "uinput" "audio" "bluetooth" ] ++ lib.optional config.frogix.gaming.enable "gamemode"'';
      description = ''
        groups the primary user is a member of ("gamemode" is added
        automatically when frogix.gaming is enabled)
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
