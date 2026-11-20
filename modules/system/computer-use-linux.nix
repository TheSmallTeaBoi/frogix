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
#     and computer-use's apps/state tools stay empty for them;
#   - a gnome-screenshot shim backed by grim. computer-use's last-resort
#     screenshot fallback execs `gnome-screenshot -f FILE` and expects a
#     full-desktop PNG. niri's org.gnome.Shell.Screenshot D-Bus API refuses
#     multi-monitor layouts ("Condition failed: outputs.len() == 1", still an
#     upstream FIXME as of 2026-11), which kills the plugin's GNOME Shell and
#     xdg-desktop-portal-gnome routes — and the portal route also drags in a
#     consent dialog that has no reason to exist for our own agent. grim talks
#     to niri's wlr-screencopy support directly, stitches every output
#     side-by-side, and never prompts. Remove this shim if the plugin grows a
#     native niri capture or niri fixes multi-output portal screenshots.

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix."computer-use-linux";

  # see the header comment: computer-use-linux's screenshot fallback chain
  # ends in `gnome-screenshot -f FILE`; give it a grim-backed one that works
  # on niri multi-monitor without any portal consent.
  # gsettings-desktop-schemas installs to share/gsettings-schemas/<ver>/glib-2.0/schemas
  # — no stable path any environment variable can point at across nixpkgs
  # bumps. flatten it so GSETTINGS_SCHEMA_DIR can. GSETTINGS_SCHEMA_DIR is
  # additive to GLib's XDG_DATA_DIRS scan, so this never hides other schemas.
  gsettings-schemas-flat = pkgs.runCommand "frogix-gsettings-schemas" { } ''
    mkdir -p $out/glib-2.0/schemas
    for d in ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/*/glib-2.0/schemas; do
      cp -r "$d"/. $out/glib-2.0/schemas/
    done
  '';

  gnome-screenshot-shim = pkgs.writeShellApplication {
    name = "gnome-screenshot";
    runtimeInputs = [ pkgs.grim ];
    text = ''
      file=""
      prev=""
      for arg in "$@"; do
        if [ "$prev" = "-f" ] || [ "$prev" = "--file" ]; then
          file="$arg"
        fi
        case "$arg" in
          -f | --file) prev="$arg" ;;
          *) prev="" ;;
        esac
      done
      if [ -z "$file" ]; then
        echo "gnome-screenshot shim: only '-f FILE' is supported (grim, all outputs)" >&2
        exit 2
      fi
      grim "$file"
    '';
  };
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

    # glib provides the gsettings binary; GSETTINGS_SCHEMA_DIR makes it (and
    # every libgsettings consumer, like at-spi-bus-launcher at login) find the
    # GNOME schemas, so the toolkit-accessibility key computer-use persists
    # actually survives reboots instead of living only in the runtime fallback.
    environment.systemPackages = [
      pkgs.glib
      gnome-screenshot-shim
    ];
    environment.sessionVariables.GSETTINGS_SCHEMA_DIR = "${gsettings-schemas-flat}/glib-2.0/schemas";

    # the RemoteDesktop portal prompts once per computer-use process; this
    # asks it to hand out a restore token (GNOME-family portals, incl. niri's
    # xdg-desktop-portal-gnome backend, pre-check the remember box) so later
    # processes reuse a mode-0600 token in the user state dir instead of
    # re-prompting. pointer/keyboard input itself goes through uinput/wtype
    # and never touches the portal, so this only matters for portal-input
    # fallback paths.
    environment.sessionVariables.COMPUTER_USE_LINUX_PERSIST_REMOTE_DESKTOP = "1";
  };
}
