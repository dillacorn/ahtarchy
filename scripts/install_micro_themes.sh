#!/bin/bash

# Ensure the script is run with sudo
if [ -z "$SUDO_USER" ]; then
    echo "This script must be run with sudo!"
    exit 1
fi

# Define variables
REPO_URL1="https://github.com/catppuccin/micro"
REPO_URL2="https://github.com/zyedidia/micro"
TEMP_DIR1=$(mktemp -d)
TEMP_DIR2=$(mktemp -d)
USER_HOME="/home/$SUDO_USER"
DEST_DIR="$USER_HOME/.config/micro/colorschemes"

# Function to check and update a repository
check_and_update_repo() {
    local repo_url=$1
    local temp_dir=$2

    echo "Checking repository $repo_url for updates..."

    git clone "$repo_url" "$temp_dir" &>/dev/null || {
        echo "❌ Failed to clone $repo_url"
        exit 1
    }

    cd "$temp_dir" || exit

    DEFAULT_BRANCH=$(git remote show origin | awk '/HEAD branch/ {print $NF}')
    git fetch origin "$DEFAULT_BRANCH" &>/dev/null
    REMOTE_COMMIT=$(git rev-parse "origin/$DEFAULT_BRANCH")
    LOCAL_COMMIT=$(git rev-parse HEAD)

    if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
        echo "📥 New updates found for $repo_url. Pulling latest changes..."
        git reset --hard "origin/$DEFAULT_BRANCH"
    else
        echo "✅ $repo_url is already up-to-date."
    fi
}

# Check and update both repositories
check_and_update_repo "$REPO_URL1" "$TEMP_DIR1"
check_and_update_repo "$REPO_URL2" "$TEMP_DIR2"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy themes from repositories
cp -r "$TEMP_DIR1/src/." "$DEST_DIR" || {
    echo "❌ Failed to copy files from $REPO_URL1"
    exit 1
}
cp -r "$TEMP_DIR2/runtime/colorschemes/." "$DEST_DIR" || {
    echo "❌ Failed to copy files from $REPO_URL2"
    exit 1
}

# Clean up temporary directories
rm -rf "$TEMP_DIR1" "$TEMP_DIR2"

# Run micro as the user to initialize config files
sudo -u "$SUDO_USER" micro &

# Capture PID and wait
MICRO_PID=$!
sleep 1
kill "$MICRO_PID" 2>/dev/null || true

echo "✅ micro was launched and terminated to initialize config."

# Overwrite settings.json
sudo -u "$SUDO_USER" tee "$USER_HOME/.config/micro/settings.json" >/dev/null <<EOL
{
   "colorscheme": "gruvbox"
}
EOL

# Fix ownership of entire .config/micro directory
chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.config/micro"

echo "🎨 Themes installed successfully and micro configured with 'gruvbox'."
