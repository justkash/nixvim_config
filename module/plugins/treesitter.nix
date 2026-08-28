{ pkgs, ... }: {
  plugins.treesitter = {
    enable = true;
    lazyLoad.settings.event = [
      "BufReadPre"
      "BufNewFile"
    ];
    folding = {
      enable = true;
      disable.__raw = "function(_, bufnr) return vim.b[bufnr].large_file == true end";
    };
    highlight = {
      enable = true;
      disable.__raw = "function(_, bufnr) return vim.b[bufnr].large_file == true end";
    };
    indent = {
      enable = true;
      disable.__raw = "function(_, bufnr) return vim.b[bufnr].large_file == true end";
    };
    # Install pinned Nix grammars instead of compiling parsers at runtime.
    nixGrammars = true;
    grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      bash
      c
      c_sharp
      cmake
      cpp
      css
      lua
      regex
      nix
      javascript
      typescript
      purescript
      elixir
      fennel
      heex
      eex
      rust
      clojure
      python
      go
      haskell
      toml
      yaml
      json
      make
      markdown
      markdown_inline
      html
    ];
  };
}
