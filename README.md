# Decisions

## EasyOnMe theme

EasyOnMe is derived from Gruvbox. Use `\tt` in normal mode to switch between
dark and light. Each new Neovim session starts dark, and the selected theme
lasts for that session. Light mode uses Gruvbox's default contrast with a warm
ivory `#f7f1df` background, brown text, cream surfaces and selections, and
coordinated earthy syntax, diagnostic, and terminal accents. Set it with
`:colorscheme easyonme`.

Edit the dark and light palette overrides in `colors/easyonme.nix` to
customize their colors. Neovim highlight groups are customized in
`module/theme.nix`.

The flake exports both reusable palettes as `lib.colors.easyonme`. Another Nix
configuration that uses this flake as `inputs.nvim` can read individual values
or the complete palette:

```nix
inputs.nvim.lib.colors.easyonme.light.background
inputs.nvim.lib.colors.easyonme.dark.palette.dark0_hard
```

For generated files, encode the palette as JSON and write it to the store:

```nix
pkgs.writeText "easyonme-colors.json"
  (builtins.toJSON inputs.nvim.lib.colors.easyonme)
```

A plain Nix attribute set is sufficient for sharing values during evaluation;
use a derivation when another program needs a generated file.

## Swap files are disabled

Neovim swap files are turned off (`swapfile = false` in `module/default.nix`).
This has the following consequences:

- Unsaved changes are lost if Neovim, the terminal, or the machine crashes.
  `:recover` has nothing to restore, so only what has been written to disk
  survives.
- Opening a file that is already open in another Neovim instance no longer
  shows the `E325: ATTENTION` warning. Neovim still warns on `:w` if the file
  changed on disk after it was read.
- Persistent undo (`undofile = true`) is unaffected, but its history is saved
  on write, so it cannot recover unsaved edits either.
- No swap files are written to Neovim's state directory
  (`~/.local/state/nvim/swap/` by default). Swap files left there by earlier
  sessions are no longer used and can be deleted.
