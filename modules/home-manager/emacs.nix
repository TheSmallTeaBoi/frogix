{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.frogix.emacs;
in
{
  options.frogix."emacs".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "doom emacs + emacs server";
  };
  options.frogix."emacs".orgDirectory = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "org directory injected into the doom config (org, org-roam and the roam db live here)";
  };

  imports = [
    inputs.doom-emacs.homeModule
  ];

  config = lib.mkIf cfg.enable {
    home.sessionVariables = lib.mkIf (cfg.orgDirectory != null) {
      FROGIX_ORG_DIR = cfg.orgDirectory;
    };

    services.emacs.enable = true;
    programs.doom-emacs = {
      enable = true;
      doomDir = ./doom;
      emacs = pkgs.emacs-pgtk;
      doomLocalDir = "${config.home.homeDirectory}/.config/emacs/";
      extraPackages = epkgs: [ epkgs.treesit-grammars.with-all-grammars ];
      extraBinPackages = with pkgs; [
        black
        nixfmt
        prettier
        html-tidy
        shfmt
        js-beautify
        stylelint

        fd
        gnumake
        cmake
        graphviz
        maim

        python314Packages.pyflakes
        python314Packages.pytest_8_3
        isort
        pipenv

        ispell
        shellcheck
        python3
        pyright
        typescript
        typescript-language-server
        haskell-language-server
        yaml-language-server
        zls
        zig
        nil
        lua-language-server
        rustywind

        texliveFull
      ];
    };
    xdg.configFile."emacs/snippets" = {
      source = ./doom/snippets;
      recursive = false;
    };
  };
}
