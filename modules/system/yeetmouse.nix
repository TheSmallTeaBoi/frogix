{pkgs, ...}: let
  accel = 0.7;
  accelMode = "linear";
  accelModeNum = 1;
  preScale = 0.5;
  sens = 0.5;
  midpoint = 6.0;
  useSmoothing = false;
  offset = 5.0;
  outputCap = 0.0;
  inputCap = 0.0;
  exponent = 1.0;
  rotation = 0.0; # This takes radians.
  snapAngle = 0.0;
  snapThreshold = 0.0; # This takes radians.
  # echo = "${pkgs.coreutils}/bin/echo";
  # yeetmouseConfig = pkgs.writeShellScriptBin "yeetmouseConfig" ''
  #   ${echo} "${toString accel}" > /sys/module/leetmouse/parameters/Acceleration
  #   ${echo} "${toString midpoint}" > /sys/module/leetmouse/parameters/Midpoint
  #   ${echo} "${toString preScale}" > /sys/module/leetmouse/parameters/PreScale
  #   ${echo} "${toString sens}" > /sys/module/leetmouse/parameters/Sensitivity
  #   ${echo} "${toString sens}" > /sys/module/leetmouse/parameters/SensitivityY
  #   ${echo} "${toString accelModeNum}" > /sys/module/leetmouse/parameters/AccelerationMode
  #   ${echo} "${toString offset}" > /sys/module/leetmouse/parameters/Offset
  #   ${echo} "${toString outputCap}" > /sys/module/leetmouse/parameters/OutputCap
  #   ${echo} "${toString snapAngle}" > /sys/module/leetmouse/parameters/AngleSnap_Angle
  #   ${echo} "${toString snapThreshold}" > /sys/module/leetmouse/parameters/AngleSnap_Threshold
  #   ${echo} "1" > /sys/module/leetmouse/parameters/update
  # '';
in {
  hardware = {
    yeetmouse = {
      enable = true;
      preScale = preScale;
      sensitivity = sens;
      inputCap = inputCap;
      outputCap = outputCap;
      offset = offset;
      mode.linear = {
        acceleration = accel;
      };
    };
  };

  # services.udev.extraRules = ''
  #   ACTION=="add|bind|change", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c53f", RUN+="/bin/sh -c 'echo -n 1-9:1.1 > /sys/bus/usb/drivers/usbhid/unbind; echo -n 1-9:1.1 > /sys/bus/usb/drivers/leetmouse/bind; ${yeetmouseConfig}/bin/yeetmouseConfig'"
  # '';
  #
  # systemd.services.yeetmouse-setup = {
  #   description = "Rebind USB HID device to leetmouse and configure it";
  #   wantedBy = ["multi-user.target"];
  #   after = ["local-fs.target"];
  #
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = ''
  #       /bin/sh -c 'echo -n 1-9:1.1 > /sys/bus/usb/drivers/usbhid/unbind; \
  #                   echo -n 1-9:1.1 > /sys/bus/usb/drivers/leetmouse/bind; \
  #                   ${yeetmouseConfig}/bin/yeetmouseConfig'
  #     '';
  #   };
  # };
}
