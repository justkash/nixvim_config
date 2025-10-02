{ pkgs, ... }: {
  imports = [
    ./treesitter.nix
    ./lsp.nix
    ./lazygit.nix
  ];

  plugins = {
    conjure.enable = true;
    undotree.enable = true;
  };

  extraPlugins = [
    (pkgs.callPackage ./fzf-lua.nix {})
  ];
}
