# ~/.bash/.bash_profile
# macOS's Terminal.app (and most terminal emulators there) launch *login*
# shells, which read ~/.bash_profile instead of ~/.bashrc - this pulls
# .bashrc in so aliases/functions/prompt still load.
[[ -f "$HOME/.bashrc" ]] && . "$HOME/.bashrc"

# Homebrew's node@22 is keg-only and isn't symlinked into PATH automatically.
if [[ -d "/opt/homebrew/opt/node@22/bin" ]]; then
    export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
fi
