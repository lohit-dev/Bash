#!/bin/bash

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

# Color definitions
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\x1b[38;5;214m"
end="\e[1;0m"

# Message prompt function
msg() {
    local actn=$1
    local msg=$2

    case "$actn" in
        act) echo -e "${green}=>${end} $msg" ;;
        att) echo -e "${yellow}!!${end} $msg" ;;
        ask) echo -e "${orange}??${end} $msg" ;;
        dn)  echo -e "${cyan}::${end} $msg\n" ;;
        skp) echo -e "${magenta}[ SKIP ]${end} $msg" ;;
        err) echo -e "${red}>< Ohh no! an error...${end}\n   $msg\n" ;;
    esac
}

# Log file setup (portable: avoids relying on `realpath`, which is not
# guaranteed to exist on older macOS installs)
dir="$(cd "$(dirname "$0")" && pwd)"
log="$dir/bash-install-$(date +%I:%M_%p).log"
touch "$log"

# OS detection
OS_TYPE="$(uname -s)"

# Required packages
common_packages=(
    bash-completion
    bat
    curl
    eza
    fastfetch
    figlet
    fzf
    git
    less
    zoxide
    pv
)

for_opensuse=(
    python311
    python311-pip
    python311-pipx
)

for_macos=(
    bash
    neovim
    tmux
    ripgrep
    fd
    tree
    lazygit
    tree-sitter
    postgresql@18
    mpv
    ffmpeg
    cloudflared
    ruby
    python@3.14
)

for_macos_casks=(
    ghostty
    orbstack
    bruno
    repobar
    font-maple-mono-nf
    font-jetbrains-mono
)

clear && printf "${green}::${end} Starting the script...\n"
sleep 1
echo

# macOS ships bash 3.2 (last GPLv2 release) as /bin/bash, but this dotfiles
# setup relies on bash 4+ features (associative arrays, $EPOCHSECONDS, etc).
# Warn early so the user installs a modern bash via Homebrew first.
if [[ "$OS_TYPE" == "Darwin" && "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    msg att "You're running bash ${BASH_VERSION%%[^0-9.]*}, but this setup needs bash 4+."
    msg att "This script will install a modern bash via Homebrew for you."
    msg att "After it finishes, add it to /etc/shells and set it as your default shell:"
    msg att "  echo \$(brew --prefix)/bin/bash | sudo tee -a /etc/shells && chsh -s \$(brew --prefix)/bin/bash"
    sleep 2
fi

# Package manager detection
PKG_MANAGER=""
if [[ "$OS_TYPE" == "Darwin" ]]; then
    if command -v brew &> /dev/null; then
        PKG_MANAGER="brew"
        # bash-completion on Homebrew is versioned; use the v2 formula and
        # pull in a modern bash since macOS ships bash 3.2 by default.
        common_packages=("${common_packages[@]/bash-completion/bash-completion@2}")
        common_packages+=("${for_macos[@]}")
    else
        msg err "Homebrew not found. Install it first from https://brew.sh, then re-run this script."
        exit 1
    fi
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
elif command -v zypper &> /dev/null; then
    PKG_MANAGER="zypper"
    common_packages+=("${for_opensuse[@]}")
elif command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
else
    msg err "Unsupported distribution. Could not find brew, pacman, dnf, zypper, or apt."
    exit 1
fi

# Ask questions early
# macOS gets its fonts (incl. Nerd Fonts) via Homebrew casks below, so the
# manual JetBrains Mono Nerd Font download only applies to Linux.
if [[ "$OS_TYPE" != "Darwin" ]]; then
    msg ask "Would you like to install a Nerd font? In this case, the ${yellow}JetBrains Mono Nerd Font${end}? It is important. [ y/n ]"
    read -r -p "Select: " font
    echo
fi

msg ask "Would you like to use ${cyan}starship${end} as the bash prompt? [ y/n ]"
read -r -p "Select: " prmpt
echo

# Helper functions for packages
fn_is_installed() {
    local pkg=$1
    case "$PKG_MANAGER" in
        brew) brew list --formula "$pkg" &> /dev/null ;;
        pacman) pacman -Q "$pkg" &> /dev/null ;;
        dnf) rpm -q "$pkg" &> /dev/null ;;
        zypper) zypper se -i "$pkg" &> /dev/null ;;
        apt) dpkg -l "$pkg" &> /dev/null ;;
    esac
}

