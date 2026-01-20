{ pkgs, ... }: {
  plugins.treesitter = {
    enable = true;
    folding.enable = true;
    nixGrammars = false;
    settings = {
      auto_install = false;
      highlight.enable = true;
      indent.enable = true;
    };
    package = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: with p; [
      bash
      c
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
      html
    ]);
  };
}
