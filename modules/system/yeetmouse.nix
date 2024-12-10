{pkgs, ...}: let
  accel = 0.2;
  accelMode = "linear";
  accelModeNum = 1;
  preScale = 0.5;
  sens = 0.5;
  midpoint = 6.0;
  useSmoothing = false;
  offset = 3.0;
  outputCap = 0.0;
  inputCap = 0.0;
  exponent = 1.0;
  rotation = 0.0; # This takes radians.
in {
  hardware = {
    yeetmouse = {
      enable = true;
      parameters = {
        AccelerationMode = accelMode;
        PreScale = preScale;
        Sensitivity = sens;
        Midpoint = midpoint;
        UseSmoothing = useSmoothing;
        ScrollsPerTick = 1;
        InputCap = inputCap;
        OutputCap = outputCap;
        Exponent = exponent;
        RotationAngle = rotation;
      };
    };
  };

  services.udev.extraRules = let
    # Yeetmouse will only work with my g305 if I do this; I know it's ugly.
    echo = "${pkgs.coreutils}/bin/echo";
    yeetmouseConfig = pkgs.writeShellScriptBin "yeetmouseConfig" ''
      ${echo} "${toString accel}" > /sys/module/leetmouse/parameters/Acceleration
      ${echo} "${toString midpoint}" > /sys/module/leetmouse/parameters/Midpoint
      ${echo} "${toString preScale}" > /sys/module/leetmouse/parameters/PreScale
      ${echo} "${toString sens}" > /sys/module/leetmouse/parameters/Sensitivity
      ${echo} "${toString accelModeNum}" > /sys/module/leetmouse/parameters/AccelerationMode
      ${echo} "${toString offset}" > /sys/module/leetmouse/parameters/Offset
      ${echo} "${toString outputCap}" > /sys/module/leetmouse/parameters/OutputCap
      ${echo} "1" > /sys/module/leetmouse/parameters/update
    '';
  in ''
    ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c53f", RUN+="/bin/sh -c 'echo -n 1-9:1.1 > /sys/bus/usb/drivers/usbhid/unbind; echo -n 1-9:1.1 > /sys/bus/usb/drivers/leetmouse/bind; ${yeetmouseConfig}/bin/yeetmouseConfig'"
  '';
}
