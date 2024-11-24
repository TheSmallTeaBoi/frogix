{pkgs, ...}: {
  config = {
    extraPackages = with pkgs; [
      black
      alejandra
      codespell
      ormolu
      ghc
      gcc
      fd
    ];
    opts = {
      updatetime = 100;
      number = true;
      relativenumber = true;
      smartcase = true;
      list = true;
      foldmethod = "expr";
      foldexpr = "nvim_treesitter#foldexpr()";
      foldenable = true;
      foldlevel = 99;
      scrolloff = 15;
      signcolumn = "yes";
      fo = "cqj";

      textwidth = 80;
      # This means it'll show the colorcolumn at the textwidth
      colorcolumn = "+0";

      # show spaces and stuff
      listchars = "tab:▸ ,trail:·,nbsp:␣";
    };
    globals = {
      mapleader = " ";
    };
    extraConfigLua =
      # lua
      ''
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

        -- This fixes luasnip.
        package.preload["jsregexp"] = package.loadlib("${pkgs.lua51Packages.jsregexp}/lib/lua/5.1/jsregexp/core.so", "luaopen_jsregexp_core");
      '';
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
        settings = {
          ensure_installed = [
            "all"
          ];
        };
        nixvimInjections = true;
      };
      web-devicons.enable = true;
      lsp = {
        enable = true;
        servers = {
          #nix
          nixd.enable = true;

          #python
          pyright.enable = true;
          ruff.enable = true;

          #bash
          bashls.enable = true;

          #lua
          lua_ls.enable = true;

          #filesystem
          fsautocomplete.enable = true;
        };
        keymaps.lspBuf = {
          "gd" = "definition";
          "gD" = "references";
          "gi" = "implementation";
          "K" = "hover";
        };
      };
      nix.enable = true;
      comment.enable = true;
      telescope.enable = true;
      intellitab.enable = true;
      indent-o-matic.enable = true;

      # Make it pretty
      dressing.enable = true;
      indent-blankline.enable = true;
      nvim-colorizer.enable = true;
      lualine.enable = true;
      lspkind = {
        enable = true;
        symbolMap = {Codeium = "󰚩";};
      };

      neocord.enable = true;

      cursorline.enable = true;

      # Make it usable
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
        };
      };

      hop = {
        enable = true;
        settings = {
          keys = "srtnyeiafg";
        };
      };

      conform-nvim = {
        enable = true;
        settings = {
          lsp_fallback = true;
          formatters_by_ft = {
            # Conform will run multiple formatters sequentially
            python = ["black"];

            nix = ["alejandra"];

            # Use the "*" filetype to run formatters on all filetypes.
            #"*" = ["codespell"];
            # Use the "_" filetype to run formatters on filetypes that don't
            # have other formatters configured.
            "_" = ["trim_whitespace"];
          };
        };
      };

      luasnip = {
        enable = true;
        settings = {
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
      };

      vim-surround.enable = true;
      nvim-autopairs.enable = true;
      rainbow-delimiters.enable = true;

      oil = {
        enable = true;
        settings.defaultFileExplorer = true;
      };

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          experimental = {ghost_text = true;};
          snippet = {expand = "luasnip";};
          sources = [
            {name = "nvim_lsp";}
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
            "<CR>" = "cmp.mapping.confirm({ select = false })";
            "<S-CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })";
          };
        };
      };

      # cmp-ai.settings = {
      #   enable = true;
      #   provider = "Ollama";
      #   provider_options = {
      #     model = "codellama:7b";
      #   };
      #   max_lines = 50;
      #   notify = true;
      #   run_on_every_keystroke = true;
      # };
    };

    keymaps = [
      # Oil
      {
        action = "<cmd>Oil .<CR>";
        key = "<Leader>f";
        options.desc = "Open file explorer";
      }
      # Telescope
      {
        action = "<cmd>Telescope find_files<CR>";
        key = "<Leader>tf";
        options.desc = "Find files";
      }
      {
        action = "<cmd>Telescope buffers<CR>";
        key = "<Leader>to";
        options.desc = "Pick open buffers";
      }
      {
        action = "<cmd>Telescope live_grep<CR>";
        key = "<Leader>tt";
        options.desc = "Find text in project";
      }
      # LSP
      {
        action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
        key = "<Leader>lc";
        options.desc = "Code actions";
      }
      {
        action = "<cmd>lua vim.lsp.buf.rename()<CR>";
        key = "<Leader>lr";
        options.desc = "Rename";
      }
      {
        action = "<cmd>lua vim.diagnostic.open_float()<CR>";
        key = "<Leader>lf";
        options.desc = "Open diagnostic";
      }
      # Other
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
        action = "<cmd>HopPattern<CR>";
        key = "<Leader>/";
      }
      {
        mode = "n";
        action = "<cmd>HopYankChar1<CR>";
        key = "<Leader>y";
      }
      {
        mode = "n";
        action = "<cmd>b#<CR>";
        key = "<Leader>b";
      }
      # LuaSnip
      {
        mode = ["n" "i" "s"];
        action = "<cmd>lua require('luasnip').jump(-1)<CR>";
        key = "<C-H>";
      }
      {
        mode = ["n" "i" "s"];
        action = "<cmd>lua require('luasnip').jump(1)<CR>";
        key = "<C-L>";
      }
    ];

    autoCmd = [
      {
        event = ["BufWritePre"];
        command = "lua require(\"conform\").format()";
      }
      {
        event = ["BufRead" "BufNewFile"];
        pattern = ["*/diary/*.txt"];
        command = "source notes.vim";
      }
      {
        event = ["BufWritePre"];
        pattern = ["*/diary/*.txt"];
        command = "helptags ./";
      }
      {
        event = ["BufReadPost"];
        pattern = ["*/diary/*.txt"];
        command = "normal!'\"";
      }
    ];
  };
}
