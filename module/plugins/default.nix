{ pkgs, ... }: {
  imports = [
    ./treesitter.nix
    ./lsp.nix
    ./lazygit.nix
  ];

  plugins = {
    conjure.enable = true;
    undotree.enable = true;
    fzf-lua.enable = true;
  };
}
