{
  inputs,
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
    emacs = pkgs.emacs-pgtk;
    doomLocalDir = "/home/theo/.config/emacs/";
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
      tailwindcss-language-server
      rustywind

      texliveFull
    ];
  };
  xdg.configFile."emacs/snippets" = {
    source = ./doom/snippets;
    recursive = false;
  };
}
