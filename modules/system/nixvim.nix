{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nixvim.nixosModules.nixvim];
  programs.nixvim = {
    extraPackages = with pkgs; [black alejandra codespell];
    enable = true;
    opts = {
      updatetime = 100;
      number = true;
      relativenumber = true;
      smartcase = true;
      list = true;
      foldmethod = "expr";
      foldexpr = "nvim_treesitter#foldexpr()";
      foldenable = false;
      signcolumn = "yes";
      # show spaces
      listchars = "tab:▸ ,trail:·,nbsp:␣";
    };
    globals = {
      mapleader = " ";
    };
    extraConfigLua = ''
      -- Make lsp popups pretty
      local _border = "rounded"

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, {
          border = _border
        }
        )

        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
          vim.lsp.handlers.signature_help, {
            border = _border
          }
          )

          vim.diagnostic.config{
            float={border=_border}
          };

          require('lspconfig.ui.windows').default_options = {
            border = _border
          }
    '';
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
      intellitab.enable = true;

      # Make it pretty
      dressing.enable = true;
      indent-blankline.enable = true;
      nvim-colorizer.enable = true;
      lualine.enable = true;
      lspkind = {
        enable = true;
        symbolMap = {Codeium = "󰚩";};
      };

      cursorline.enable = true;

      # Make it usable
      lsp-format.enable = true;
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
        };
      };
      hop.enable = true;
      conform-nvim = {
        enable = true;
        extraOptions = {
          lsp_fallback = true;
        };
        formattersByFt = {
          # Conform will run multiple formatters sequentially
          python = ["black"];
          nix = ["alejandra"];
          # Use the "*" filetype to run formatters on all filetypes.
          "*" = ["codespell"];
          # Use the "_" filetype to run formatters on filetypes that don't
          # have other formatters configured.
          "_" = ["trim_whitespace"];
        };
      };
      luasnip = {
        enable = true;
        extraConfig = {
          enable_autosnippets = true;
        };
        fromVscode = [
          {
            lazyLoad = true;
            paths = "${pkgs.vimPlugins.friendly-snippets}";
          }
        ];
      };
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

      # Autocomplete
      codeium-nvim = {
        enable = true;
      };
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          experimental = {ghost_text = true;};
          snippet = {expand = "luasnip";};
          sources = [
            {name = "nvim_lsp";}
            {name = "codeium";}
            {name = "luasnip";}
            {name = "path";}
          ];
          mapping = {
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<C-j>" = "cmp.mapping.select_next_item()";
            "<C-k>" = "cmp.mapping.select_prev_item()";
            "<C-e>" = "cmp.mapping.abort()";
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<S-CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })";
          };
        };
      };
    };

    keymaps = [
      {
        action = "<cmd>Telescope find_files<CR>";
        key = "<Leader>f";
        options.desc = "Find files";
      }
      {
        action = "<cmd>Telescope buffers<CR>";
        key = "<Leader>o";
        options.desc = "Pick open buffers";
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
        event = ["BufWritePre"];
        command = "lua require(\"conform\").format()";
      }
    ];
  };
}
