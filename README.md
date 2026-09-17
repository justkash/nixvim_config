# Decisions

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
