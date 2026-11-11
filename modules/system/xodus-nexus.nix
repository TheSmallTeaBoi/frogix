# Xodus Nexus — runs Microsoft Store / PC Game Pass games on Linux.
# https://github.com/domsvoboda/xodus-nexus
#
# Upstream ships no flake and is not in nixpkgs: the only distributable is an
# x86_64 AppImage attached to each GitHub release. This module pins that
# AppImage and wraps it with appimageTools, which extracts it into the store and
# runs its AppRun inside an FHS env carrying the libraries an AppImage expects
# (gtk3, libsecret, the steam chroot library list, ...). That is wrapped again
# into a plain xodus-nexus launcher so one set of flags applies no matter how
# the app is started.
#
# To bump: set xodusNexusVersion to the new tag, then
#   nix store prefetch-file --json --hash-type sha256 \
#     "https://github.com/domsvoboda/xodus-nexus/releases/download/v$VER/Xodus-Nexus-$VER-x86_64.AppImage"
# and paste the reported hash into xodusNexusSrc.
{
  pkgs,
  lib,
  ...
}:
let
  xodusNexusVersion = "0.3.9";

  xodusNexusSrc = pkgs.fetchurl {
    url = "https://github.com/domsvoboda/xodus-nexus/releases/download/v${xodusNexusVersion}/Xodus-Nexus-${xodusNexusVersion}-x86_64.AppImage";
    hash = "sha256-9nUbObj2uyngHCZIO7duntBUb5Gkie5/MIe4uHI8W0U=";
  };

  xodusNexusAppDir = pkgs.appimageTools.extract {
    pname = "xodus-nexus";
    version = xodusNexusVersion;
    src = xodusNexusSrc;
  };

  xodusNexusUnwrapped = pkgs.appimageTools.wrapAppImage {
    name = "xodus-nexus";
    contents = xodusNexusAppDir;
  };

  # Electron's chrome-sandbox wants a SUID helper (impossible out of the nix
  # store) or unprivileged user namespaces. Upstream launches itself this way
  # too — its own .desktop is `Exec=AppRun --no-sandbox %U`. Empty this list if
  # you enable unprivileged user namespaces instead, e.g.
  #   security.unprivilegedUsernsClone = true;
  xodusNexusFlags = [ "--no-sandbox" ];

  xodus-nexus = pkgs.writeShellScriptBin "xodus-nexus" ''
    exec ${lib.getExe' xodusNexusUnwrapped "xodus-nexus"} ${lib.escapeShellArgs xodusNexusFlags} "$@"
  '';

  xodusNexusDesktop = pkgs.makeDesktopItem {
    name = "xodus-nexus";
    desktopName = "Xodus Nexus";
    comment = "Xbox-inspired Microsoft Store game launcher for Linux";
    exec = "xodus-nexus %U";
    icon = "${xodusNexusAppDir}/xodus-nexus.png";
    categories = [ "Game" ];
    startupWMClass = "Xodus Nexus";
    terminal = false;
  };
in
{
  environment.systemPackages = [
    xodus-nexus
    xodusNexusDesktop
  ];
}
