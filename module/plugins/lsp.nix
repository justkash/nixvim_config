{ pkgs, ... }: {
  plugins = {
    lsp = {
      enable = true;
      # Disable Nixvim's whole-buffer renderer; the implementation below
      # requests hints only for the current line.
      inlayHints = false;
      lazyLoad.settings.event = [
        "BufReadPre"
        "BufNewFile"
      ];

      keymaps = {
        silent = true;
        diagnostic = {
          "<leader>j" = "goto_next";
          "<leader>k" = "goto_prev";
          "<leader>d" = "open_float";
          "<leader>ld" = "setloclist";
        };
        lspBuf = {
          gd = "definition";
          gr = "references";
          gD = "declaration";
          gi = "implementation";
          gT = "type_definition";
          "<leader>cw" = "workspace_symbol";
          "<leader>cr" = "rename";
          "<leader>ca" = "code_action";
          "<leader>cf" = "format";
        };
        extra = [
          {
            mode = "n";
            key = "K";
            action.__raw = ''
              function()
                vim.lsp.buf.hover({ border = "rounded" })
              end
            '';
            options = {
              silent = true;
              desc = "LSP hover";
            };
          }
          {
            mode = "n";
            key = "<leader>ls";
            action.__raw = ''
              function()
                vim.lsp.buf.signature_help({ border = "rounded" })
              end
            '';
            options = {
              silent = true;
              desc = "LSP signature help";
            };
          }
        ];
      };

      servers = {
        purescriptls = {
          enable = true;
          package = pkgs.purescript-language-server-unstable;
          settings = {
            purescript = {
              addSpagoSources = true;
              addNpmPath = true;
              formatter = "purs-tidy";
              buildCommand = "spago build --purs-args '--json-errors'";
            };
          };
        };
        clojure_lsp.enable = true;
        # These servers drag their associated SDK/compiler into the Neovim
        # closure. Keep their configuration here, but resolve the executable
        # from the active project's dev shell instead.
        omnisharp = {
          enable = true;
          package = null;
        };
        gopls = {
          enable = true;
          package = null;
          settings = {
            gopls = {
              analyses = {
                unusedparams = true;
                shadow = true;
              };
              staticcheck = true;
            };
          };
        };
        nixd = {
          enable = true;
          settings = {
            nixd = {
              nixpkgs.expr = "import ${pkgs.path} {}";
              formatting.command = [ "nixfmt" ];
            };
          };
        };
        clangd = {
          enable = true;
          package = null;
          cmd = [
            "clangd"
            "--background-index"
            "--clang-tidy"
            "--header-insertion=iwyu"
            "--completion-style=detailed"
            "--function-arg-placeholders"
            "--fallback-style=llvm"
          ];
        };
        jdtls = {
          enable = true;
          package = null;
        };
        rust_analyzer = {
          enable = true;
          # Cargo, rustc and clippy are supplied by the project's dev shell.
          installCargo = false;
          installRustc = false;
          settings = {
            rust-analyzer = {
              checkOnSave = true;
              check.command = "clippy";
              cargo.allFeatures = true;
              procMacro.enable = true;
            };
          };
        };
        hls = {
          enable = true;
          package = null;
          # Use the project GHC so HLS sees the same compiler and packages.
          installGhc = false;
        };
        fennel_ls.enable = true;
        lua_ls = {
          enable = true;
          settings = {
            Lua = {
              runtime.version = "LuaJIT";
              workspace.checkThirdParty = false;
              telemetry.enable = false;
              diagnostics.globals = [ "vim" ];
            };
          };
        };
      };
    };
  };

  extraPackages = with pkgs; [
    fzf
    ripgrep
    fd
    bat
    lazygit
    nixfmt
  ];

  extraConfigLua = ''
    -- Request and render inlay hints only for the current line. This avoids
    -- decorating and repeatedly refreshing every visible line in a buffer.
    local inlay_hint_namespace = vim.api.nvim_create_namespace(
      "nixvim_current_line_inlay_hints"
    )
    local inlay_hint_generation = {}

    local function clear_inlay_hints(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      inlay_hint_generation[bufnr] = (inlay_hint_generation[bufnr] or 0) + 1
      vim.api.nvim_buf_clear_namespace(
        bufnr,
        inlay_hint_namespace,
        0,
        -1
      )
    end

    local function render_inlay_hints(bufnr)
      clear_inlay_hints(bufnr)

      if vim.b[bufnr].large_file
        or vim.api.nvim_get_current_buf() ~= bufnr
        or vim.bo[bufnr].buftype ~= ""
      then
        return
      end

      local row = vim.api.nvim_win_get_cursor(0)[1] - 1
      local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
      local generation = inlay_hint_generation[bufnr]
      local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
      if line == nil then
        return
      end

      for _, client in ipairs(vim.lsp.get_clients({
        bufnr = bufnr,
        method = "textDocument/inlayHint",
      })) do
        local hint_client = client
        local range_end
        if row == vim.api.nvim_buf_line_count(bufnr) - 1
          and not vim.bo[bufnr].endofline
        then
          range_end = {
            line = row,
            character = vim.lsp.util.character_offset(
              bufnr,
              row,
              #line,
              hint_client.offset_encoding
            ),
          }
        else
          range_end = { line = row + 1, character = 0 }
        end

        hint_client:request("textDocument/inlayHint", {
          textDocument = { uri = vim.uri_from_bufnr(bufnr) },
          range = {
            start = { line = row, character = 0 },
            ["end"] = range_end,
          },
        }, function(err, hints)
          if err
            or not vim.api.nvim_buf_is_valid(bufnr)
            or vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick
            or inlay_hint_generation[bufnr] ~= generation
          then
            return
          end

          for _, hint in ipairs(hints or {}) do
            if hint.position.line == row then
              local text
              if type(hint.label) == "string" then
                text = hint.label
              else
                local label_parts = {}
                for _, part in ipairs(hint.label) do
                  label_parts[#label_parts + 1] = part.value
                end
                text = table.concat(label_parts)
              end

              local ok, column = pcall(
                vim.str_byteindex,
                line,
                hint_client.offset_encoding,
                hint.position.character,
                false
              )

              if ok then
                local virtual_text = {}
                if hint.paddingLeft then
                  virtual_text[#virtual_text + 1] = { " " }
                end
                virtual_text[#virtual_text + 1] = { text, "LspInlayHint" }
                if hint.paddingRight then
                  virtual_text[#virtual_text + 1] = { " " }
                end

                vim.api.nvim_buf_set_extmark(
                  bufnr,
                  inlay_hint_namespace,
                  row,
                  column,
                  {
                    strict = false,
                    virt_text = virtual_text,
                    virt_text_pos = "inline",
                  }
                )
              end
            end
          end
        end, bufnr)
      end
    end

    local inlay_hint_group = vim.api.nvim_create_augroup(
      "nixvim_current_line_inlay_hints",
      { clear = true }
    )

    vim.api.nvim_create_autocmd({
      "CursorMoved",
      "CursorMovedI",
      "InsertLeave",
      "TextChanged",
      "TextChangedI",
    }, {
      group = inlay_hint_group,
      callback = function(args)
        clear_inlay_hints(args.buf)
      end,
    })

    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "LspAttach" }, {
      group = inlay_hint_group,
      callback = function(args)
        render_inlay_hints(args.buf)
      end,
    })

    vim.api.nvim_create_autocmd({ "LspDetach", "BufWipeout" }, {
      group = inlay_hint_group,
      callback = function(args)
        clear_inlay_hints(args.buf)
        inlay_hint_generation[args.buf] = nil
      end,
    })
  '';
}
