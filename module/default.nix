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
    # Project compilers and SDKs come from dev shells. None of the configured
    # plugins use Neovim's remote plugin providers.
    withNodeJs = false;
    withPerl = false;
    withPython3 = false;
    withRuby = false;
    waylandSupport = false;

    # Avoid adding plugin-declared build toolchains (GCC, Go, Node, full Git,
    # etc.) to the editor closure. Runtime CLI tools are listed in
    # extraPackages, while language servers are configured under plugins.lsp.
    autowrapRuntimeDeps = false;
    dependencies = {
      gcc.enable = false;
      git.enable = false;
      go.enable = false;
      nodejs.enable = false;
      tree-sitter.enable = false;
    };

    performance = {
      combinePlugins.enable = true;
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
      providers.wl-copy.enable = false; # disable the Wayland provider
      providers.xclip.enable = false; # disable the X11 provider
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
      completeopt = "menuone,noselect";
      history = 1000;
      scrollback = 100000; # maximum terminal scrollback retained by Neovim
      startofline = true;
      signcolumn = "yes"; # always show signs (diagnostics, gitsigns)

      # display
      background = "dark";
      showmatch = true; # show matching brackets
      scrolloff = 10; # keep ten screen lines above and below the cursor
      synmaxcol = 500; # cap legacy syntax work on exceptionally long lines
      laststatus = 3; # use one global status line
      statusline = " %t %m%r%=%l:%c %P ";
      foldenable = true; # enable folding
      foldlevel = 99; # keep all folds open by default
      foldlevelstart = 99; # start newly opened buffers fully expanded
      wrap = true; # wrap long lines at the window edge
      showbreak = "↪"; # prefix for wrapped screen lines
      termguicolors = true;

      # search
      ignorecase = true; # ignore letter case when searching
      smartcase = true; # match case when the search pattern contains capitals
      wildmode = "full:lastused";

      # indentation
      smartindent = true;
      tabstop = 2; # display a tab as two columns
      shiftwidth = 0; # use tabstop value
      shiftround = true; # round indent shifts to multiples of shiftwidth
      expandtab = true; # insert spaces instead of tab characters

      # files
      eol = false; # new buffers default to no final line ending
      swapfile = true; # preserve unsaved changes for crash recovery
      undofile = true;
      updatetime = 500; # write swap data and trigger CursorHold after 500ms
      timeoutlen = 500;
    };

    colorschemes.gruvbox = {
      enable = true;
      settings = {
        contrast = "hard";
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
