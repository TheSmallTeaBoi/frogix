{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    promptInit = ''
      nix-your-shell fish | source
    '';
  };

  programs.direnv.enable = true;

  programs.ssh.askPassword = ""; # I have absolutely no idea why this isn't default.
  users.users.theo.shell = pkgs.fish;
  environment = {
    systemPackages = [ pkgs.nix-your-shell ];
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_CACHE_HOME = "$HOME/.cache";
      SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS = "0";
      XCURSOR_SIZE = "8";
    };
  };
}
