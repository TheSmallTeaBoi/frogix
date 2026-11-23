# Vial — real-time QMK/Vial keyboard configurator (https://get.vial.today).
#
# nixpkgs ships Vial as an AppImage wrapped by appimageTools, but that FHS env
# is missing libgpg-error.so.0. The AppImage's bundled libgcrypt links it and
# Qt's xcb platform plugin dlopens that chain, so without it every launch dies
# with:
#   could not find or load the Qt platform plugin "xcb"
# nixpkgs' wrapType2 exposes no extraPkgs hook, so the wrapper is rebuilt here
# with libgpg-error in the env (same pattern as modules/system/xodus-nexus.nix).
#
# The GUI and its hidraw udev rule are deliberately one switch: Vial that can't
# open /dev/hidraw* as a normal user is a broken install, and the rule alone
# does nothing without the GUI.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.frogix.vial;

  appDir = pkgs.appimageTools.extract {
    pname = "Vial";
    inherit (pkgs.vial) version src;
  };

  vialUnwrapped = pkgs.appimageTools.wrapAppImage {
    name = "Vial";
    contents = appDir;
    extraPkgs = p: [ p.libgpg-error ];
  };

  # re-add the desktop entry + icons wrapType2 would have installed for us
  vial = pkgs.symlinkJoin {
    name = "vial";
    paths = [ vialUnwrapped ];
    postBuild = ''
      install -m 444 -D ${appDir}/Vial.desktop $out/share/applications/Vial.desktop
      cp -r ${appDir}/usr/share/icons $out/share/
    '';
  };
in
{
  options.frogix.vial = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "Vial keyboard configurator (GUI plus the hidraw rule that lets it reach the keyboard)";
    };

    serial = lib.mkOption {
      type = lib.types.str;
      default = "vial:f64c2b3c";
      description = ''
        serial fragment matched by the Vial udev rule. The default is the magic
        serial stock Vial firmware advertises; override it only for a build that
        sets its own VIAL_SERIAL. Check yours with `udevadm info /dev/hidraw*`
        or `lsusb -v`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ vial ];

    services.udev.extraRules = ''
      # This is needed for Vial and plover
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*${cfg.serial}*", MODE="0660", TAG+="uaccess"
    '';
  };
}
