{ pkgs, ... }: {
  plugins.lazygit = {
    enable = true;
    lazyLoad.settings.cmd = "LazyGit";
    settings = {
      floating_window_scaling_factor = 0.95;
    };
  };
}
