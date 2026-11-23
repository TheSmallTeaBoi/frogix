{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.steam;
in
{
  options.frogix.steam.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "steam, steam hardware, gamescope session and the steam chroot libs";
  };

  config = lib.mkIf cfg.enable {
    hardware.steam-hardware.enable = true;
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
        gamescopeSession.enable = true;
        extest.enable = true;
      };
    };
    # overlay rather than programs.steam.package so every consumer of pkgs.steam
    # (including sunshine's launch-gamescope and steam-run) shares one FHS env
    nixpkgs = {
      config.allowUnfree = true;
      overlays = [
        (_final: prev: {
          steam = prev.steam.override {
            extraPkgs =
              p: with p; [
                libXcursor
                libXi
                libXinerama
                libXScrnSaver
                libpng
                libpulseaudio
                libvorbis
                stdenv.cc.cc.lib
                libkrb5
                keyutils
              ];
          };
        })
      ];
    };
  };
}
