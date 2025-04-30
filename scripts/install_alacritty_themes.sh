#!/bin/bash

# Determine if the script is run with sudo
if [ -z "$SUDO_USER" ]; then
    # Not run with sudo
    TARGET_DIR="$HOME/.config/alacritty"
else
    # Run with sudo
    TARGET_DIR="/home/$SUDO_USER/.config/alacritty"
fi

# Attempt to clone the repo, but prompt the user if the directory already exists
if [ -d "$TARGET_DIR/themes" ]; then
    echo "The 'themes' directory already exists in $TARGET_DIR. Checking for updates..."

    # Navigate to the themes directory
    cd "$TARGET_DIR/themes" || exit

    # Fetch the latest changes from the remote repository
    git fetch origin

    # Determine the default branch name
    DEFAULT_BRANCH=$(git remote show origin | awk '/HEAD branch/ {print $NF}')

    # Get the latest commit hash on the remote default branch
    REMOTE_COMMIT=$(git rev-parse "origin/$DEFAULT_BRANCH")
    LOCAL_COMMIT=$(git rev-parse HEAD)

    if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
        echo "Updating 'themes' directory to the latest version..."
        git reset --hard "origin/$DEFAULT_BRANCH"
    else
        echo "The 'themes' directory is up-to-date."
    fi
else
    # Clone the alacritty-theme repository if it does not exist
    git clone https://github.com/alacritty/alacritty-theme "$TARGET_DIR/themes"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone the repository. Exiting."
        exit 1
    fi
fi

# Confirm completion
echo "Finished running install_alacritty_themes.sh. 'themes' directory placed in $TARGET_DIR"
exit 0  # Explicitly return control
