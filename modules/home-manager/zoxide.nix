{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.zoxide;
in
{
  options.frogix."zoxide".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "zoxide with cd replacement";
  };

  config = lib.mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
