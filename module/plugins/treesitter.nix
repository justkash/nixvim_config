{ pkgs, ... }: {
  plugins.treesitter = {
    enable = true;
    folding = true;
    settings = {
      auto_install = false;
      highlight.enable = true;
      indent.enable = true;
    };
    grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      regex
      bash
      nix
      elixir
      heex
      eex
      rust
      clojure
      go
      cpp
      haskell
      toml
      yaml
      json
      make
      markdown
    ];
  };
}