fn_install() {
    local pkg=$1

    if fn_is_installed "$pkg"; then
        msg skp "Skipping $pkg, it is already installed..."
        return 0
    fi

    msg act "Installing $pkg..."
    case "$PKG_MANAGER" in
        brew) brew install "$pkg" 2>&1 | tee -a "$log" > /dev/null ;;
        pacman) sudo pacman -S --noconfirm "$pkg" 2>&1 | tee -a "$log" > /dev/null ;;
        dnf) sudo dnf install -y "$pkg" 2>&1 | tee -a "$log" > /dev/null ;;
        zypper) sudo zypper in -y "$pkg" 2>&1 | tee -a "$log" > /dev/null ;;
        apt) sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" 2>&1 | tee -a "$log" > /dev/null ;;
    esac

    if fn_is_installed "$pkg"; then
        msg dn "$pkg was installed successfully!"
    else
        msg err "Could not install $pkg"
    fi
}

# Install core packages
for pkg in "${common_packages[@]}"; do
    fn_install "$pkg"
done

# macOS: Homebrew casks (GUI apps + fonts) are a separate namespace from
# formulae, so they need their own install/detection commands.
if [[ "$PKG_MANAGER" == "brew" ]]; then
    fn_is_installed_cask() {
        brew list --cask "$1" &> /dev/null
    }

    fn_install_cask() {
        local cask=$1
        if fn_is_installed_cask "$cask"; then
            msg skp "Skipping $cask, it is already installed..."
            return 0
        fi
        msg act "Installing $cask..."
        brew install --cask "$cask" 2>&1 | tee -a "$log" > /dev/null
        if fn_is_installed_cask "$cask"; then
            msg dn "$cask was installed successfully!"
        else
            msg err "Could not install $cask"
        fi
    }

    for cask in "${for_macos_casks[@]}"; do
        fn_install_cask "$cask"
    done

    # postgresql@18 is keg-only and doesn't start itself; register + start it
    # as a per-user background service (also handles future logins/reboots).
    if fn_is_installed "postgresql@18"; then
        msg act "Starting postgresql@18 service..."
        brew services start postgresql@18 2>&1 | tee -a "$log" > /dev/null
        msg dn "postgresql@18 is running (brew services start postgresql@18 to restart it later)."
    fi

    # cloudflared has an optional background service too - leave it opt-in
    # rather than auto-starting a tunnel daemon with no config yet.
fi

# Install thefuck
# Note: the thefuck formula was removed from homebrew-core, so on macOS we
# install it the same way we do for openSUSE - via pipx.
if [[ "$PKG_MANAGER" == "zypper" || "$PKG_MANAGER" == "brew" ]]; then
    if ! command -v pipx &> /dev/null; then
        if [ "$PKG_MANAGER" = "brew" ]; then
            msg act "Installing pipx via Homebrew..."
            brew install pipx 2>&1 | tee -a "$log" > /dev/null
            pipx ensurepath &> /dev/null
        fi
    fi

    if command -v pipx &> /dev/null; then
        msg act "Installing thefuck via pipx..."
        pipx runpip thefuck install setuptools &> /dev/null
        sleep 0.5
        if [ "$PKG_MANAGER" = "brew" ]; then
            pipx install thefuck 2>&1 | tee -a "$log" > /dev/null || true
        else
            pipx install --python python3.11 thefuck 2>&1 | tee -a "$log" > /dev/null || true
        fi

        if command -v thefuck &> /dev/null; then
            msg dn "thef*ck was installed successfully!" && sleep 1
        else
            msg err "Could not install thefuck"
        fi
    fi
