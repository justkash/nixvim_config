{ lib, ... }:
let
  colors = import ../colors/easyonme.nix;
  light = colors.light;
  lightUi = light.ui;
  lightHighlight = bg: {
    fg = lightUi.activeText;
    inherit bg;
  };
  lightError = {
    fg = light.red;
    bg = light.palette.light_red;
    reverse = false;
    bold = true;
  };
  variants = {
    dark = {
      contrast = "hard";
      palette_overrides = colors.dark.palette;
      overrides = {
        StatusLine.bg = colors.dark.ui.separator;
        StatusLine.fg = colors.dark.ui.activeText;
        StatusLineNC.bg = colors.dark.ui.separator;
        StatusLineNC.fg = colors.dark.ui.mutedText;
        StatusLineTerm.bg = colors.dark.ui.separator;
        StatusLineTerm.fg = colors.dark.ui.activeText;
        StatusLineTermNC.bg = colors.dark.ui.separator;
        StatusLineTermNC.fg = colors.dark.ui.mutedText;
        TabLine.bg = colors.dark.ui.separator;
        TabLine.fg = colors.dark.ui.mutedText;
        TabLineFill.bg = colors.dark.ui.separator;
        TabLineFill.fg = colors.dark.ui.mutedText;
        TabLineSel.bg = colors.dark.ui.separator;
        TabLineSel.fg = colors.dark.ui.activeText;
      };
    };
    light = {
      contrast = "";
      palette_overrides = colors.light.palette;
      overrides = {
        LineNr.fg = lightUi.mutedText;
        BlinkCmpGhostText.fg = lightUi.mutedText;
        NonText.fg = lightUi.whitespace;
        Whitespace.fg = lightUi.whitespace;

        NormalFloat = lightHighlight lightUi.surface;
        FloatBorder = { fg = lightUi.separator; bg = lightUi.surface; };
        FloatTitle = lightHighlight lightUi.surface // { bold = true; };

        StatusLine = lightHighlight lightUi.selection;
        StatusLineTerm = lightHighlight lightUi.selection;
        StatusLineNC = { fg = lightUi.mutedText; bg = lightUi.surface; };
        StatusLineTermNC = { fg = lightUi.mutedText; bg = lightUi.surface; };
        TabLineFill = { fg = lightUi.mutedText; bg = lightUi.surface; };
        TabLineSel = lightHighlight lightUi.selection // { bold = true; };
        WinSeparator = { fg = lightUi.separator; bg = light.background; };

        Pmenu = lightHighlight lightUi.surface;
        PmenuSel = lightHighlight lightUi.selection // { bold = true; };
        PmenuSbar.bg = lightUi.selection;
        PmenuThumb.bg = lightUi.separator;
        WildMenu = lightHighlight lightUi.selection // { bold = true; };

        Visual = lightHighlight lightUi.selection // { reverse = false; };
        MatchParen = lightHighlight lightUi.selection // { bold = true; };
        Search = lightHighlight lightUi.search // { reverse = false; };
        IncSearch = lightHighlight lightUi.searchCurrent // { reverse = false; };
        Todo = lightHighlight lightUi.search // { reverse = false; bold = true; };
        DiffText = lightHighlight lightUi.search // { reverse = false; };
        DiffAdd = lightHighlight light.palette.light_green;
        DiffDelete = lightHighlight light.palette.light_red;
        DiffChange = lightHighlight light.palette.light_aqua;

        Error = lightError;
        ErrorMsg = lightError;
        WarningMsg.fg = light.yellow;
        DiagnosticFloatingWarn.link = "DiagnosticWarn";
      };
    };
  };
in
{
  opts.background = "dark";
  colorscheme = "easyonme";

  extraFiles."colors/easyonme.lua".text = ''
    require("gruvbox").load()
    vim.g.colors_name = "easyonme"
  '';

  colorschemes.gruvbox = {
    enable = true;
    settings = variants.dark;
    # Register before the initial colorscheme, including native background reloads.
    luaConfig.post = ''
      local easyonme_variants = ${lib.nixvim.toLuaObject variants}
      local easyonme_group = vim.api.nvim_create_augroup(
        "nixvim_easyonme_theme",
        { clear = true }
      )

      vim.api.nvim_create_autocmd("ColorSchemePre", {
        group = easyonme_group,
        pattern = "easyonme",
        callback = function()
          -- Gruvbox mutates its palette: replace every color on each load.
          require("gruvbox").setup(easyonme_variants[vim.o.background])
        end,
      })

      local gutter_groups = {
        "SignColumn",
        "LineNr",
        "CursorLineNr",
        "FoldColumn",
        "CursorLineSign",
        "CursorLineFold",
        "DiagnosticSignError",
        "DiagnosticSignWarn",
        "DiagnosticSignHint",
        "DiagnosticSignInfo",
      }

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = easyonme_group,
        pattern = "easyonme",
        callback = function()
          local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })

          for _, group in ipairs(gutter_groups) do
            local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
            hl.bg = normal.bg
            vim.api.nvim_set_hl(0, group, hl)
          end

          if vim.o.background == "dark" then
            vim.api.nvim_set_hl(0, "WinSeparator", {
              fg = "${colors.dark.ui.separator}",
              bg = "${colors.dark.background}",
            })
          end
        end,
      })
    '';
  };
}
