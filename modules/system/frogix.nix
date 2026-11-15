{ lib, ... }:
{
  options.frogix = {
    enable = lib.mkEnableOption "the frogix module suite";

    user = lib.mkOption {
      type = lib.types.str;
      description = "the primary user the frogix modules configure (no default: set it in your host)";
    };
  };
}
