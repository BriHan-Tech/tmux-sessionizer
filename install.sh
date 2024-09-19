#!/usr/bin/env bash

# Set the target directory and script URL
INSTALL_DIR="$HOME/.tmux/scripts"
SCRIPT_URL="https://raw.githubusercontent.com/BriHan-Tech/tmux-sessionizer/refs/heads/master/scripts/sessionizer.sh"
SCRIPT_NAME="sessionizer.sh"
FULL_PATH="$INSTALL_DIR/$SCRIPT_NAME"

# Create the target directory if it does not exist
echo "Checking if the target directory exists..."
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating directory $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory $INSTALL_DIR"
        exit 1
    fi
fi

# Download the script
echo "Downloading sessionizer..."
curl -f -o "$FULL_PATH" "$SCRIPT_URL"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download sessionizer from $SCRIPT_URL"
    exit 1
fi

# Make it executable
echo "Making the script executable..."
chmod +x "$FULL_PATH"
if [ $? -ne 0 ]; then
    echo "Error: Failed to make $FULL_PATH executable"
    exit 1
fi


# Adding alias to shell configuration file 
ALIAS_NAME="sessionizer"
USER_SHELL=$(basename "$SHELL") # This extracts the name of the shell (e.g., 'zsh' or 'bash')

echo "Adding alias..."
if [ -n "$ZSH_VERSION" ]; then
    ZSHRC="$HOME/.zshrc"
    if ! grep -Fxq "alias $ALIAS_NAME='$FULL_PATH'" "$ZSHRC"; then
        echo "alias $ALIAS_NAME='$FULL_PATH'" >> "$ZSHRC"
        if [ $? -eq 0 ]; then
            echo "Alias '$ALIAS_NAME' added to $ZSHRC"
        else
            echo "Error: Failed to add the alias to $ZSHRC"
            exit 1
        fi
    else
        echo "Alias already exists in $ZSHRC"
    fi

elif [ -n "$BASH_VERSION" ]; then
    BASHRC="$HOME/.bashrc"
    if ! grep -Fxq "alias $ALIAS_NAME='$FULL_PATH'" "$BASHRC"; then
        echo "alias $ALIAS_NAME='$FULL_PATH'" >> "$BASHRC"
        if [ $? -eq 0 ]; then
            echo "Alias '$ALIAS_NAME' added to $BASHRC"
        else
            echo "Error: Failed to add the alias to $BASHRC"
            exit 1
        fi
    else
        echo "Alias already exists in $BASHRC"
    fi

else
    echo "Error: Unsupported shell. This script supports Zsh and Bash."
    exit 1
fi

echo "Installation complete! Remember to source your shell to start using the 'tmux-sessionizer' with the 'sessionizer' alias!"
