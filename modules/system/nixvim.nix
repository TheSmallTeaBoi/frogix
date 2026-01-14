{
  pkgs,
  lib,
  ...
}:
{
  config = {
    extraPackages = with pkgs; [
      black
      codespell
      fd
      gcc
      ghc
      nixfmt
      ormolu
      prettierd
    ];
    opts = {
      updatetime = 100;
      number = true;
      relativenumber = true;
      ignorecase = true;
      smartcase = true;
      list = true;
      foldmethod = "expr";
      foldexpr = "nvim_treesitter#foldexpr()";
      foldenable = true;
      foldlevel = 99;
      scrolloff = 15;
      signcolumn = "yes";
      fo = "cqj";
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      guicursor = "i-ci:ver30-iCursor-blinkwait300-blinkon200-blinkoff150";

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


        -- This is ass, probably.
        -- Disable highlight for TODO, FIX, FIXME, ERROR, INFO, WARNING, etc.
        local function apply_styles()
          -- force-link so colorschemes don't win
          vim.cmd('highlight! link @comment.todo    Comment')
          vim.cmd('highlight! link @comment.note    Comment')
          vim.cmd('highlight! link @comment.warning Comment')
          vim.cmd('highlight! link @comment.error   Comment')

          vim.cmd('highlight! Comment gui=italic')
          vim.cmd('highlight! String gui=italic')
          vim.cmd('highlight! Type gui=italic')
          vim.cmd('highlight! Function gui=italic')

          vim.cmd('highlight! Keyword gui=bolditalic')
          vim.cmd('highlight! Function gui=bolditalic')
        end


        apply_styles()
        vim.api.nvim_create_autocmd("ColorScheme", {
          pattern = "*",
          callback = apply_styles,
        })
      '';
    package = pkgs.neovim-unwrapped;
    enableMan = true;
    clipboard.register = "unnamedplus";
    lsp = {
      servers = {
        #nix
        nil_ls.enable = true;
        nixd.enable = true;

        #python
        pyright.enable = true;
        ruff.enable = true;

        #bash
        bashls.enable = true;

        #lua
        lua_ls.enable = true;

        #javascript et al
        ts_ls.enable = true;
        tailwindcss.enable = true;
        emmet_ls.enable = true;

        #html
        html.enable = true;

        #filesystem
        fsautocomplete.enable = true;
      };
      keymaps = [
        {
          action = lib.nixvim.mkRaw "require('telescope.builtin').lsp_definitions";
          key = "gd";
        }
        {
          key = "gD";
          lspBufAction = "references";
        }
        {
          key = "K";
          lspBufAction = "hover";
        }
        {
          key = "gi";
          lspBufAction = "implementation";
        }
      ];
    };
    plugins = {
      lspconfig.enable = true;
      treesitter = {
        enable = true;
        folding.enable = true;
        settings = {
          highlight.enable = true;
          ensure_installed = [
          ];
        };
        nixvimInjections = true;
      };
      web-devicons.enable = true;
      nix.enable = true;
      comment.enable = true;
      telescope.enable = true;
      intellitab.enable = true;
      indent-o-matic.enable = true;

      # Make it pretty
      dressing.enable = true;
      indent-blankline.enable = true;
      colorizer = {
        enable = true;
        settings = {
          user_default_options = {
            mode = "background";
            always_update = true;
            names = true;
            tailwind = "both";
            tailwing_opts = {
              update_names = true;
            };
          };
        };
      };
      lualine.enable = true;
      lspkind.enable = true;
      tiny-inline-diagnostic.enable = true;

      # Shh.
      # neocord.enable = true;

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
          keys = "strdnaei";
        };
      };

      conform-nvim = {
        enable = true;
        settings = {
          lsp_fallback = true;
          formatters_by_ft = {
            # Conform will run multiple formatters sequentially
            python = [ "black" ];

            nix = [ "nixfmt" ];

            html = [ "prettierd" ];
            css = [ "prettierd" ];
            javascript = [ "prettierd" ];
            javascriptreact = [ "prettierd" ];
            typescript = [ "prettierd" ];

            # Use the "*" filetype to run formatters on all filetypes.
            "*" = [ "codespell" ];
            # Use the "_" filetype to run formatters on filetypes that don't
            # have other formatters configured.
            "_" = [ "trim_whitespace" ];
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
          experimental = {
            ghost_text = true;
          };
          snippet = {
            expand = "luasnip";
          };
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "path"; }
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
        mode = [
          "n"
          "i"
          "s"
        ];
        action = "<cmd>lua require('luasnip').jump(-1)<CR>";
        key = "<C-H>";
      }
      {
        mode = [
          "n"
          "i"
          "s"
        ];
        action = "<cmd>lua require('luasnip').jump(1)<CR>";
        key = "<C-L>";
      }
    ];

    autoCmd = [
      {
        event = [ "BufWritePre" ];
        command = "lua require(\"conform\").format()";
      }
      {
        event = [
          "BufRead"
          "BufNewFile"
        ];
        pattern = [ "*/diary/*.txt" ];
        command = "source notes.vim";
      }
      {
        event = [ "BufWritePre" ];
        pattern = [ "*/diary/*.txt" ];
        command = "helptags ./";
      }
      {
        event = [ "BufReadPost" ];
        pattern = [ "*/diary/*.txt" ];
        command = "normal!'\"";
      }
    ];
  };
}