elif [[ "$PKG_MANAGER" =~ ^(pacman|dnf|apt)$ ]]; then
    fn_install thefuck
fi

# Install starship
if [ "$PKG_MANAGER" = "dnf" ]; then
    msg act "Enabling starship copr repo..."
    sudo dnf copr enable -y atim/starship 2>&1 | tee -a "$log" > /dev/null
fi

if [[ "$PKG_MANAGER" != "apt" ]]; then
    fn_install starship
else
    if ! command -v starship &> /dev/null; then
        msg act "Installing starship via official installer..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y 2>&1 | tee -a "$log" > /dev/null
        msg dn "starship installed successfully!"
    else
        msg skp "Skipping starship, it is already installed..."
    fi
fi

msg act "Installing bash files..." && sleep 0.5

# Backup existing files
BACKUP_DIR="$HOME/.bash-backup-${USER}"
for item in "$HOME/.bash" "$HOME/.bashrc"; do
    if [[ -d $item ]] || [[ -f $item ]]; then
        mkdir -p "$BACKUP_DIR"
        timestamp=$(date +%I:%M:%S%p)
        if [[ -d $item ]]; then
            msg att "A ${green}.bash${end} directory is available. Backing it up..." 
            mv "$item" "$BACKUP_DIR/.bash-$timestamp" 2>&1 | tee -a "$log"
        elif [[ -f $item ]]; then
            msg att "A ${cyan}.bashrc${end} file is available. Backing it up..." 
            mv "$item" "$BACKUP_DIR/.bashrc-$timestamp" 2>&1 | tee -a "$log"
        fi
    fi
done

# Copy custom .bash directory
if [[ -d "$dir/.bash" ]]; then
    cp -r "$dir/.bash" ~/ 2>&1 | tee -a "$log"
    [[ -f "$HOME/.bash/.bashrc" ]] && ln -sf ~/.bash/.bashrc ~/.bashrc 2>&1 | tee -a "$log"
else
    msg err "Could not find $dir/.bash to copy!"
fi

# macOS's Terminal.app (and most other terminal emulators there) launch
# *login* shells, which read ~/.bash_profile instead of ~/.bashrc. Without
# this, none of the aliases/functions/prompt would ever load on macOS.
if [[ "$OS_TYPE" == "Darwin" && -f "$HOME/.bashrc" ]]; then
    PROFILE="$HOME/.bash_profile"
    SOURCE_LINE='[[ -f "$HOME/.bashrc" ]] && . "$HOME/.bashrc"'
    if [[ -f "$PROFILE" ]]; then
        if ! grep -qF '.bashrc' "$PROFILE"; then
            msg act "Adding ~/.bashrc sourcing to your existing ~/.bash_profile..."
            printf '\n# Load ~/.bashrc for interactive login shells (added by shell-ninja/Bash)\n%s\n' "$SOURCE_LINE" >> "$PROFILE"
        else
            msg skp "~/.bash_profile already references .bashrc, leaving it alone..."
        fi
    else
        msg act "Creating ~/.bash_profile to source ~/.bashrc (needed on macOS login shells)..."
        printf '# Load ~/.bashrc for interactive login shells (added by shell-ninja/Bash)\n%s\n' "$SOURCE_LINE" > "$PROFILE"
    fi
fi

