{
  config,
  pkgs,
  home-manager,
  ...
}: {
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
    };
  };
}
