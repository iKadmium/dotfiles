#!/bin/sh

# 1. Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to path for the remainder of this script
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
fi

# 2. Install "Phase 1" dependencies
echo "Installing bootstrap tools..."
brew install lastpass-cli chezmoi 

# 3. Authenticate with LastPass
echo "Authenticating with LastPass..."
lpass login jesse.d.higginson@gmail.com

# 4. Initialize Chezmoi
# This will trigger the .toml.tmpl, pull the Age key, and decrypt your SSH keys
echo "Initializing dotfiles..."
chezmoi init --apply https://github.com/iKadmium/dotfiles.git