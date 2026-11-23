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
        # Doom / Org core tools only — language LSPs, formatters, linters and
        # toolchains come from per-project devShells (direnv).
        fd
        gnumake
        graphviz
        ispell

        # Minimal TeX Live for Org LaTeX export (ox-latex defaults + previews)
        # and booklet export (pdfbook2 --paper=a4paper in doom/config.el).
        (texliveBasic.withPackages (
          ps: with ps; [
            # org-latex-default-packages-alist
            amsmath
            amsfonts
            capt-of
            cm-super
            ec
            graphics
            grffile
            hyperref
            tools
            ulem
            wrapfig
            # org latex preview & common formatting
            babel
            babel-english
            babel-spanish
            booktabs
            dvipng
            dvisvgm
            etoolbox
            fancyhdr
            geometry
            latexmk
            listings
            microtype
            preview
            soul
            xcolor
            # booklet export (pdfbook2 -> pdfcrop + pdfjam + pdfpages)
            everyshi
            eso-pic
            pdfbook2
            pdfcrop
            pdfjam
            pdflscape
            pdfpages
          ]
        ))
      ];
    };
    xdg.configFile."emacs/snippets" = {
      source = ./doom/snippets;
      recursive = false;
    };
  };
}
