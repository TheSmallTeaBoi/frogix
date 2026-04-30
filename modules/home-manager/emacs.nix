{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    inputs.doom-emacs.homeModule
  ];
  services.emacs.enable = true;
  programs.doom-emacs = {
    enable = true;
    doomDir = ./doom;
    doomLocalDir = "/home/theo/.config/emacs/";
    extraPackages = epkgs: [ epkgs.treesit-grammars.with-all-grammars ];
    extraBinPackages = with pkgs; [
      black
      nixfmt
      prettier
      html-tidy
      luaformatter
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

      shellcheck
      python3
      pyright
      typescript
      typescript-language-server
      yaml-language-server
      zls
      zig
      nil
      lua-language-server
      tailwindcss-language-server
      rustywind
    ];
  };
  xdg.configFile."emacs/stylix.el".text =
    let
      colors = config.lib.stylix.colors.withHashtag;
      fonts = config.stylix.fonts;
    in
    # elisp
    ''
      (setq doom-font (font-spec :family "${fonts.monospace.name}" :size 14))
      (setq doom-variable-pitch-font (font-spec :family "${fonts.sansSerif.name}" :size 14))
      (setq nerd-icons-font-family "${fonts.monospace.name}")

      (set-face-attribute 'font-lock-comment-face nil :slant 'italic)
      (set-face-attribute 'font-lock-function-name-face nil :slant 'italic)
      (set-face-attribute 'font-lock-variable-name-face nil :slant 'italic)

      (setq doom-symbol-font (font-spec :family "${fonts.monospace.name}"))

      (add-hook 'after-make-frame-functions
                (lambda (frame)
                  (with-selected-frame frame
                    (doom/reload-font))))

      (add-hook 'doom-load-theme-hook
                (lambda ()
                  (custom-set-faces!
                    ;; Base Editor
                    '(default :background "${colors.base00}" :foreground "${colors.base05}")
                    '(region :background "${colors.base02}")
                    '(hl-line :background "${colors.base01}")

                    ;; Solaire-mode (Doom's background dimmer)
                    '(solaire-default-face :background "${colors.base00}")
                    '(solaire-hl-line-face :background "${colors.base01}")
                    '(solaire-mode-line-face :background "${colors.base01}")
                    '(solaire-mode-line-inactive-face :background "${colors.base00}")

                    ;; Modeline Base
                    '(mode-line :background "${colors.base01}" :foreground "${colors.base05}")
                    '(mode-line-inactive :background "${colors.base00}" :foreground "${colors.base03}")

                    ;; Force Modeline text to drop their old backgrounds!
                    '(doom-modeline-buffer-file :background unspecified)
                    '(doom-modeline-buffer-path :background unspecified)
                    '(doom-modeline-buffer-modified :background unspecified)
                    '(doom-modeline-project-dir :background unspecified)
                    '(doom-modeline-info :background unspecified)
                    '(doom-modeline-warning :background unspecified)

                    ;; Syntax Highlighting
                    '(minibuffer-prompt :foreground "${colors.base0D}")
                    '(font-lock-keyword-face :foreground "${colors.base0E}")
                    '(font-lock-type-face :foreground "${colors.base0A}")
                    '(font-lock-constant-face :foreground "${colors.base09}")
                    '(font-lock-string-face :foreground "${colors.base0B}")
                    '(font-lock-comment-face :foreground "${colors.base03}")
                    '(font-lock-variable-name-face :foreground "${colors.base08}")
                    '(font-lock-function-name-face :foreground "${colors.base0D}")
                  )))

      (when doom-theme
        (run-hooks 'doom-load-theme-hook))
    '';
}
