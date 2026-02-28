{ pkgs, ... }: {
  imports = [
    ./treesitter.nix
    ./lsp.nix
    ./lazygit.nix
  ];

  plugins = {
    conjure.enable = true;
    undotree.enable = true;
    gitsigns.enable = true;
    web-devicons = {
      enable = true;
      autoLoad = true;
      settings = {
        color_icons = true;
        strict = true;
      };
    };
  };

  extraPlugins = [
    (pkgs.callPackage ./fzf-lua.nix {})
    (pkgs.callPackage ./editable-term.nix {})
  ];
}
