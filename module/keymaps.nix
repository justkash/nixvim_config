{ pkgs, ... }: {
  keymaps = [
    # Termainal
    {
      mode = "t";
      key = "<Esc>";
      action = "<C-\\><C-n>";
    }
    {
      mode = "t";
      key = "<leader>cd";
      action = "pwd|pbcopy<CR><C-\\><C-n>:cd <C-r>+<CR>i";
    }

    # FZF
    {
      mode = "n";
      key = "<leader>f";
      action.__raw = "require('fzf-lua').files";
      options.silent = true;
    }
    {
      mode = "n";
      key = "<leader>b";
      action.__raw = "require('fzf-lua').buffers";
      options.silent = true;
    }
    {
      mode = "n";
      key = "<leader>g";
      action.__raw = "require('fzf-lua').git_files";
      options.silent = true;
    }

    # Undotree
    {
      mode = "n";
      key = "<leader>u";
      action = ":UndotreeToggle<CR>";
    }

    # Lazy Git
    {
      mode = "n";
      key = "<leader>lg";
      action = ":LazyGit<CR>";
    }

    # Toggle Term
    {
      mode = "n";
      key = "<leader>t";
      action = ":ToggleTerm<CR>";
    }
  ];
}
