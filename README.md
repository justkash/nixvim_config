# Decisions

## EasyOnMe theme

EasyOnMe is derived from Gruvbox. Use `\tt` in normal mode to switch between
dark and light. Each new Neovim session starts dark, and the selected theme
lasts for that session. Light mode uses Gruvbox's default contrast with a warm
ivory `#f7f1df` background, brown text, cream surfaces and selections, and
coordinated earthy syntax, diagnostic, and terminal accents. Both modes use
distinct cursors, visible borders, and high-contrast menu selections. Pickers
share the editor background so their rounded borders blend into surrounding
buffers. Set it with `:colorscheme easyonme`.

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

## Oil file manager

[oil.nvim](https://github.com/stevearc/oil.nvim) lets you manage files by
editing a directory listing as a buffer. In normal mode, press `\dd` to open
the current file's directory; inside Oil, `-` goes to its parent. You can also
run `:Oil path` or open Neovim on a directory. Press `<Enter>` to open an
entry. Press `o` to add a name (end it with `/` to make a directory); edit an
existing name to rename it while keeping its identifier. In Oil, `dd` deletes
an entry.

To move an entry, cut the whole line with `"add`, navigate to the destination,
then paste with `"ap`. To copy, yank the whole line with `"ayy` and paste with
`"ap`. Register `a` avoids relying on the system clipboard; keeping the full
line preserves the entry identifier.

Press `:w` to review and confirm the planned operations across Oil buffers
before applying them. Finish moves before saving; use `u` to undo pending
edits. Press `g.` to show hidden entries and `g?` for Oil's keymap help.
