{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.frogix.gaming;
in
{
  options.frogix.gaming.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "gamemode, gpu-screen-recorder and the game package rack";
  };

  config = lib.mkIf cfg.enable {
    programs.gpu-screen-recorder.enable = true;
    programs.gamemode.enable = true;

    environment.systemPackages = with pkgs; [
      heroic-unwrapped

      inputs.lsfg-vk-nix.packages.${pkgs.stdenv.hostPlatform.system}.lsfg-vk
      inputs.lsfg-vk-nix.packages.${pkgs.stdenv.hostPlatform.system}.lsfg-vk-ui
      steamtinkerlaunch
      gpu-screen-recorder-gtk

      (prismlauncher.override {
        jdks = with pkgs; [
          jdk21
        ];
      })

      beammp-launcher

      # Emulation {
      # retroarch-full
      pcsx2
      # torzu # I will not forget you.
      # }

      (tic-80.override { withPro = true; }) # :3

      logmein-hamachi # my beloved
      parsec-bin # actual black magic.
      protontricks
      mangohud
    ];
  };
}
