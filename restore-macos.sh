#!/usr/bin/env bash
# Restores the Homebrew apps/tools and this repository's Bash dotfiles.
# It deliberately does not restore credentials, shell history, or user data.

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v brew >/dev/null 2>&1; then
    printf 'Homebrew is required. Install it from https://brew.sh, then re-run this script.\n' >&2
    exit 1
fi

brew bundle --file="$repo_dir/Brewfile"

printf '\nInstalling Bash configuration...\n'
"$repo_dir/install.sh"

printf '\nRestore complete. This does not include credentials, history, SSH keys, browser data, or project files.\n'
