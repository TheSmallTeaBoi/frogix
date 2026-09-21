{ pkgs, ... }:
{
  hardware = {
    yeetmouse = {
      enable = true;
      preScale = 1.0;
      sensitivity = 1.0;
      inputCap = 0.0;
      outputCap = 0.0;
      offset = 0.0;
      mode.jump = {
        acceleration = 1.0;
        midpoint = 3.0;
        smoothness = 1.0;
        useSmoothing = false;
      };
    };
  };
}
