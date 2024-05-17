{
  config,
  inputs,
  outputs,
  pkgs,
  ...
}: {
  programs.fish = {
    enable = true;
    promptInit = ''
      nix-your-shell fish | source
    '';
  };

  programs.ssh.askPassword = ""; # I have absolutely no idea why this isn't default.
  users.users.theo.shell = pkgs.fish;
  environment.systemPackages = [pkgs.nix-your-shell];
}
