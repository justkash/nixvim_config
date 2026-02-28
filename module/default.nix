{ pkgs, lib, ... }: {
  imports = [
    ./plugins
    ./keymaps.nix
  ];

  config = {
    # defaultEditor = true;
    # vimdiffAlias = true;
    # withNodeJs = false;
    # withRuby = false;

    performance = {
      combinePlugins = {
        enable = true;
        # Exclude plugins that need to be standalone
        standalonePlugins = [
          "nvim-treesitter"
          "nvim-lspconfig"
          "conjure"
        ];
      };
      byteCompileLua.enable = true;
    };

    luaLoader.enable = true;

    globals = {
      mapleader = "\\";
      maplocalleader = "\\";
      rust_recommended_style = 0;
    };

    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = false; # Disable wayland
      providers.xclip.enable = false;   # Disable X11
    };

    # Enable OSC 52 support
    extraConfigLua = ''
      vim.g.clipboard = {
        name = 'OSC 52',
        copy = {
          ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
          ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
          ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
          ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        },
      }

      -- Diagnostic configuration
      vim.diagnostic.config({
        virtual_text = {
          source = "if_many",
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })

      -- Diagnostic signs
      local signs = { Error = "☒", Warn = "⚠", Hint = "󰌵", Info = "ℹ" }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      -- LSP handlers with rounded borders
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, { border = "rounded" }
      )
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help, { border = "rounded" }
      )

      -- User command to check LSP status
      vim.api.nvim_create_user_command("LspCheck", function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          print("No LSP clients attached to this buffer")
        else
          for _, client in ipairs(clients) do
            print(string.format("LSP: %s (id: %d)", client.name, client.id))
          end
        end
      end, { desc = "Check LSP clients attached to current buffer" })

      local gutter_groups = {
        "SignColumn",
        "LineNr",
        "CursorLineNr",
        "FoldColumn",
        "CursorLineSign",
        "CursorLineFold",
      }

      local function sync_gutter_background()
        local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })

        for _, group in ipairs(gutter_groups) do
          local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
          hl.bg = normal.bg
          vim.api.nvim_set_hl(0, group, hl)
        end
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = sync_gutter_background,
      })
      sync_gutter_background()

      -- editable-term.nvim
      require("editable-term").setup()
    '';

    opts = {
      # basic settings
      guifont = "JetBrains Mono:h12";
      linespace = 0;
      encoding = "utf-8";
      backspace = "indent,eol,start"; # backspace works on every char in insert mode
      completeopt = "menuone,noselect";
      history = 1000;
      startofline = true;
      errorbells = false;
      visualbell = false;
      autoread = true;
      signcolumn = "yes"; # always show signs (diagnostics, gitsigns)

      # display
      background = "dark";
      showmatch = true; # show matching brackets
      scrolloff = 10; # always show 3 rows from edge of the screen
      synmaxcol = 0; # stop syntax highlight after x lines for performance
      laststatus = 0; # never show status line
      list = false; # do not display white characters
      foldenable = false;
      foldlevel = 4; # limit folding to 4 levels
      wrap = true; #do not wrap lines even if very long
      eol = false; # show if there's no eol char
      showbreak = "↪"; # character to show when line is broken
      termguicolors = true;

      # sidebar
      number = false; # hide absolute line numbers
      relativenumber = false; # hide relative line numbers
      showcmd = true; # display command in bottom bar

      # search
      incsearch = true; # starts searching as soon as typing, without enter needed
      ignorecase = true; # ignore letter case when searching
      hlsearch = true; # highlight all matches for previous pattern
      smartcase = true; # case insentive unless capitals used in search
      wildmode = "full:lastused";

      # white characters
      autoindent = true;
      smartindent = true;
      tabstop = 2; # 1 tab = 2 spaces
      shiftwidth = 0; # use tabstop value
      shiftround = true; # use tabstop value
      expandtab = true; # expand tab to spaces

      # files
      hidden = true; # show hidden files and term buffers
      backup = false;
      writebackup = false;
      swapfile = false;
      modifiable = true;
      undofile = true;
      updatetime = 500; # waits 1s of no action for swap file write
      timeoutlen = 500;
    };

    colorschemes.gruvbox = { # TODO Pull colors from global scheme
      enable = true;
      settings = {
        contrast = "hard";
        dim_inactive = false;
        palette_overrides = {
          dark0_hard = "#101414";
        };
        overrides = {
          status_line.fg = "#111515";
          tab_line_fill.bg = "#111515";
          tab_line_sel.bg = "#192020";
        };
      };
    };
  };
}
