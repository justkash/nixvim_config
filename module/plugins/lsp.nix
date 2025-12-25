{ pkgs, ... }: {
  plugins.lsp = {
    enable = true;
    keymaps = {
      silent = true;
      diagnostic = {
        "<leader>j" = "goto_next";
        "<leader>k" = "goto_prev";
        "<leader>d" = "open_float";
      };
      lspBuf = {
        gd = "definition";
        gr = "references";
        gD = "declaration";
        gI = "implementation";
        gT = "type_definition";
        K = "hover";
        "<leader>cw" = "workspace_symbol"; 
        "<leader>cr" = "rename"; 
      };
    };
    servers = {
      clojure_lsp.enable = true;
      gopls.enable = true;
      nixd.enable = true;
      rust_analyzer = {
        enable = true;
        installCargo = true;
        installRustc = true;
      };
      hls = {
        enable = true;
        installGhc = true;
      };
    };
  };
}
