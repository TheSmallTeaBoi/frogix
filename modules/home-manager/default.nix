{ ... }:
{
  imports = [
    # ./plover.nix
    ./aichat.nix
    ./beets.nix
    ./bottom.nix
    ./desktop.nix
    ./firefox.nix
    ./git.nix
    ./gtk.nix
    ./home.nix
    ./hyprland.nix
    ./iamb.nix
    ./kitty.nix
    ./lazygit.nix
    ./mako.nix
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
