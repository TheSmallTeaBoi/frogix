{ config, lib, ... }:
{
  options.frogix = {
    enable = lib.mkEnableOption "frogix home-manager modules";

    user = lib.mkOption {
      type = lib.types.str;
      description = "the primary user (inherited from the NixOS side by default)";
    };

    wallpapersDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Pictures/Wallpapers";
      description = "directory wallpapers are shuffled from";
    };

    screens = lib.mkOption {
      type = lib.types.submodule {
        options = {
          main = lib.mkOption {
            type = lib.types.str;
            description = "the main monitor — mandatory; niri/pywal/vitrina reference it directly";
          };
          left = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          right = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          outputs = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
            description = "niri monitor rules (mode, scale, position, transform, per-screen layout) — host hardware layout";
          };
        };
      };
      description = "monitor names as niri/wlpicker see them";
    };
  };
}
