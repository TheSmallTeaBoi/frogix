{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.input;
in
{
  options.frogix.input.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "libinput defaults: flat mouse accel, no middle emulation";
  };

  config = lib.mkIf cfg.enable {
    services.libinput = {
      enable = true;

      # all my homies love mouse acceleration
      # but the libinput one is useless, doesn't get recognized by
      # games that use raw input, which KINDA makes sense but isn't what
      # a gamer wants.
      mouse = {
        accelProfile = "flat";
        middleEmulation = false;
      };
    };
  };
}
