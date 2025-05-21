{...}: {
  imports = [
    ./aichat.nix
    ./beets.nix
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
    ./plover.nix
    ./rofi.nix
    ./shell.nix
    ./tmux.nix
    ./zoxide.nix
  ];
  programs.home-manager.enable = true;
}
