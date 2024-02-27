{config, inputs, outputs, pkgs, ...}:
{
  programs.fish.enable = true;
  users.users.theo.shell = pkgs.fish;
}
