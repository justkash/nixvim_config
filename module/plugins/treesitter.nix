{ pkgs, ... }: {
  plugins.treesitter = {
    enable = true;
    folding = true;
    nixGrammars = false;
    settings = {
      auto_install = false;
      highlight.enable = true;
      indent.enable = true;
    };
    package = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: with p; [
      regex
      bash
      nix
      javascript
      typescript
      purescript
      elixir
      heex
      eex
      rust
      clojure
      python
      go
      c
      cpp
      haskell
      toml
      yaml
      json
      make
      markdown
      css
      html
    ]);
  };
}
