{ pkgs, ... }: {
  plugins.treesitter = {
    enable = true;
    folding.enable = true;
    nixGrammars = true;
    settings = {
      auto_install = false;
      highlight.enable = true;
      indent.enable = true;
    };
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
