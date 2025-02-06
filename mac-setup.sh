#!/bin/bash

# User Configuration
# ------------------
# Your personal information for Git and SSH key
USER_NAME="Ryan"
USER_EMAIL="ryanspacekirk@gmail.com"

# Dotfiles configuration
DOTFILES_REPO="git@github.com:ryanspacekirk/dotfiles.git"
ZSHRC_URL="${DOTFILES_REPO}/.zshrc"

# Exit on any error
set -e

echo "Starting Mac setup script..."

# Function to check if a Homebrew package is installed
check_brew_package() {
    # Returns true if package is installed, false otherwise
    brew list "$1" &>/dev/null
}

# Function to check if a Homebrew cask is installed
check_brew_cask() {
    local cask_name=$1
    local app_name
    
    # Map cask names to their actual .app names
    # This is necessary because cask names often don't match installed app names
    case $cask_name in
        "visual-studio-code")
            app_name="Visual Studio Code.app"
            ;;
        "firefox")
            app_name="Firefox.app"
            ;;
        "docker")
            app_name="Docker.app"
            ;;
        *)
            # For unknown applications, capitalize first letter and add .app
            app_name="$(echo "$cask_name" | sed 's/./\U&/').app"
            ;;
    esac
    
    # Check both Homebrew installation and Applications folders
    if [ -d "/Applications/$app_name" ] || [ -d "$HOME/Applications/$app_name" ]; then
        return 0  # Application found in Applications folder
    else
        # Fall back to checking Homebrew cask list
        brew list --cask "$cask_name" &>/dev/null
    fi
}

# Function to install a Homebrew package if not already installed
install_brew_package() {
    local package=$1
    if check_brew_package "$package"; then
        echo "✓ $package is already installed"
    else
        echo "Installing $package..."
        brew install "$package"
    fi
}

# Function to install a Homebrew cask if not already installed
install_brew_cask() {
    local cask=$1
    if check_brew_cask "$cask"; then
        echo "✓ $cask is already installed"
    else
        echo "Installing $cask..."
        brew install --cask "$cask"
    fi
}

# Install Xcode Command Line Tools if not already installed
if ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    # Wait for installation to complete
    until xcode-select -p &> /dev/null; do
        sleep 5
    done
fi

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "✓ Homebrew is already installed"
    # Update Homebrew to get latest package information
    echo "Updating Homebrew..."
    brew update
fi

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Download your custom .zshrc if URL is provided
    if [ "$ZSHRC_URL" != "${DOTFILES_REPO}/.zshrc" ]; then
        echo "Downloading custom .zshrc..."
        curl -o ~/.zshrc "$ZSHRC_URL"
    fi
else
    echo "✓ Oh My Zsh is already installed"
fi

# Install command line applications via Homebrew
echo "Installing command line applications via Homebrew..."
BREW_PACKAGES=(
    "git"
    "docker"
    "python3"
    "node"

    # Add more packages as needed
)

for package in "${BREW_PACKAGES[@]}"; do
    install_brew_package "$package"
done

# Install GUI applications via Homebrew Cask
echo "Installing GUI applications via Homebrew Cask..."
BREW_CASK_PACKAGES=(
    "docker"
    "visual-studio-code"
    "firefox"
    "coteditor"
    
    # Add more GUI applications as needed
)

for package in "${BREW_CASK_PACKAGES[@]}"; do
    install_brew_cask "$package"
done

# Generate SSH key if it doesn't exist
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Generating SSH key..."
    # Generate SSH key with provided email
    ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY_PATH" -N ""
    
    # Start ssh-agent and add the key
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY_PATH"
    
    # Copy public key to clipboard
    cat "$SSH_KEY_PATH.pub" > ~/Desktop/my_ssh_key.txt
    echo "SSH public key has been copied to clipboard. Please add it to your GitHub account."
    echo "You can view it here:"
    cat "$SSH_KEY_PATH.pub"
else
    echo "✓ SSH key already exists at $SSH_KEY_PATH"
fi

echo "Starting Git configuration..."

# Get current git configuration with error handling
current_git_user=$(git config --global user.name || echo "")
current_git_email=$(git config --global user.email || echo "")

echo "Current Git configuration:"
echo "User: '$current_git_user'"
echo "Email: '$current_git_email'"
echo "Desired configuration:"
echo "User: '$USER_NAME'"
echo "Email: '$USER_EMAIL'"

# Check if configuration needs updating
if [ "$current_git_user" != "$USER_NAME" ] || [ "$current_git_email" != "$USER_EMAIL" ]; then
    echo "Updating Git configuration..."
    # Add error handling to git config commands
    if git config --global user.name "$USER_NAME"; then
        echo "✓ Successfully set Git user name"
    else
        echo "Error: Failed to set Git user name"
        return 1
    fi
    
    if git config --global user.email "$USER_EMAIL"; then
        echo "✓ Successfully set Git email"
    else
        echo "Error: Failed to set Git email"
        return 1
    fi
else
    echo "✓ Git is already configured with correct user information"
fi

# Verify the configuration was set correctly
echo "Verifying Git configuration..."
new_git_user=$(git config --global user.name)
new_git_email=$(git config --global user.email)

echo "Final Git configuration:"
echo "User: '$new_git_user'"
echo "Email: '$new_git_email'"

echo ""
echo "======================================"
echo "          SETUP COMPLETE              "
echo "======================================"
echo ""
echo "Important next steps:"
echo "------------------------------------"
echo "1. Add the SSH key to your GitHub account (if newly generated)"
echo "2. Customize your .zshrc file if needed"
echo "3. Launch Docker Desktop to complete its setup (if newly installed)"
echo ""
echo "If you don't see these steps, something may have gone wrong."
echo "Check the output above for any error messages."