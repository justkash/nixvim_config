{ pkgs, ... }: {
  imports = [
    ./treesitter.nix
    ./lsp.nix
    ./completion.nix
    ./lazygit.nix
  ];

  plugins = {
    lz-n = {
      enable = true;

      plugins = [
        {
          __unkeyed-1 = "fzf-lua";
          cmd = "FzfLua";
          after = ''
            function()
              local fzf_lua = require("fzf-lua")
              fzf_lua.setup({
                defaults = {
                  -- Populate quickfix without opening its window. Use
                  -- <leader>q to show the list when it is useful.
                  copen = false,
                },
                winopts = {
                  fullscreen = true,
                  on_close = function()
                    vim.cmd("stopinsert")
                  end,
                },
                files = {
                  follow = true,
                },
                actions = {
                  files = {
                    [1] = true,
                    ["ctrl-q"] = {
                      prefix = "select-all+",
                      fn = fzf_lua.actions.file_sel_to_qf,
                    },
                    ["ctrl-l"] = {
                      prefix = "select-all+",
                      fn = fzf_lua.actions.file_sel_to_ll,
                    },
                  },
                },
              })
            end
          '';
        }
      ];

      keymaps = map (mapping: mapping // { plugin = "fzf-lua"; }) [
        {
          mode = "n";
          key = "<leader>ff";
          action.__raw = ''function() require("fzf-lua").files() end'';
          options = {
            silent = true;
            desc = "Find files";
          };
        }
        {
          mode = "n";
          key = "<leader>fb";
          action.__raw = ''function() require("fzf-lua").buffers() end'';
          options = {
            silent = true;
            desc = "Find buffers";
          };
        }
        {
          mode = "n";
          key = "<leader>fg";
          action.__raw = ''function() require("fzf-lua").git_files() end'';
          options = {
            silent = true;
            desc = "Git files";
          };
        }
        {
          mode = "n";
          key = "<leader>fr";
          action.__raw = ''function() require("fzf-lua").live_grep() end'';
          options = {
            silent = true;
            desc = "Live grep";
          };
        }
        {
          mode = "n";
          key = "<leader>fh";
          action.__raw = ''function() require("fzf-lua").help_tags() end'';
          options = {
            silent = true;
            desc = "Help tags";
          };
        }
        {
          mode = "n";
          key = "<leader>fd";
          action.__raw = ''function() require("fzf-lua").lsp_document_diagnostics() end'';
          options = {
            silent = true;
            desc = "Diagnostics";
          };
        }
      ];
    };

    conjure = {
      enable = true;
      lazyLoad.settings.ft = [
        "clojure"
        "fennel"
        "hy"
        "janet"
        "lisp"
        "python"
        "racket"
        "scheme"
      ];
    };

    undotree = {
      enable = true;
      lazyLoad.settings.cmd = "UndotreeToggle";
    };

    gitsigns = {
      enable = true;
      lazyLoad.settings.event = [
        "BufReadPre"
        "BufNewFile"
      ];
      settings.on_attach.__raw = ''
        function(bufnr)
          if vim.b[bufnr].large_file then
            return false
          end
        end
      '';
    };

    web-devicons = {
      enable = true;
      autoLoad = true;
      settings = {
        color_icons = true;
        strict = true;
      };
    };
  };

  programs.obsessions = {
    enable = true;
    restoreLastSession = true;
  };

  extraPlugins = [
    {
      plugin = pkgs.callPackage ./fzf-lua.nix { };
      optional = true;
    }
    (pkgs.callPackage ./editable-term.nix { })
  ];
}
