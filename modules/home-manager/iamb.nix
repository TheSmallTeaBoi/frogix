{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.iamb;
in
{
  options.frogix."iamb".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "iamb matrix client config";
  };

  options.frogix.iamb.matrixId = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "matrix account iamb logs into (null = no profile block)";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."iamb/config.toml".text =
      # toml
      ''
        ${lib.optionalString (cfg.matrixId != null) ''
          [profiles.user]
          user_id = "${cfg.matrixId}"
        ''}

        [settings.notifications]
        enabled = true
        via = "bell"

        [settings]
        username_display = "displayname"

        [dirs]
        downloads = '${config.home.homeDirectory}/Unorganized/iamb/'
      '';
  };
}
