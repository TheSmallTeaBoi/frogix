{
  config,
  pkgs,
  ...
}: {
  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;
  environment.systemPackages = with pkgs; [
    fishPlugins.fzf-fish
  ];
  environment.shellAliases = {
    ls = "eza --icons";
    la = "eza -a --icons";
    ll = "eza -i --icons";
    tree = "eza --tree --icons";
  };
}

