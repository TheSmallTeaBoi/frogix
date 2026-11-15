{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.virt;
in
{
  options.frogix.virt.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "virt-manager / libvirtd stack with spice usb redirection";
  };

  config = lib.mkIf cfg.enable {
    programs.virt-manager.enable = true;
    users.extraGroups.libvirtd.members = [ config.frogix.user ];
    virtualisation.libvirtd.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
