{...}: {
  services.picom = {
    enable = true;
    backend = "glx";
    fadeSteps = [0.1 0.1];
    vSync = true;
    shadow = false;
    settings = {
      # corners
      corner-radius = 0;
      rounded-corners-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
      ];
    };
  };
}
