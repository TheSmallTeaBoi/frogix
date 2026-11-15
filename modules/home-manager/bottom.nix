{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.bottom;
in
{
  options.frogix."bottom".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "bottom system monitor with gpu + fast refresh";
  };

  config = lib.mkIf cfg.enable {
    programs.bottom = {
      enable = true;
      settings = {
        flags = {
          enable_gpu = true;
          rate = "500ms";
        };
      };
    };
  };
}
