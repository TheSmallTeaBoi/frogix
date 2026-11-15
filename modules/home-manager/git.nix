{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.git;
in
{
  options.frogix.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "git with frogix defaults";
    };
    email = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "git user.email (null = don't set)";
    };
    name = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "git user.name (null = don't set)";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      settings = {
        user =
          lib.optionalAttrs (cfg.email != null) { email = cfg.email; }
          // lib.optionalAttrs (cfg.name != null) { name = cfg.name; };
        credential.helper = "store"; # Save credentials. This shit is unsafe af.
      };
    };
  };
}
