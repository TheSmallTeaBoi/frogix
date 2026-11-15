{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.lazygit;
in
{
  options.frogix."lazygit".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "lazygit";
  };

  config = lib.mkIf cfg.enable {
    programs.lazygit = {
      enable = true;
    };
  };
}
