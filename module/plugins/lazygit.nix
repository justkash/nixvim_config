{ pkgs, ... }: {
  plugins.lazygit = {
    enable = true;
    settings = {
      floating_window_winblend = 0;
      floating_window_scaling_factor = 0.95;
      use_neovim_remote = 1;
    };
  };
}
