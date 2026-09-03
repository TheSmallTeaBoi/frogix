{ pkgs, ... }:
{
  hardware = {
    yeetmouse = {
      enable = true;
      preScale = 0.5;
      sensitivity = 0.25;
      inputCap = 0.0;
      outputCap = 0.0;
      offset = 0.0;
      mode.jump = {
        acceleration = 3.0;
        midpoint = 3.0;
        smoothness = 1.0;
        useSmoothing = false;
      };
    };
  };

  # services.udev.extraRules = ''
  #   ACTION=="add|bind|change", SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="03", ATTRS{bInterfaceSubClass}=="01", ATTRS{bInterfaceProtocol}=="02", RUN+="${yeetmouseConfig}/bin/yeetmouseConfig"
  # '';
  # systemd.services.yeetmouse-setup = {
  #   description = "Rebind USB HID device to leetmouse and configure it";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "display-manager.service" ];

  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = ''
  #       ${yeetmouseConfig}/bin/yeetmouseConfig
  #     '';
  #   };
  # };
}
