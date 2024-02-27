{inputs, outputs, pkgs, config, ...}:
{
  imports = [
    ./gtk.nix
    ./home.nix
  ];
  programs.home-manager.enable = true;

}
