{
  inputs,
  pkgs,
  ...
}: {
  services = {
    # This is needed for kmonad
    udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput
    '';

    # Drive mounting
    gvfs = {
      enable = true;
      package = pkgs.gvfs;
    };

    udisks2.enable = true;

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
