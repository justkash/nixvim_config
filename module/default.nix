{ pkgs, lib, ... }:
let
  separatorColor = "#171919";
  activeUiTextColor = "#a89984";
  mutedUiTextColor = "#7c6f64";
in
{
  imports = [
    ./plugins
    ./keymaps.nix
  ];

  config = {
    # Language-specific tools come from project dev shells. None of the
    # configured plugins use Neovim's remote plugin providers.
    withNodeJs = false;
    withPerl = false;
    withPython3 = false;
    withRuby = false;
    waylandSupport = false;

    # Avoid plugin-declared build toolchains (GCC, Go, Node, full Git, etc.)
    # being added to the editor closure. Required runtime tools are listed
    # explicitly in extraPackages.
    autowrapRuntimeDeps = false;
    dependencies = {
      gcc.enable = false;
      git.enable = false;
      go.enable = false;
      nodejs.enable = false;
      tree-sitter.enable = false;
    };

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

    # Keep recoverable swap files in Neovim's state directory and identify
    # large files before file-backed plugins handle BufReadPre.
    extraConfigLuaPre = lib.mkBefore ''
      local swap_directory = vim.fn.stdpath("state") .. "/swap"
      vim.fn.mkdir(swap_directory, "p")
      vim.opt.directory = { swap_directory .. "//" }

      vim.g.large_file_threshold = 1024 * 1024

      local large_file_group = vim.api.nvim_create_augroup(
        "nixvim_large_files",
        { clear = true }
      )

      vim.api.nvim_create_autocmd("BufReadPre", {
        group = large_file_group,
        callback = function(args)
          local filename = vim.api.nvim_buf_get_name(args.buf)
          local stat = filename ~= "" and vim.uv.fs_stat(filename) or nil
          local is_large = stat ~= nil
            and stat.type == "file"
            and stat.size > vim.g.large_file_threshold

          vim.b[args.buf].large_file = is_large

          if is_large then
            vim.diagnostic.enable(false, { bufnr = args.buf })
          end
        end,
      })

      -- LSP setup may globally enable features after BufReadPre, so enforce
      -- the large-file policy again as each client attaches.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = large_file_group,
        callback = function(args)
          if not vim.b[args.buf].large_file then
            return
          end

          vim.diagnostic.enable(false, { bufnr = args.buf })
        end,
      })
    '';

    globals = {
      mapleader = "\\";
      maplocalleader = "\\";
      rust_recommended_style = 0;
    };

    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = false; # Disable wayland
      providers.xclip.enable = false; # Disable X11
    };

    # Use OSC 52 for copy, but a native provider for paste. OSC 52 paste
    # queries can block while waiting for terminals that do not support them.
    extraConfigLua = ''
      local native_paste = {}

      if vim.fn.has("mac") == 1 then
        native_paste["+"] = { "pbpaste" }
        native_paste["*"] = { "pbpaste" }
      elseif vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-paste") == 1 then
        native_paste["+"] = { "wl-paste", "--no-newline" }
        native_paste["*"] = { "wl-paste", "--no-newline", "--primary" }
      elseif vim.env.DISPLAY and vim.fn.executable("xclip") == 1 then
        native_paste["+"] = { "xclip", "-o", "-selection", "clipboard" }
        native_paste["*"] = { "xclip", "-o", "-selection", "primary" }
      elseif vim.env.DISPLAY and vim.fn.executable("xsel") == 1 then
        native_paste["+"] = { "xsel", "--output", "--clipboard" }
        native_paste["*"] = { "xsel", "--output", "--primary" }
      else
        local function unavailable_paste()
          vim.notify(
            "No native clipboard paste provider is available",
            vim.log.levels.WARN
          )
          return { {}, "v" }
        end

        native_paste["+"] = unavailable_paste
        native_paste["*"] = unavailable_paste
      end

      vim.g.clipboard = {
        name = "OSC 52 copy with native paste",
        copy = {
          ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
          ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
        },
        paste = native_paste,
      }

      -- Diagnostic configuration
      vim.diagnostic.config({
        virtual_text = {
          source = "if_many",
          -- Inline virtual text participates in window wrapping instead of
          -- being clipped at the edge of narrow splits.
          virt_text_pos = "inline",
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

      local function sync_ui_highlights()
        local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })

        for _, group in ipairs(gutter_groups) do
          local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
          hl.bg = normal.bg
          vim.api.nvim_set_hl(0, group, hl)
        end

        vim.api.nvim_set_hl(0, "WinSeparator", {
          fg = "${separatorColor}",
          bg = "#101414",
        })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = sync_ui_highlights,
      })
      sync_ui_highlights()

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
      scrollback = 100000; # maximum terminal scrollback retained by Neovim
      startofline = true;
      errorbells = false;
      visualbell = false;
      autoread = true;
      signcolumn = "yes"; # always show signs (diagnostics, gitsigns)

      # display
      background = "dark";
      showmatch = true; # show matching brackets
      scrolloff = 10; # always show 3 rows from edge of the screen
      synmaxcol = 500; # cap legacy syntax work on exceptionally long lines
      laststatus = 3; # use one global status line
      statusline = " %t %m%r%=%l:%c %P ";
      list = false; # do not display white characters
      foldenable = false;
      foldlevel = 4; # limit folding to 4 levels
      wrap = true; # do not wrap lines even if very long
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
      swapfile = true; # preserve unsaved changes for crash recovery
      modifiable = true;
      undofile = true;
      updatetime = 500; # write swap data and trigger CursorHold after 500ms
      timeoutlen = 500;
    };

    colorschemes.gruvbox = {
      # TODO Pull colors from global scheme
      enable = true;
      settings = {
        contrast = "hard";
        dim_inactive = false;
        palette_overrides = {
          dark0_hard = "#101414";
        };
        overrides = {
          StatusLine.bg = separatorColor;
          StatusLine.fg = activeUiTextColor;
          StatusLineNC.bg = separatorColor;
          StatusLineNC.fg = mutedUiTextColor;
          StatusLineTerm.bg = separatorColor;
          StatusLineTerm.fg = activeUiTextColor;
          StatusLineTermNC.bg = separatorColor;
          StatusLineTermNC.fg = mutedUiTextColor;
          TabLine.bg = separatorColor;
          TabLine.fg = mutedUiTextColor;
          TabLineFill.bg = separatorColor;
          TabLineFill.fg = mutedUiTextColor;
          TabLineSel.bg = separatorColor;
          TabLineSel.fg = activeUiTextColor;
        };
      };
    };
  };
}
