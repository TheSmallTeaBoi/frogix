# AT-SPI readiness for @agent-sh/computer-use-linux. the computer-use binary
# itself is NOT installed system-wide: it ships inside the pi package
# npm:@agent-sh/computer-use-linux (frogix.pi.settings.packages), which
# downloads it when pi starts. what a downloaded binary cannot bring with it
# is the session's accessibility plumbing, so that is what this module owns:
#
#   - org.a11y.Bus becomes dbus-activatable (services.gnome.at-spi2-core), so
#     clients can walk app accessibility trees;
#   - the bridge-disabling variables the at-spi2-core module sets while off
#     are cleared, and GTK/Qt are told to export trees (GTK_ACCESSIBILITY=1,
#     QT_ACCESSIBILITY=1). these are PAM session variables — a host must
#     re-login after enabling: already-running apps keep the old environment
#     and computer-use's apps/state tools stay empty for them.

{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix."computer-use-linux";
in
{
  options.frogix."computer-use-linux" = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = ''
        accessibility plumbing (AT-SPI bus, GTK/Qt bridge env) that
        @agent-sh/computer-use-linux needs to read this desktop. the binary
        itself is not installed here: it ships inside the pi package
        npm:@agent-sh/computer-use-linux (see frogix.pi.settings.packages),
        which downloads it when pi starts. disabling this makes computer-use's
        apps/state tools come back empty; changes take effect for new login
        sessions only (the variables are PAM session variables)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # system-wide assistive technology bus: org.a11y.Bus launches
    # at-spi-bus-launcher on demand so clients can read accessibility trees.
    services.gnome.at-spi2-core.enable = true;

    # at-spi2-core sets GTK_A11Y = "none" and NO_AT_BRIDGE = "1" while it is
    # off; clear them so turning the bus on actually lets toolkits bridge.
    # GTK loads atk-bridge when GTK_ACCESSIBILITY is set; Qt needs
    # QT_ACCESSIBILITY = 1. the sddm -> niri session picks these up via PAM.
    environment.sessionVariables = {
      NO_AT_BRIDGE = null;
      GTK_A11Y = null;
      GTK_ACCESSIBILITY = "1";
      QT_ACCESSIBILITY = "1";
    };
  };
}
