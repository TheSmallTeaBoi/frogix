# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = ["noatime"];
  };

  fileSystems."/efi" = {
    device = "systemd-1";
    fsType = "autofs";
  };

  fileSystems."/home/theo/Rattus" = {
    device = "/dev/disk/by-uuid/e0fa5f82-c2b8-417d-a4dd-9ff45ee93fb4";
    fsType = "ext4";
    options = ["nofail"];
  };

  fileSystems."/home/theo/Data" = {
    device = "/dev/disk/by-uuid/65e258da-2f64-4fa5-a170-afc2de0ff11c";
    fsType = "btrfs";
    options = ["compress-force=zstd:10" "noatime" "nofail"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # This shit doesn't work anymore, seems lexar SSDs don't have the greatest QC
  # fileSystems."/home/theo/SSD" = {
  #   device = "/dev/disk/by-uuid/47686783-7cf2-40e3-98cc-72e17b420217";
  #   fsType = "ext4";
  #   options = ["discard" "nofail"];
  # };

  swapDevices = [];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
