{ pkgs, ... }: {
  plugins = {
    lsp = {
      enable = true;
      inlayHints = true;

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
              desc = "Lsp buf hover";
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
              desc = "Lsp buf signature_help";
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
  ];
}
