{pkgs, ...}: {
  services = {
    # This is needed for kmonad and Vial
    udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      # There's something odd with yeetmouse, my g305 only works with it if I do
      # this
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c53f", RUN+="/bin/sh -c 'echo -n 1-9:1.1 > /sys/bus/usb/drivers/usbhid/unbind; echo -n 1-9:1.1 > /sys/bus/usb/drivers/leetmouse/bind'"

    '';

    # Drive mounting
    gvfs = {
      enable = true;
      package = pkgs.gvfs;
    };

    udisks2.enable = true;

    dbus = {
      enable = true;
      implementation = "broker";
    };

    # Enable sound.
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # Enable the OpenSSH daemon.
    openssh.enable = true;

    # Syncthing
    syncthing = {
      enable = true;
      user = "theo";
      dataDir = "/home/theo/Documents";
      configDir = "/home/theo/.config/syncthing";
      overrideDevices = true; # overrides any devices added or deleted through the WebUI
      overrideFolders = true; # overrides any folders added or deleted through the WebUI
      settings = {
        devices = {
          "Phone" = {id = "WCFUTSH-VU6QZOM-SJEHLLF-OFRDX3T-PWPHBX6-XNRV3VZ-AQZWC6X-36A5OAV";};
        };
        folders = {
          "Obsidian" = {
            path = "/home/theo/Data/Personal/obsidian";
            devices = ["Phone"];
            ignorePerms = false; # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          };
        };
      };
    };
  };
}
