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

    # Hide mouse if you don't move it for a while
    unclutter.enable = true;

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
  };
}
