{ lib, ... }:
let
  colors = import ../colors/easyonme.nix;
  mkVariant = name: mode:
    let
      isDark = name == "dark";
      ui = mode.ui;
      highlight = bg: { fg = ui.activeText; inherit bg; reverse = false; };
      selected = { fg = ui.selectionText; bg = ui.selection; reverse = false; };
      border = { fg = ui.border; bg = mode.background; };
      picker = highlight mode.background;
      title = picker // { bold = true; };
      muted = { fg = ui.mutedText; bg = mode.background; };
      status = highlight (if isDark then ui.separator else ui.selection);
      statusMuted = {
        fg = ui.mutedText;
        bg = if isDark then ui.separator else ui.surface;
      };
      diffBackground = kind:
        mode.palette.${if isDark then "dark_${kind}_hard" else "light_${kind}"};
    in {
      contrast = if isDark then "hard" else "";
      palette_overrides = mode.palette;
      overrides = {
        Cursor = { fg = mode.background; bg = ui.cursor; reverse = false; };
        lCursor.link = "Cursor";
        TermCursor.link = "Cursor";
        TermCursorNC = { fg = mode.background; bg = ui.mutedText; reverse = false; };

        LineNr.fg = ui.mutedText;
        BlinkCmpGhostText.fg = ui.mutedText;
        NonText.fg = ui.whitespace;
        Whitespace.fg = ui.whitespace;
        CursorLine.bg = ui.surface;
        ColorColumn.bg = ui.surface;
        Folded = { fg = ui.mutedText; bg = ui.surface; };

        NormalFloat = highlight ui.surface;
        # Border cells share the buffer background outside rounded corners.
        FloatBorder = border;
        FloatTitle = title;
        # Buffer dividers stay subtle; popup borders use the stronger ui.border.
        WinSeparator = { fg = ui.separator; bg = mode.background; };

        StatusLine = status;
        StatusLineTerm = status;
        StatusLineNC = statusMuted;
        StatusLineTermNC = statusMuted;
        TabLine = statusMuted;
        TabLineFill = statusMuted;
        TabLineSel = status // { bold = true; };

        Pmenu = highlight ui.surface;
        PmenuSel = selected // { bold = true; };
        PmenuSbar.bg = ui.surface;
        PmenuThumb.bg = ui.border;
        WildMenu = selected // { bold = true; };

        Visual = selected;
        MatchParen = selected // { bold = true; };
        QuickFixLine = selected;
        Search = highlight ui.search;
        IncSearch = highlight ui.searchCurrent;
        CurSearch = highlight ui.searchCurrent;
        Todo = highlight ui.search // { bold = true; };
        DiffText = highlight ui.search;
        DiffAdd = highlight (diffBackground "green");
        DiffDelete = highlight (diffBackground "red");
        DiffChange = highlight (diffBackground "aqua");

        WarningMsg.fg = mode.yellow;
        DiagnosticFloatingWarn.link = "DiagnosticWarn";

        # fzf content and opaque border cells must agree with the editor,
        # including compact pickers opened by obsessions.
        FzfLuaNormal = picker;
        FzfLuaBorder = border;
        FzfLuaTitle = title;
        FzfLuaTitleFlags = title;
        FzfLuaHelpNormal = picker;
        FzfLuaHelpBorder = border;
        FzfLuaPreviewNormal = picker;
        FzfLuaPreviewBorder = border;
        FzfLuaPreviewTitle = title;
        FzfLuaCursor.link = "Cursor";
        FzfLuaCursorLine = selected;
        FzfLuaCursorLineNr = selected;
        FzfLuaSearch.link = "IncSearch";
        FzfLuaScrollBorderEmpty = border;
        FzfLuaScrollBorderFull = { fg = ui.match; bg = mode.background; };
        FzfLuaScrollFloatEmpty.bg = ui.surface;
        FzfLuaScrollFloatFull.bg = ui.border;
        FzfLuaDirIcon.fg = mode.blue;
        FzfLuaDirPart = muted;
        FzfLuaFilePart = picker;

        FzfLuaFzfNormal = picker;
        FzfLuaFzfCursorLine = selected;
        FzfLuaFzfMatch.fg = ui.match;
        FzfLuaFzfBorder = border;
        FzfLuaFzfScrollbar = border;
        FzfLuaFzfSeparator = border;
        FzfLuaFzfGutter = picker;
        FzfLuaFzfHeader = picker;
        FzfLuaFzfInfo = muted;
        FzfLuaFzfPointer.fg = ui.match;
        FzfLuaFzfMarker.fg = ui.match;
        FzfLuaFzfSpinner.fg = ui.match;
        FzfLuaFzfPrompt.fg = ui.match;
        FzfLuaFzfQuery = picker;

        # These groups become ANSI colors independently of fzf_colors.
        FzfLuaHeaderBind.fg = mode.blue;
        FzfLuaHeaderText.fg = ui.mutedText;
        FzfLuaPathLineNr.fg = ui.mutedText;
        FzfLuaPathColNr.fg = ui.match;
        FzfLuaBufNr.fg = ui.mutedText;
        FzfLuaBufId.fg = ui.mutedText;
        FzfLuaBufName.fg = ui.activeText;
        FzfLuaBufLineNr.fg = ui.mutedText;
        FzfLuaBufFlagCur.fg = mode.green;
        FzfLuaBufFlagAlt.fg = ui.match;
        FzfLuaLivePrompt.fg = ui.match;
        FzfLuaLiveSym.fg = ui.match;
        FzfLuaTabTitle = { fg = ui.activeText; bold = true; };
        FzfLuaTabMarker = { fg = ui.match; bold = true; };
      } // (if isDark then {} else {
        Error = {
          fg = mode.red;
          bg = mode.palette.light_red;
          reverse = false;
          bold = true;
        };
        ErrorMsg = {
          fg = mode.red;
          bg = mode.palette.light_red;
          reverse = false;
          bold = true;
        };
      });
    };
  variants = builtins.mapAttrs mkVariant colors;
in
{
  opts.background = "dark";
  opts.guicursor = "n-v-c-sm:block-Cursor/lCursor,i-ci-ve:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor,o:hor50-Cursor/lCursor,a:blinkwait700-blinkoff400-blinkon250,sm:blinkwait175-blinkoff150-blinkon175,t:block-blinkon500-blinkoff500-TermCursor";
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
        end,
      })
    '';
  };
}
