{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nixvim.nixosModules.nixvim];
  programs.nixvim = {
    enable = true;
    options = {
      number = true;
    };
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    package = pkgs.neovim-unwrapped;
    enableMan = true;
    clipboard.register = "unnamedplus";
    colorscheme = "catppuccin";
    colorschemes.catppuccin = {
      enable = true;
      flavour = "mocha";
      transparentBackground = true;
    };
    plugins = {
      treesitter = {
        enable = true;
        ensureInstalled = [
          "all"
        ];
        nixvimInjections = true;
        };
        lsp = {
          enable = true;
          servers = {
            nixd.enable = true;
            pylsp.enable = true;
            bashls.enable = true;
            lua-ls.enable = true;
            tsserver.enable = true;
            };
          };
      nix.enable = true;
      comment-nvim.enable = true;
      telescope.enable = true;
      nvim-colorizer.enable = true;
      lualine.enable = true;
      lspkind.enable = true;
      cursorline.enable = true;
      surround.enable = true;
      oil = {
        enable = true;
        defaultFileExplorer = true;
      };
      nvim-cmp = {
        enable = true;
        sources = [
          { name = "nvim_lsp"; }
        ];
        mapping = {
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-d>" = "cmp.mapping.scroll_docs(-4)";
          "<C-e>" = "cmp.mapping.close()";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<S-Tab>" = {
            action = "cmp.mapping.select_prev_item()";
            modes = [
              "i"
              "s"
            ];
          };
          "<Tab>" = {
            action = "cmp.mapping.select_next_item()";
            modes = [
              "i"
              "s"
            ];
          };
        };
      };
    };
    globals = {
        mapleader = ";";
      };
    keymaps = [
      {
        action = "<cmd>Telescope find_files<CR>";
        key = "<C-l>";
      }
    ];
  };
}

