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

printf '\nRestore complete. This does not include credentials, history, SSH keys, browser data, project files, or settings stored by third-party apps.\n'
