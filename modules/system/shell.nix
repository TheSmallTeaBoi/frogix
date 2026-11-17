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
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "EDITOR/VISUAL in the session environment (null = unset; the editor is an opt-out area, so the module does not presume one)";
    };
    browser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "BROWSER in the session environment (null = unset, xdg-open/MIME decides; the browser is an opt-out area, so the module does not presume one)";
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
      # eza backs the ls-family aliases in the home shell config — they must
      # exist even when frogix.packages is off (VM, minimal hosts)
      systemPackages = [
        pkgs.nix-your-shell
        pkgs.eza
      ];
      variables = {
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_STATE_HOME = "$HOME/.local/state";
        XDG_CACHE_HOME = "$HOME/.cache";
        SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS = "0";
      }
      // lib.optionalAttrs (cfg.editor != null) {
        EDITOR = cfg.editor;
        VISUAL = cfg.editor;
      }
      // lib.optionalAttrs (cfg.browser != null) {
        BROWSER = cfg.browser;
      };
    };
  };
}