# Update scripts and install ble.sh
if [ -d ~/.bash ]; then
    msg act "Installing ble.sh (nightly)..." && sleep 1

    TMP_BLE=$(mktemp -d)
    if curl -sL https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf - -C "$TMP_BLE" 2>&1 | tee -a "$log" > /dev/null; then
        bash "$TMP_BLE/ble-nightly/ble.sh" --install ~/.local/share 2>&1 | tee -a "$log" > /dev/null
    else
        msg err "Failed to download or extract ble.sh"
    fi
    rm -rf "$TMP_BLE"

    if [ -f ~/.blerc ]; then
        msg act "Backing up ~/.blerc file..."
        mkdir -p "$BACKUP_DIR"
        mv ~/.blerc "$BACKUP_DIR/.blerc-$(date +%I:%M:%S%p)" 2>&1 | tee -a "$log"
    fi
    # Link the new .blerc if it exists in .bash
    [[ -f ~/.bash/.blerc ]] && ln -sf ~/.bash/.blerc ~/.blerc 2>&1 | tee -a "$log"

    # Configure starship in bashrc
    if [[ "$prmpt" =~ ^[Yy]$ ]]; then
        if [ -f ~/.config/starship.toml ]; then
            msg act "Backing up your old starship.toml..." && sleep 1
            mv ~/.config/starship.toml ~/.config/starship.toml.back
        fi

        if [[ -f ~/.bash/.bashrc ]]; then
            # Comment out standard PS1 and uncomment starship init
            sed -i 's/^PS1=/# PS1=/' ~/.bash/.bashrc
            sed -i 's/^# eval "\(.*starship init bash.*\)"/eval "\1"/' ~/.bash/.bashrc
            msg dn "Updated .bashrc file. Commented out PS1 and enabled Starship prompt."
        fi
    fi
fi

sleep 1
echo

# Font installation (Linux only - macOS gets fonts via Homebrew casks above)
if [[ "$OS_TYPE" != "Darwin" && "$font" =~ ^[Yy]$ ]]; then
    msg act "Installing the ${yellow}JetBrains Mono Nerd Font${end}"

    DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    TMP_FONT=$(mktemp -d)
    
    # Maximum number of download attempts
    MAX_ATTEMPTS=2
    SUCCESS=false
    for ((ATTEMPT = 1; ATTEMPT <= MAX_ATTEMPTS; ATTEMPT++)); do
        if curl -fLo "$TMP_FONT/JetBrainsMono.tar.xz" "$DOWNLOAD_URL" > /dev/null 2>&1; then
            SUCCESS=true
            break
        fi
        msg att "Download attempt $ATTEMPT failed. Retrying in 2 seconds..."
        sleep 2
    done

    if [ "$SUCCESS" = true ]; then
        # macOS uses ~/Library/Fonts and has no fontconfig cache to rebuild;
        # Linux uses ~/.local/share/fonts and needs `fc-cache`.
        if [[ "$OS_TYPE" == "Darwin" ]]; then
            FONT_DIR="$HOME/Library/Fonts"
        else
            FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
            # Cleanup existing font directory
            if [ -d "$FONT_DIR" ]; then
                rm -rf "$FONT_DIR" > /dev/null 2>&1
            fi
        fi
        mkdir -p "$FONT_DIR"

        # Extract the new files
        tar -xJkf "$TMP_FONT/JetBrainsMono.tar.xz" -C "$FONT_DIR" > /dev/null 2>&1

        if [[ "$OS_TYPE" != "Darwin" ]]; then
            # Update font cache (Linux only, macOS registers fonts automatically)
            msg act "Updating font cache..."
            sudo fc-cache -fv > /dev/null 2>&1
        fi
        msg dn "JetBrains Mono Nerd Font installed successfully!"
    else
        msg err "Failed to download JetBrains Mono Nerd Font after $MAX_ATTEMPTS attempts."
    fi

    # Clean up 
    rm -rf "$TMP_FONT"
elif [[ "$OS_TYPE" != "Darwin" ]]; then
    msg skp "Skipping installing the ${yellow}JetBrains Mono Nerd Font${end}.\n         Please install a nerd font manually and set it to your terminal..."
fi

sleep 1 && clear

# Make scripts executable
if [[ -d "$HOME/.bash" ]]; then
    if chmod +x "$HOME/.bash"/* 2>/dev/null; then
        msg dn "Bash configuration has been completed! Close the terminal and open it again." && sleep 2
        exit 0
    else
        msg err "Could not make all the scripts executable."
        printf " Run: \n \"chmod +x ~/.bash/*\" in your terminal\n"
    fi
fi

#__________ ( code finishes here ) __________#
