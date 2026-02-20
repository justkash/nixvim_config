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
          "<leader>q" = "setloclist";
        };
        lspBuf = {
          gd = "definition";
          gr = "references";
          gD = "declaration";
          gi = "implementation";
          gT = "type_definition";
          K = "hover";
          "<leader>cw" = "workspace_symbol"; 
          "<leader>cr" = "rename"; 
          "<leader>ca" = "code_action";
          "<leader>cf" = "format";
          "<C-k>" = "signature_help";
        };
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
        omnisharp.enable = true;
        gopls.enable = true;
        nixd.enable = true;
        clangd.enable = true;
        jdtls.enable = true;
        rust_analyzer = {
          enable = true;
          installCargo = true;
          installRustc = true;
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
          installGhc = true;
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

    cmp = {
      enable = true;
      autoEnableSources = true;
      
      settings = {
        snippet.expand = ''
          function(args)
            require('luasnip').lsp_expand(args.body)
          end
        '';
        
        mapping = {
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-e>" = "cmp.mapping.abort()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          "<C-n>" = "cmp.mapping.select_next_item()";
          "<C-p>" = "cmp.mapping.select_prev_item()";
          "<C-d>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
        };
        
        sources = [
          { name = "nvim_lsp"; priority = 1000; }
          { name = "luasnip"; priority = 750; }
          { name = "conjure"; priority = 800; }
          { name = "buffer"; priority = 500; }
          { name = "path"; priority = 250; }
        ];
        
        window = {
          completion.border = "rounded";
          documentation.border = "rounded";
        };
      };
    };

    luasnip.enable = true;
    
    cmp-nvim-lsp.enable = true;
    cmp-buffer.enable = true;
    cmp-path.enable = true;
    cmp_luasnip.enable = true;

    lsp-signature = {
      enable = true;
      settings = {
        bind = true;
        hint_enable = true;
        handler_opts.border = "rounded";
      };
    };
  };

  extraPackages = with pkgs; [
    nixfmt
    clang-tools
    dotnet-sdk
    luajitPackages.fennel

    # PureScript
    purs-unstable
    spago-unstable
    purs-tidy-unstable
  ];
}
