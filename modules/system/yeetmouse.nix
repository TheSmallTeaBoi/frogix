{ pkgs, ... }:
let
  accel = 0.4;
  accelModeNum = 1;
  preScale = 0.5;
  sens = 0.5;
  midpoint = 6.0;
  offset = 5.0;
  outputCap = 0.0;
  inputCap = 0.0;
  snapAngle = 0.0;
  snapThreshold = 0.0; # This takes radians.

  echo = "${pkgs.coreutils}/bin/echo";
  yeetmouseConfig = pkgs.writeShellScriptBin "yeetmouseConfig" ''
    ${echo} "${toString accel}" > /sys/module/yeetmouse/parameters/Acceleration
    ${echo} "${toString midpoint}" > /sys/module/yeetmouse/parameters/Midpoint
    ${echo} "${toString preScale}" > /sys/module/yeetmouse/parameters/PreScale
    ${echo} "${toString sens}" > /sys/module/yeetmouse/parameters/Sensitivity
    ${echo} "1.0" > /sys/module/yeetmouse/parameters/SensitivityY
    ${echo} "${toString accelModeNum}" > /sys/module/yeetmouse/parameters/AccelerationMode
    ${echo} "${toString offset}" > /sys/module/yeetmouse/parameters/Offset
    ${echo} "${toString outputCap}" > /sys/module/yeetmouse/parameters/OutputCap
    ${echo} "${toString snapAngle}" > /sys/module/yeetmouse/parameters/AngleSnap_Angle
    ${echo} "${toString snapThreshold}" > /sys/module/yeetmouse/parameters/AngleSnap_Threshold
    ${echo} "1" > /sys/module/yeetmouse/parameters/update
  '';
in
{
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
  #   ACTION=="add|bind|change", SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="03", ATTRS{bInterfaceSubClass}=="01", ATTRS{bInterfaceProtocol}=="02", RUN+="${yeetmouseConfig}/bin/yeetmouseConfig"
  # '';
  systemd.services.yeetmouse-setup = {
    description = "Rebind USB HID device to leetmouse and configure it";
    wantedBy = [ "multi-user.target" ];
    after = [ "display-manager.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''
        ${yeetmouseConfig}/bin/yeetmouseConfig
      '';
    };
  };
}
