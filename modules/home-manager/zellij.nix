{
  config,
  inputs,
  outputs,
  pkgs,
  ...
}: {
  programs.zellij = {
    enable = true;
    # enableFishIntegration = true;
  };
}
