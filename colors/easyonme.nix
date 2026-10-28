let
  # EasyOnMe is derived from Gruvbox. Keep this shared base aligned with the
  # Gruvbox.nvim 2.0.0-unstable-2026-04-15 palette in lua/gruvbox.lua.
  base = {
    dark0_hard = "#1d2021";
    dark0 = "#282828";
    dark0_soft = "#32302f";
    dark1 = "#3c3836";
    dark2 = "#504945";
    dark3 = "#665c54";
    dark4 = "#7c6f64";
    light0_hard = "#f9f5d7";
    light0 = "#fbf1c7";
    light0_soft = "#f2e5bc";
    light1 = "#ebdbb2";
    light2 = "#d5c4a1";
    light3 = "#bdae93";
    light4 = "#a89984";
    bright_red = "#fb4934";
    bright_green = "#b8bb26";
    bright_yellow = "#fabd2f";
    bright_blue = "#83a598";
    bright_purple = "#d3869b";
    bright_aqua = "#8ec07c";
    bright_orange = "#fe8019";
    neutral_red = "#cc241d";
    neutral_green = "#98971a";
    neutral_yellow = "#d79921";
    neutral_blue = "#458588";
    neutral_purple = "#b16286";
    neutral_aqua = "#689d6a";
    neutral_orange = "#d65d0e";
    faded_red = "#9d0006";
    faded_green = "#79740e";
    faded_yellow = "#b57614";
    faded_blue = "#076678";
    faded_purple = "#8f3f71";
    faded_aqua = "#427b58";
    faded_orange = "#af3a03";
    dark_red_hard = "#792329";
    dark_red = "#722529";
    dark_red_soft = "#7b2c2f";
    light_red_hard = "#fc9690";
    light_red = "#fc9487";
    light_red_soft = "#f78b7f";
    dark_green_hard = "#5a633a";
    dark_green = "#62693e";
    dark_green_soft = "#686d43";
    light_green_hard = "#d3d6a5";
    light_green = "#d5d39b";
    light_green_soft = "#cecb94";
    dark_aqua_hard = "#3e4934";
    dark_aqua = "#49503b";
    dark_aqua_soft = "#525742";
    light_aqua_hard = "#e6e9c1";
    light_aqua = "#e8e5b5";
    light_aqua_soft = "#e1dbac";
    gray = "#928374";
  };

  # Change these sets to customize each mode independently. EasyOnMe's light
  # variant uses a warm Gruvbox-derived palette; dark preserves its existing
  # customized background.
  darkOverrides = {
    dark0_hard = "#101414";
  };
  lightOverrides = {
    dark0_hard = "#302a23";
    dark0 = "#383128";
    dark0_soft = "#41392e";
    dark1 = "#433b32";
    dark2 = "#554b3f";
    dark3 = "#625542";
    dark4 = "#6f624f";
    light0_hard = "#fbf7eb";
    light0 = "#f7f1df";
    light0_soft = "#f0e7cf";
    light1 = "#eee5cc";
    light2 = "#e1d5b5";
    light3 = "#c7b78f";
    light4 = "#ac9870";
    bright_red = "#a4463a";
    bright_green = "#63713b";
    bright_yellow = "#896827";
    bright_blue = "#4d7079";
    bright_purple = "#89607a";
    bright_aqua = "#497568";
    bright_orange = "#9f5d2d";
    neutral_red = "#a4463a";
    neutral_green = "#63713b";
    neutral_yellow = "#896827";
    neutral_blue = "#4d7079";
    neutral_purple = "#89607a";
    neutral_aqua = "#497568";
    neutral_orange = "#9f5d2d";
    faded_red = "#9b3a32";
    faded_green = "#596a32";
    faded_yellow = "#805d1d";
    faded_blue = "#426775";
    faded_purple = "#805472";
    faded_aqua = "#3d6b5e";
    faded_orange = "#995323";
    light_red_hard = "#e7c6b8";
    light_red = "#efd9cc";
    light_red_soft = "#f3e3d7";
    light_green_hard = "#d2dbb5";
    light_green = "#e1e7cb";
    light_green_soft = "#e8ecd9";
    light_aqua_hard = "#c5d7c2";
    light_aqua = "#d8e4d1";
    light_aqua_soft = "#e3ebdb";
    gray = "#6f624f";
  };

  darkPalette = base // darkOverrides;
  lightPalette = base // lightOverrides;

  withAliases = isDark: palette: ui: {
    inherit palette ui;
    background = if isDark then palette.dark0_hard else palette.light0;
    foreground = if isDark then palette.light1 else palette.dark1;
    red = if isDark then palette.bright_red else palette.faded_red;
    green = if isDark then palette.bright_green else palette.faded_green;
    yellow = if isDark then palette.bright_yellow else palette.faded_yellow;
    blue = if isDark then palette.bright_blue else palette.faded_blue;
    purple = if isDark then palette.bright_purple else palette.faded_purple;
    aqua = if isDark then palette.bright_aqua else palette.faded_aqua;
    orange = if isDark then palette.bright_orange else palette.faded_orange;
    gray = palette.gray;
  };
in
{
  dark = withAliases true darkPalette {
    separator = "#171919";
    activeText = darkPalette.light4;
    mutedText = darkPalette.dark4;
  };

  light = withAliases false lightPalette {
    separator = lightPalette.light3;
    activeText = lightPalette.dark1;
    mutedText = lightPalette.dark4;
    surface = lightPalette.light1;
    selection = lightPalette.light2;
    whitespace = lightPalette.light4;
    search = "#e9d8ac";
    searchCurrent = "#ddc58d";
  };
}
