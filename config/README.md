# Portable application settings

These files are the settings that can be restored safely on a new Mac:

- `nvim` is a Git submodule pointing to the separate Neovim configuration repository.
- `ghostty`, `tmux`, `btop`, and `vscode` contain UI and editor settings only.
- VS Code extensions are restored from `vscode/extensions.txt`.

Account sessions, API tokens, SSH/GPG keys, browser data, chat data, Raycast data, and application databases are intentionally excluded.

VS Code is configured to use Dank Mono. Install that font separately if you want the exact editor appearance; it is not distributed through this repository.
