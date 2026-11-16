{ inputs, ... }:
{
  imports = [
    ./frogix.nix
    inputs.niri-nix.homeModules.default
    inputs.hermes-agent.homeManagerModules.default

    # ./plover.nix
    ./audio.nix
    ./beets.nix
    ./bottom.nix
    ./desktop.nix
    ./emacs.nix
    ./qutebrowser.nix
    ./git.nix
    ./gtk.nix
    ./hermes.nix
    ./home.nix
    # ./hyprland.nix
    ./iamb.nix
    ./kitty.nix
    ./mako.nix
    ./niri.nix
    ./rofi.nix
    ./shell.nix
    ./pywal.nix
    ./sunshine.nix
    ./qute-adblock
    ./tmux.nix
    ./vesktop.nix
    ./vitrina.nix
    ./xdg.nix
  ];
  programs.home-manager.enable = true;
}
