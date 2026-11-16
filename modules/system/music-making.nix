{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.musicMaking;
in
{
  options.frogix.musicMaking.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "musnix realtime audio tweaks + the plugin rack (LV2/LADSPA/VST)";
  };

  config = lib.mkIf cfg.enable {
    musnix.enable = true;

    environment.systemPackages = with pkgs; [
      # the plugin rack
      AMB-plugins
      aether-lv2
      airwindows
      autotalent
      bchoppr
      calf
      caps
      carla
      chow-centaur
      chow-kick
      chow-phaser
      chow-tape-model
      cmt
      dexed
      distrho-ports
      dragonfly-reverb
      drumkv1
      geonkick
      guitarix
      helm
      infamousPlugins
      lsp-plugins
      mod-distortion
      ninjas2
      noise-repellent
      oxefmsynth
      quadrafuzz
      rubberband
      samplv1
      sfizz
      sorcer
      synthv1
      tap-plugins
      vital
      wolf-shaper
      x42-plugins
      zam-plugins
      zita-at1
      zynaddsubfx
    ];
  };
}
