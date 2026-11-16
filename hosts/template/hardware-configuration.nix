# PLACEHOLDER hardware so `.#template` evaluates and you can smoke-test it with
# `nixos-rebuild build-vm --flake .#template`. replace this whole file with the
# output of `nixos-generate-config --show-hardware-config` when creating a real
# host from this template.
{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
