{ pkgs, ... }: {
  keymaps = [
    # Terminal
    {
      mode = "t";
      key = "<Esc>";
      action = "<C-\\><C-n>";
      options.desc = "Exit terminal mode";
    }
    # {
    #   mode = "t";
    #   key = "<leader>cd";
    #   action = "pwd|pbcopy<CR><C-\\><C-n>:cd <C-r>+<CR>i";
    # }
    # {
    #   mode = "t";
    #   key = "<leader>cd";
    #   action.__raw = ''
    #     function()
    #       local bufnr = vim.api.nvim_get_current_buf()
    #       local pid = vim.b[bufnr].terminal_job_pid
    #       if pid then
    #         -- Get the cwd of the terminal process (macOS/Linux)
    #         local handle = io.popen("lsof -p " .. pid .. " | grep cwd | awk '{print $NF}'")
    #         if handle then
    #           local cwd = handle:read("*l")
    #           handle:close()
    #           if cwd and cwd ~= "" then
    #             vim.cmd("cd " .. vim.fn.fnameescape(cwd))
    #             print("Changed directory to: " .. cwd)
    #           end
    #         end
    #       end
    #     end
    #   '';
    #   options = { desc = "Sync terminal pwd to Neovim cwd"; silent = true; };
    # }
    {
      mode = "t";
      key = "<leader>cd";
      action.__raw = ''
        function()
          -- Send pwd|pbcopy to the terminal and execute it
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("pwd|pbcopy<CR>", true, false, true), 't', false)
          -- Wait a moment for clipboard to be set, then exit terminal mode and cd
          vim.defer_fn(function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), 'n', false)
            vim.cmd("cd " .. vim.fn.getreg("+"))
            -- Return to terminal mode
            vim.cmd("startinsert")
          end, 100)
        end
      '';
      options = { desc = "Sync terminal pwd to Neovim cwd"; silent = true; };
    }

    # FZF
    {
      mode = "n";
      key = "<leader>ff";
      action.__raw = "require('fzf-lua').files";
      options = { silent = true; desc = "Find files"; };
    }
    {
      mode = "n";
      key = "<leader>fb";
      action.__raw = "require('fzf-lua').buffers";
      options = { silent = true; desc = "Find buffers"; };
    }
    {
      mode = "n";
      key = "<leader>fg";
      action.__raw = "require('fzf-lua').git_files";
      options = { silent = true; desc = "Git files"; };
    }
    {
      mode = "n";
      key = "<leader>fr";
      action.__raw = "require('fzf-lua').live_grep";
      options = { silent = true; desc = "Live grep"; };
    }
    {
      mode = "n";
      key = "<leader>fh";
      action.__raw = "require('fzf-lua').help_tags";
      options = { silent = true; desc = "Help tags"; };
    }
    {
      mode = "n";
      key = "<leader>fd";
      action.__raw = "require('fzf-lua').lsp_document_diagnostics";
      options = { silent = true; desc = "Diagnostics"; };
    }

    # Undotree
    {
      mode = "n";
      key = "<leader>u";
      action = "<cmd>UndotreeToggle<CR>";
      options.desc = "Toggle undotree";
    }

    # Lazy Git
    {
      mode = "n";
      key = "<leader>lg";
      action = "<cmd>LazyGit<CR>";
      options.desc = "Open LazyGit";
    }

    # Clear search highlight
    {
      mode = "n";
      key = "<Esc>";
      action = "<cmd>nohlsearch<CR>";
      options.desc = "Clear search highlight";
    }

    # Better indenting
    {
      mode = "v";
      key = "<";
      action = "<gv";
      options.desc = "Indent left";
    }
    {
      mode = "v";
      key = ">";
      action = ">gv";
      options.desc = "Indent right";
    }
  ];
}
