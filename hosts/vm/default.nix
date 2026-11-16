{ config, lib, ... }:
# minimal frogix VM: console-only, universal defaults, opt-outs instead of opt-ins.
# build with: nixos-rebuild build-vm --flake .#vm
# run with:   ./result/bin/run-vm  (add -nographic for a headless serial console)
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "26.11";

  networking.hostName = "frogix-vm";

  frogix = {
    enable = true;
    user = "demo";

    # system: core + networking + shell only
    boot.enable = true;
    nix.enable = true;
    networkd.enable = true;
    users.enable = true;
    shell.enable = true;
    core.enable = true;

    services.enable = false;
    packages.enable = false;
    nvidia.enable = false;
    display.enable = false;
    input.enable = false;
    steam.enable = false;
    wine.enable = false;
    gaming.enable = false;
    musicMaking.enable = false;
    romm.enable = false;
    sops.enable = false;
    torbox.enable = false;
    "torbox-music-sync".enable = false;
    "xodus-nexus".enable = false;
    "emeet-linux".enable = false;

    # no gamemode in the VM, so drop it from the default groups
    users.extraGroups = [
      "wheel"
      "input"
      "audio"
    ];
  };

  users.users.${config.frogix.user}.initialPassword = "demo";
  users.users.root.initialPassword = "toor";

  home-manager.users.demo = {
    frogix.home.stateVersion = "26.11";
    frogix.screens.main = "none"; # mandatory option; unused since desktop HM modules are off

    frogix.niri.enable = false;
    frogix.pywal.enable = false;
    frogix.vitrina.enable = false;
    frogix.sunshine.enable = false;
    frogix.audio.enable = false;
    frogix.emacs.enable = false;
    frogix.qutebrowser.enable = false;
    frogix.hermes.enable = false;
    frogix.iamb.enable = false;
    frogix.mako.enable = false;
    frogix.rofi.enable = false;
    frogix.vesktop.enable = false;
    frogix.beets.enable = false;
    frogix.desktop.enable = false;
    frogix.gtk.enable = false;
  };
}
