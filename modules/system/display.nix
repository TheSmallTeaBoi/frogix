{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.display;
in
{
  options.frogix.display.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "sddm + the niri session, and the session plumbing its config hard-references";
  };
  options.frogix.display.autoLogin = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "autologin the frogix user on the sddm niri session (off by default)";
  };

  config = lib.mkIf cfg.enable {
    # electron apps should run native wayland
    environment.variables.NIXOS_OZONE_WL = "1";

    programs.niri.enable = true;

    services.displayManager = {
      sddm.enable = true;
      sddm.wayland.enable = true;
      defaultSession = "niri";
      autoLogin = {
        enable = cfg.autoLogin;
        user = config.frogix.user;
      };
    };

    # session plumbing the niri config hard-references — always present with
    # the display stack, independent of frogix.packages:
    #   nemo               Mod+E bind + xdg default for directories
    #   feh                xdg default for images
    #   xwayland-satellite X11 apps under niri
    #   grimblast          screenshots
    environment.systemPackages = with pkgs; [
      nemo
      feh
      xwayland-satellite
      grimblast
    ];

    # Drive mounting in the session's file browser (nemo's sidebar, removable
    # media). gvfs pulls in udisks2 itself; keep it with the display stack so a
    # host that has no sops (and therefore frogix.services off) still gets it.
    services.gvfs = {
      enable = true;
      package = pkgs.gvfs;
    };
  };
}
