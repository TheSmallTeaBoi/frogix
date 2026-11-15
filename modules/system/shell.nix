{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.shell;
in
{
  options.frogix.shell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.frogix.enable;
      description = "fish shell, direnv and the core session environment";
    };
    editor = lib.mkOption {
      type = lib.types.str;
      default = "emacsclient -c";
      description = "EDITOR/VISUAL in the session environment";
    };
    browser = lib.mkOption {
      type = lib.types.str;
      default = "qutebrowser";
      description = "BROWSER in the session environment";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      promptInit = ''
        nix-your-shell fish | source
      '';
    };

    programs.direnv.enable = true;

    programs.ssh.askPassword = ""; # I have absolutely no idea why this isn't default.
    users.users.${config.frogix.user}.shell = pkgs.fish;
    environment = {
      systemPackages = [ pkgs.nix-your-shell ];
      variables = {
        EDITOR = cfg.editor;
        VISUAL = cfg.editor;
        BROWSER = cfg.browser;
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_STATE_HOME = "$HOME/.local/state";
        XDG_CACHE_HOME = "$HOME/.cache";
        SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS = "0";
      };
    };
  };
}
