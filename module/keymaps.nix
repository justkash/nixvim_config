{ ... }: {
  keymaps = [
    # Terminal
    {
      mode = "t";
      key = "<leader>cd";
      action.__raw = ''
        function()
          local pid = vim.fn.jobpid(vim.bo.channel)
          local cwd

          if vim.uv.os_uname().sysname == "Linux" then
            cwd = vim.uv.fs_readlink("/proc/" .. pid .. "/cwd")
          elseif vim.fn.executable("lsof") == 1 then
            local result = vim.system(
              { "lsof", "-a", "-p", tostring(pid), "-d", "cwd", "-Fn" },
              { text = true }
            ):wait()

            if result.code == 0 then
              cwd = result.stdout:match("\nn([^\r\n]+)")
                or result.stdout:match("^n([^\r\n]+)")
            end
          end

          if not cwd or vim.fn.isdirectory(cwd) == 0 then
            vim.notify("Could not determine the terminal working directory", vim.log.levels.ERROR)
            return
          end

          vim.cmd("cd " .. vim.fn.fnameescape(cwd))
          vim.notify("Neovim cwd: " .. cwd, vim.log.levels.INFO)
        end
      '';
      options = {
        desc = "Sync terminal pwd to Neovim cwd";
        silent = true;
      };
    }

    # FZF keymaps are defined through lz.n so they load fzf-lua on demand.
    {
      mode = "n";
      key = "<leader>dq";
      action.__raw = ''
        function()
          vim.diagnostic.setqflist({ open = false })
        end
      '';
      options = {
        silent = true;
        desc = "Diagnostics to quickfix";
      };
    }

    # LSP
    {
      mode = "n";
      key = "<leader>r";
      action.__raw = "vim.lsp.buf.rename";
      options = {
        silent = true;
        desc = "Rename symbol";
      };
    }

    # Obsessions
    {
      mode = "n";
      key = "<leader>o";
      action = "<cmd>ObsessionsPick<CR>";
      options = {
        silent = true;
        desc = "Pick session (<C-d> to delete, <C-r> to rename)";
      };
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

    # Quickfix navigation
    {
      mode = "n";
      key = "<leader>q";
      action.__raw = ''
        function()
          local quickfix = vim.fn.getqflist({ winid = 0 })
          if quickfix.winid ~= 0 then
            vim.cmd("cclose")
          elseif #vim.fn.getqflist() > 0 then
            vim.cmd("botright copen")
          else
            vim.notify("Quickfix list is empty", vim.log.levels.INFO)
          end
        end
      '';
      options = {
        silent = true;
        desc = "Toggle quickfix list";
      };
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<cmd>cnext<CR>";
      options = {
        silent = true;
        desc = "Next quickfix item";
      };
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<cmd>cprev<CR>";
      options = {
        silent = true;
        desc = "Previous quickfix item";
      };
    }

    # Location list navigation
    {
      mode = "n";
      key = "]l";
      action = "<cmd>lnext<CR>";
      options = {
        silent = true;
        desc = "Next location list item";
      };
    }
    {
      mode = "n";
      key = "[l";
      action = "<cmd>lprev<CR>";
      options = {
        silent = true;
        desc = "Previous location list item";
      };
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
