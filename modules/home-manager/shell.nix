{
  config,
  pkgs,
  home-manager,
  ...
}: {
  home.sessionVariables = {
    fish_tmux_config = "~/.config/tmux/tmux.config";
  };
  programs.fish = {
    enable = true;
    functions = {
      fish_greeting = "";
      fish_prompt = "set_color red; echo $IN_NIX_SHELL '> '";
    };
    shellAliases = {
      ls = "eza --icons";
      la = "eza -a --icons";
      ll = "eza -i --icons";
      tree = "eza --tree --icons";
      nixb = "sudo nixos-rebuild switch --flake ~/frogix/";
      nsearch = "nix search nixpkgs";
      dev = "nix develop --command fish"; # This shit sucks
      det = "tmux detach";
    };
    plugins = [
      {
        name = "tmux.fish";
        src = pkgs.fetchFromGitHub {
          owner = "budimanjojo";
          repo = "tmux.fish";
          rev = "e95dbc11fa57d738cd837cb659d50b73ec0a8d90";
          sha256 = "sha256-tNq/F9NQZZ1pd0ZWPzQVwuHABCVECmXRN12ovGSUUFU=";
        };
      }
    ];
  };
}
