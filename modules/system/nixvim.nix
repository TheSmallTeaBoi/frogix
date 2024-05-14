{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nixvim.nixosModules.nixvim];
  programs.nixvim = {
    enable = true;
    opts = {
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
      settings = {
        flavour = "mocha";
        transparent_background = true;
      };
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
            ruff.enable = true;
            bashls.enable = true;
            lua-ls.enable = true;
            fsautocomplete.enable = true;
            tsserver.enable = true;
            };
          keymaps.lspBuf = {
            "gd" = "definition";
            "gD" = "references";
            "gi" = "implementation";
            "K" = "hover";
            };
        };
        lsp-lines = {
            enable = true;
            currentLine = true;
          };
      nix.enable = true;
      comment.enable = true;
      telescope.enable = true;
      nvim-colorizer.enable = true;
      lualine.enable = true;
      lspkind.enable = true;
      lsp-format.enable = true;
      cursorline.enable = true;
      hop.enable = true;
      which-key = {
        enable = true;
        registrations = {
          "gd" = "Go to definition";
          "gD" = "Go to uses";
          "gi" = "Go to implementation";
          "K" = "Hover info";
        };
      };
      surround.enable = true;
      nvim-autopairs.enable = true;
      oil = {
        enable = true;
        settings.defaultFileExplorer = true;
        };
      coq-nvim = {
        enable = true;
        settings.auto_start = "shut-up";
      };
      friendly-snippets.enable = true;
    };
    globals = {
        mapleader = " ";
      };
    keymaps = [
      {
        action = "<cmd>Telescope find_files<CR>";
        key = "<Leader>f";
        options.desc = "Find files";
      }
      {
        action = "<cmd>Telescope live_grep<CR>";
        key = "<Leader>t";
        options.desc = "Find text in project";
      }
      {
        action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
        key = "<Leader>c";
        options.desc = "Code actions";
      }
      {
        action = "<cmd>lua vim.lsp.buf.rename()<CR>";
        key = "<Leader>r";
        options.desc = "Rename";
      }
      {
        mode = "n";
        action = "<cmd>nohlsearch<CR>";
        key = "<Esc>";
      }
      {
        mode = "n";
        action = "<cmd>HopWord<CR>";
        key = "<Leader><Leader>";
      }
      {
        mode = "n";
        action = "<cmd>b#<CR>";
        key = "<Leader>b";
      }
    ];
    autoCmd = [
      {
        event = [ "BufWritePre" ];
        command = "lua vim.lsp.buf.format()";
      }
    ];
  };
}

