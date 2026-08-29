{ pkgs, lib, ... }:
let
  separatorColor = "#171919";
  activeUiTextColor = "#a89984";
  mutedUiTextColor = "#7c6f64";
in
{
  imports = [
    ./plugins
    ./project-lsp.nix
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

      -- Render diagnostics on virtual lines above the affected source line.
      -- Unlike inline virtual text, these decorations never shift the source
      -- code horizontally.
      local diagnostic_virtual_line_namespaces = {}
      local diagnostic_virtual_line_highlights = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticVirtualLinesError",
        [vim.diagnostic.severity.WARN] = "DiagnosticVirtualLinesWarn",
        [vim.diagnostic.severity.INFO] = "DiagnosticVirtualLinesInfo",
        [vim.diagnostic.severity.HINT] = "DiagnosticVirtualLinesHint",
      }

      local function diagnostic_message_lines(message)
        local lines = {}

        for _, message_line in ipairs(vim.split(
          message,
          "\n",
          { plain = true }
        )) do
          -- Preserve indentation produced by the language server; it often
          -- conveys the structure of types and source snippets. Only remove
          -- blank separator rows and the CR from CRLF line endings.
          message_line = message_line:gsub("\r$", "")
          if message_line:find("%S") then
            lines[#lines + 1] = message_line
          end
        end

        return lines
      end

      local function leading_indentation(line, tabstop)
        local columns = 0
        local byte_index = 1

        while byte_index <= #line do
          local character = line:sub(byte_index, byte_index)
          if character == " " then
            columns = columns + 1
          elseif character == "\t" then
            columns = columns + tabstop - (columns % tabstop)
          else
            break
          end
          byte_index = byte_index + 1
        end

        return columns, byte_index
      end

      local function show_diagnostic_sources(bufnr, source_option)
        if source_option == true then
          return true
        end
        if source_option ~= "if_many" then
          return false
        end

        local sources = {}
        for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
          if diagnostic.source then
            sources[diagnostic.source] = true
          end
        end
        return vim.tbl_count(sources) > 1
      end

      vim.diagnostic.handlers.virtual_lines_above = {
        show = function(namespace, bufnr, diagnostics, opts)
          local extmark_namespace = diagnostic_virtual_line_namespaces[namespace]
          if not extmark_namespace then
            extmark_namespace = vim.api.nvim_create_namespace(
              "nixvim.diagnostic.virtual_lines_above." .. namespace
            )
            diagnostic_virtual_line_namespaces[namespace] = extmark_namespace
          end

          vim.api.nvim_buf_clear_namespace(
            bufnr,
            extmark_namespace,
            0,
            -1
          )

          local handler_options = opts.virtual_lines_above or {}
          local include_source = show_diagnostic_sources(
            bufnr,
            handler_options.source
          )
          local diagnostics_by_line = {}
          local tabstop = vim.bo[bufnr].tabstop

          for _, diagnostic in ipairs(diagnostics) do
            local message = handler_options.format
                and handler_options.format(diagnostic)
              or diagnostic.message

            if message then
              local message_lines = diagnostic_message_lines(message)

              if #message_lines > 0 then
                local line_diagnostics = diagnostics_by_line[diagnostic.lnum]
                if not line_diagnostics then
                  line_diagnostics = {}
                  diagnostics_by_line[diagnostic.lnum] = line_diagnostics
                end
                line_diagnostics[#line_diagnostics + 1] = {
                  diagnostic = diagnostic,
                  message_lines = message_lines,
                  source = include_source and diagnostic.source or nil,
                }
              end
            end
          end

          for line, line_diagnostics in pairs(diagnostics_by_line) do
            local source_line = vim.api.nvim_buf_get_lines(
              bufnr,
              line,
              line + 1,
              false
            )[1] or ""
            local virtual_lines = {}

            for _, item in ipairs(line_diagnostics) do
              local diagnostic = item.diagnostic
              local byte_column = math.min(diagnostic.col, #source_line)
              local display_column = vim.fn.strdisplaywidth(
                source_line:sub(1, byte_column)
              )
              local indentation = string.rep(" ", display_column)
              local highlight = diagnostic_virtual_line_highlights[
                diagnostic.severity
              ] or "DiagnosticVirtualLinesInfo"
              local initial_indentation = leading_indentation(
                item.message_lines[1],
                tabstop
              )
              local compensation_columns = math.min(
                display_column,
                initial_indentation
              )
              local compensate_leading_indentation = compensation_columns > 0

              for message_line_number, message_line in ipairs(
                item.message_lines
              ) do
                if compensate_leading_indentation then
                  local indentation_columns, content_byte_index =
                    leading_indentation(message_line, tabstop)

                  if indentation_columns >= compensation_columns then
                    message_line = string.rep(
                      " ",
                      indentation_columns - compensation_columns
                    ) .. message_line:sub(content_byte_index)
                  else
                    -- A less-indented line ends the leading block. It and the
                    -- remaining lines are already relative to the diagnostic
                    -- column and need no compensation.
                    compensate_leading_indentation = false
                  end
                end

                if message_line_number == 1 and item.source then
                  message_line = item.source .. ": " .. message_line
                end

                local prefix = message_line_number == 1 and "┌─ " or "│  "
                virtual_lines[#virtual_lines + 1] = {
                  { indentation, "Normal" },
                  { prefix .. message_line, highlight },
                }
              end
            end

            vim.api.nvim_buf_set_extmark(
              bufnr,
              extmark_namespace,
              line,
              0,
              {
                virt_lines = virtual_lines,
                virt_lines_above = true,
                virt_lines_overflow = "scroll",
              }
            )
          end
        end,
        hide = function(namespace, bufnr)
          local extmark_namespace = diagnostic_virtual_line_namespaces[namespace]
          if extmark_namespace and vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_clear_namespace(
              bufnr,
              extmark_namespace,
              0,
              -1
            )
          end
        end,
      }

      -- Diagnostic configuration
      vim.diagnostic.config({
        virtual_text = false,
        virtual_lines = false,
        virtual_lines_above = {
          source = "if_many",
        },
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
          scope = "buffer",
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
        "DiagnosticSignError",
        "DiagnosticSignWarn",
        "DiagnosticSignHint",
        "DiagnosticSignInfo",
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
      scrollback = 100000; # maximum terminal scrollback retained by Neovim
      startofline = true;
      signcolumn = "yes"; # always show signs (diagnostics, gitsigns)

      # display
      background = "dark";
      showmatch = true; # show matching brackets
      scrolloff = 10; # keep ten screen lines above and below the cursor
      synmaxcol = 500; # cap legacy syntax work on exceptionally long lines
      laststatus = 2; # status per window
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
