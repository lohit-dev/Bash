#!/usr/bin/env bash
case "$-" in
    *i*) iatest=1 ;;
    *)   iatest=0 ;;
esac
#==============================================================================
# ███████╗██╗  ██╗███████╗██╗     ██╗     
# ██╔════╝██║  ██║██╔════╝██║     ██║     
# ███████╗███████║█████╗  ██║     ██║     
# ╚════██║██╔══██║██╔══╝  ██║     ██║     
# ███████║██║  ██║███████╗███████╗███████╗
# ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
#                                         
# ███╗   ██╗██╗███╗   ██╗     ██╗ █████╗  
# ████╗  ██║██║████╗  ██║     ██║██╔══██╗ 
# ██╔██╗ ██║██║██╔██╗ ██║     ██║███████║ 
# ██║╚██╗██║██║██║╚██╗██║██   ██║██╔══██║ 
# ██║ ╚████║██║██║ ╚████║╚█████╔╝██║  ██║ 
# ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝ 
                                                                            
#==============================================================================


# If not running interactively, don't do anything
[[ $- != *i* ]] && return
# -o internal_suppress_bash_output=1 keeps Bash's own stdout/stderr (e.g. the
# "TERM: changed, rebinding..." flash) from leaking to the terminal during
# ble-attach/reload. It's ble.sh's documented default already, but setting it
# explicitly here guarantees nothing later in this file can turn it off.
if [[ -f "$HOME/.local/share/blesh/ble.sh" ]]; then
    source "$HOME/.local/share/blesh/ble.sh" --attach=none -o internal_suppress_bash_output=1
fi

# ================================= fastfetch ================================= #
if command -v fastfetch &> /dev/null; then
    if [[ -d "$HOME/.local/share/fastfetch" ]]; then
        export ffconfig=minimal
        fastfetch --config "$ffconfig"
        alias fastfetch='clr && fastfetch --config "$ffconfig"'
    else
        fastfetch
    fi
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# ================================= prompt ================================= #
PS1='\n\e[1;36m╭─ \e[1;37m\u\e[1;34m@\e[1;37m\h\e[1;0m in $(if [[ "$PWD" = "$HOME" ]]; then echo "\e[1;36m󰜥"; elif [[ "$PWD" = "/" ]]; then echo "\e[1;36m\e[1;0m"; else echo "\e[1;33m\w"; fi)\n\e[1;36m╰──\e[1;32m󰘧\e[1;0m '

# set prompt starship
# export STARSHIP_CONFIG=/home/shell-ninja/.bash/starship/starship-macos_frame.toml

# Cache starship init to speed up terminal start
STARSHIP_CACHE="$HOME/.cache/starship_init.bash"
if [[ ! -s "$STARSHIP_CACHE" || "$(command -v starship)" -nt "$STARSHIP_CACHE" ]]; then
    mkdir -p "$(dirname "$STARSHIP_CACHE")"
    starship init bash > "$STARSHIP_CACHE"
fi
# source "$STARSHIP_CACHE"


# User specific environment
for p in "$HOME/.local/bin" "$HOME/bin" "$HOME/.opencode/bin"; do
    if [[ ":$PATH:" != *":$p:"* ]] && [[ -d "$p" ]]; then
        export PATH="$p:$PATH"
    fi
done

# ================================= macOS / Homebrew extras ================================= #
if [[ "$(uname -s)" == "Darwin" ]]; then
    # Homebrew itself (Apple Silicon prefix first, then Intel's /usr/local)
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv bash)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv bash)"
    fi

    # Go workspace binaries.
    if command -v go &> /dev/null; then
        export GOPATH="$(go env GOPATH)"
        if [[ ":$PATH:" != *":$GOPATH/bin:"* ]]; then
            export PATH="$GOPATH/bin:$PATH"
        fi
    fi

    # bun
    if [[ -d "$HOME/.bun" ]]; then
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
    fi

    # nvm (lazy-loaded via nvm.sh, which also manages its own PATH entries)
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"

    # Homebrew keg-only formulae aren't symlinked into PATH automatically
    # (e.g. `ruby`, `python@x.y`, `postgresql@x` all fall in this bucket).
    if [[ -n "$HOMEBREW_PREFIX" ]]; then
        for keg in "openjdk@21" "node@22" ruby "python@3.14" "postgresql@18"; do
            keg_bin="$HOMEBREW_PREFIX/opt/$keg/bin"
            if [[ -d "$keg_bin" ]] && [[ ":$PATH:" != *":$keg_bin:"* ]]; then
                export PATH="$keg_bin:$PATH"
            fi
        done
        [[ -d "$HOMEBREW_PREFIX/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home" ]] && export JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
        unset keg keg_bin
    fi

    # Android Studio's SDK, when it is installed.
    android_sdk="$HOME/Library/Android/sdk"
    if [[ -d "$android_sdk" ]]; then
        export ANDROID_HOME="$android_sdk"
        export ANDROID_SDK_ROOT="$android_sdk"
        for android_bin in "$android_sdk/platform-tools" "$android_sdk/emulator" "$android_sdk/cmdline-tools/latest/bin"; do
            [[ -d "$android_bin" && ":$PATH:" != *":$android_bin:"* ]] && export PATH="$android_bin:$PATH"
        done
        unset android_bin
    fi
    unset android_sdk
