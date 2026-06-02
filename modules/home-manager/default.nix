{ inputs, ... }:
{
  imports = [
    inputs.niri-nix.homeModules.default
    inputs.niri-nix.homeModules.stylix

    # ./plover.nix
    ./aichat.nix
    ./beets.nix
    ./bottom.nix
    ./desktop.nix
    ./easyeffects.nix
    ./emacs.nix
    ./firefox.nix
    ./git.nix
    ./gtk.nix
    ./home.nix
    # ./hyprland.nix
    ./iamb.nix
    ./kitty.nix
    ./lazygit.nix
    ./mako.nix
    ./niri.nix
    ./obsidian.nix
    ./rofi.nix
    ./shell.nix
    ./theme.nix
    ./tmux.nix
    ./vesktop.nix
    ./xdg.nix
    ./zoxide.nix
  ];
  programs.home-manager.enable = true;
}
