{inputs, outputs, pkgs, config, ...}:
{
  imports = [
    ./gtk.nix
    ./home.nix
    ./awesome.nix
  ];
  programs.home-manager.enable = true;

}
