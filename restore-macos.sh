#!/usr/bin/env bash
# One command to rebuild this Mac's Homebrew apps/tools and Bash dotfiles.
# It deliberately does not restore credentials, shell history, or user data.

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'This restore script is for macOS. Use install.sh for Linux.\n' >&2
    exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
    printf 'Installing Homebrew...\n'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

brew bundle --file="$repo_dir/Brewfile"

printf '\nInstalling Bash configuration...\n'
"$repo_dir/install.sh" --yes

printf '\nInstalling portable app settings...\n'
git -C "$repo_dir" submodule update --init --recursive

mkdir -p "$HOME/.config/ghostty" "$HOME/.config/btop" "$HOME/Library/Application Support/Code/User"
cp -R "$repo_dir/config/ghostty/." "$HOME/.config/ghostty/"
cp "$repo_dir/config/btop/btop.conf" "$HOME/.config/btop/btop.conf"
cp "$repo_dir/config/tmux/tmux.conf" "$HOME/.tmux.conf"
cp "$repo_dir/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

vscode_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if [[ -x "$vscode_bin" ]]; then
    while IFS= read -r extension; do
        [[ -n "$extension" ]] && "$vscode_bin" --install-extension "$extension" --force
    done < "$repo_dir/config/vscode/extensions.txt"
fi

if [[ -d "$repo_dir/config/nvim" ]]; then
    mkdir -p "$HOME/.config"
    if [[ -e "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]]; then
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    ln -sfn "$repo_dir/config/nvim" "$HOME/.config/nvim"
fi

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
"$HOME/.tmux/plugins/tpm/bin/install_plugins" || true

printf '\nRestore complete. This does not include credentials, history, SSH keys, browser data, project files, or settings stored by third-party apps.\n'
