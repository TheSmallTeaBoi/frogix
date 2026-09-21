{ inputs, ... }:
{
  imports = [
    inputs.niri-nix.homeModules.default
    inputs.hermes-agent.homeManagerModules.default

    # ./plover.nix
    ./beets.nix
    ./bottom.nix
    ./desktop.nix
    ./easyeffects.nix
    ./emacs.nix
    ./browser.nix
    ./git.nix
    ./gtk.nix
    ./hermes.nix
    ./home.nix
    # ./hyprland.nix
    ./iamb.nix
    ./kitty.nix
    ./lazygit.nix
    ./mako.nix
    ./niri.nix
    ./rofi.nix
    ./shell.nix
    ./pywal.nix
    ./qute-adblock
    ./tmux.nix
    ./vesktop.nix
    ./xdg.nix
    ./zoxide.nix
  ];
  programs.home-manager.enable = true;
}
