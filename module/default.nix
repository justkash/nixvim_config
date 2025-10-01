{ pkgs, lib, ... }: {
  imports = [
    ./plugins
    ./keymaps.nix
  ];

  config = {
    # defaultEditor = true;
    # vimdiffAlias = true;
    # withNodeJs = false;
    # withRuby = false;

    performance = {
      combinePlugins = {
        enable = true;
	standalonePlugins = ["nvim-treesitter"];
      };
      byteCompileLua.enable = true;
    };

    luaLoader.enable = true;

    globals = {
      mapleader = "\\";
      maplocalleader = "\\";
      rust_recommended_style = 0;
    };

    clipboard.register = "unnamedplus";

    opts = {
      # basic settings
      guifont = "JetBrains Mono:h12";
      linespace = 0;
      encoding = "utf-8";
      backspace = "indent,eol,start"; # backspace works on every char in insert mode
      completeopt = "menuone,noselect";
      history = 1000;
      startofline = true;
      errorbells = false;
      visualbell = false;
      autoread = true;
      signcolumn = "number";

      # display
      background = "dark";
      showmatch = true; # show matching brackets
      scrolloff = 10; # always show 3 rows from edge of the screen
      synmaxcol = 0; # stop syntax highlight after x lines for performance
      laststatus = 0; # never show status line
      list = false; # do not display white characters
      foldenable = false;
      foldlevel = 4; # limit folding to 4 levels
      wrap = true; #do not wrap lines even if very long
      eol = false; # show if there's no eol char
      showbreak = "↪"; # character to show when line is broken
      termguicolors = true;

      # sidebar
      number = true; # line number on the left
      relativenumber = true;
      showcmd = true; # display command in bottom bar

      # search
      incsearch = true; # starts searching as soon as typing, without enter needed
      ignorecase = true; # ignore letter case when searching
      hlsearch = true; # highlight all matches for previous pattern
      smartcase = true; # case insentive unless capitals used in search
      wildmode = "full:lastused";

      # white characters
      autoindent = true;
      smartindent = true;
      tabstop = 2; # 1 tab = 2 spaces
      shiftwidth = 0; # use tabstop value
      shiftround = true; # use tabstop value
      expandtab = true; # expand tab to spaces

      # files
      hidden = true; # show hidden files and term buffers
      backup = false;
      writebackup = false;
      swapfile = false;
      modifiable = true;
      undofile = true;
      updatetime = 1000; # waits 1s of no action for swap file write
    };

    colorschemes.gruvbox = { # TODO Pull colors from global scheme
      enable = true;
      settings = {
        contrast = "hard";
        dim_inactive = false;
        palette_overrides = {
          dark0_hard = "#101414";
        };
        overrides = {
          status_line.fg = "#111515";
          tab_line_fill.bg = "#111515";
          tab_line_sel.bg = "#192020";
        };
      };
    };
  };
}
