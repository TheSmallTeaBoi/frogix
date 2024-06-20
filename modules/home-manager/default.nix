{
  inputs,
  outputs,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./awesome.nix
    ./firefox.nix
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
    ./xinit.nix
    ./zellij.nix
    ./zoxide.nix
  ];
  programs.home-manager.enable = true;
}
