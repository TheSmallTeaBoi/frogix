{config, intputs, outputs, pkgs, ...}:
{
  services.picom = {
    enable = true;
    backend = "glx";
    fade = true;
    fadeSteps = [0.1 0.1];
    vSync = true;
    shadow = false;
    settings = {
      # corners
      corner-radius = 16;
      rounded-corners-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
      ];
    };
  };
}
