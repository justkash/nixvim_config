{ ... }: {
  plugins = {
    cmp = {
      enable = true;

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
          {
            name = "nvim_lsp";
            priority = 1000;
          }
          {
            name = "luasnip";
            priority = 750;
          }
          {
            name = "buffer";
            priority = 500;
            option.get_bufnrs.__raw = ''
              function()
                local bufnr = vim.api.nvim_get_current_buf()
                return vim.b[bufnr].large_file and {} or { bufnr }
              end
            '';
          }
          {
            name = "path";
            priority = 250;
          }
        ];

        window = {
          completion.border = "rounded";
          documentation.border = "rounded";
        };
      };
    };

    luasnip = {
      enable = true;
      lazyLoad.settings.event = "InsertEnter";
    };

    lsp-signature = {
      enable = true;
      lazyLoad.settings.event = "InsertEnter";
      settings = {
        floating_window = false;
        hint_inline.__raw = ''function() return "inline" end'';
      };
    };
  };
}