fi

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head 200; else bat -n --color=always --line-range :1000 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"



# ================================= fzf ================================= #
if [[ -x "$(command -v fzf)" ]]; then
	export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
	  --info=inline-right \
	  --ansi \
	  --layout=reverse \
	  --border=rounded \
	  --color=border:#27a1b9 \
	  --color=fg:#c0caf5 \
	  --color=gutter:#16161e \
	  --color=header:#ff9e64 \
	  --color=hl+:#2ac3de \
	  --color=hl:#2ac3de \
	  --color=info:#545c7e \
	  --color=marker:#ff007c \
	  --color=pointer:#ff007c \
	  --color=prompt:#2ac3de \
	  --color=query:#c0caf5:regular \
	  --color=scrollbar:#27a1b9 \
	  --color=separator:#ff9e64 \
	  --color=spinner:#ff007c \
	"
fi

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# Configure FZF for directory preview
if command -v fzf &> /dev/null; then
  _fzf_preview() {
    eza --color=always --icons=always "$1"
  }
fi


# ================================= completion and autocd ================================= #
bind "set completion-ignore-case on"
shopt -s autocd
# Makes `echo` expand backslash escapes (\e, \n, \t, ...) by default, same as
# always passing `echo -e`. Without this, `echo '\e[1;36mHello\e[0m'` prints
# the escape sequence literally instead of coloring the text - you'd need
# `echo -e` or ANSI-C quoting ($'...') every time otherwise.
shopt -s xpg_echo
unset rc



# ================================= add functionalities ================================= #
# Only load `thefuck` and `zoxide` when needed
_thefuck_init() { eval "$(thefuck --alias)"; unset -f _thefuck_init; }

alias fuck='_thefuck_init && fuck'
alias hell='_thefuck_init && hell'

# For zoxide integration with FZF (if zoxide is installed)
if command -v zoxide &> /dev/null; then
    # NOTE: intentionally NOT --cmd cd. Overriding `cd` globally makes every
    # internal `cd` call (ble.sh's reload/reattach, other tools, etc.) go
    # through zoxide's fuzzy matcher instead of a literal path lookup, which
    # is what causes the "zoxide: no match found" noise right after `[ble:
    # reload]`. Use `z <query>` for fuzzy-jumping and leave `cd` alone.
    eval "$(zoxide init bash)"
    alias zi='zoxide query -i | xargs -r eza --color=always --icons=always'
    _ZO_DOCTOR=0
fi

# ================================= source functions, aliases and blers ================================= #
source ~/.bash/functions.sh
source ~/.bash/alias.sh
source ~/.bash/.blerc



# ================================= Expand the history size ================================= #
export HISTFILESIZE=10000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T" # add timestamp to history

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
shopt -s checkwinsize

# Causes bash to append to history instead of overwriting it so if you start a new terminal, you have old session history
shopt -s histappend
PROMPT_COMMAND="history -a"
alias hist="history | grep"


# ================================= transient prompt and right prompt ================================= #
bleopt prompt_ps1_transient=always
bleopt prompt_ps1_final="❯ "

# bleopt prompt_rps1='\n$(current_time)'
bleopt prompt_rps1='\n$(git rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo $(git_info) || echo "")${elapsed_time_display}'


# ================================= vi mode ================================= #
bind 'set editing-mode vi'
bleopt keymap_vi_mode_show:=
bind "set show-mode-in-prompt on"
bind "set vi-cmd-mode-string "
bind "set vi-ins-mode-string "


# ================================= ble-attach ================================= #
[[ ${BLE_VERSION-} ]] && ble-attach
# source "$HOME/.cargo/env"
