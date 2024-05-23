{
  inputs,
  outputs,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./awesome.nix
    ./git.nix
    ./gtk.nix
    ./home.nix
    ./iamb.nix
    ./kitty.nix
    ./lazygit.nix
    ./picom.nix
    ./polybar.nix
    ./rofi.nix
    ./shell.nix
    ./sxhkd.nix
    ./tmux.nix
    ./zellij.nix
    ./xinit.nix
  ];
  programs.home-manager.enable = true;
}
