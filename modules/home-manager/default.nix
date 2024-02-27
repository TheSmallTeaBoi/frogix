{inputs, outputs, pkgs, config, ...}:
{
  imports = [
    ./gtk.nix
    ./shell.nix
    ./home.nix
    ./awesome.nix
    ./sxhkd.nix
    ./kitty.nix
    ./git.nix
    ./xinit.nix
    ./rofi.nix
    ./picom.nix
  ];
  programs.home-manager.enable = true;

}
