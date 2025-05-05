#!/bin/bash
#################################################
##           Installation Instructions         ##
#################################################

# Step 1: Download the repository
# --------------------------------
# Open a terminal and run:
#   sudo pacman -S git
#   git clone https://github.com/dillacorn/arch-hypr-dots

# Step 2: Run the installer
# -------------------------
# Navigate to the arch-hypr-dots directory:
#   cd arch-hypr-dots
# Make the installer executable and run it:
#   chmod +x setup_installer.sh
#   sudo ./setup_installer.sh
# Follow the on-screen instructions.

#################################################
##              End of Instructions            ##
#################################################

# Ensure the script is run with sudo
if [ -z "$SUDO_USER" ]; then
    echo "This script must be run with sudo!"
    exit 1
fi

retry_command() {
    local retries=3
    local count=0
    until "$@"; do
        exit_code=$?
        count=$((count + 1))
        echo -e "\033[1;31mAttempt $count/$retries failed for command:\033[0m"
        printf "'%s' " "$@"; echo
        if [ $count -lt $retries ]; then
            echo -e "\033[1;31mRetrying...\033[0m"
            sleep 1
        else
            echo -e "\033[1;31mCommand failed after $retries attempts. Exiting.\033[0m"
            return $exit_code
        fi
    done
    return 0
}

# Ensure script is being run from the correct directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Check if there's enough disk space (e.g., 1GB)
REQUIRED_SPACE_MB=1024
AVAILABLE_SPACE_MB=$(df / | tail -1 | awk '{print $4}')

if [ "$AVAILABLE_SPACE_MB" -lt "$REQUIRED_SPACE_MB" ]; then
    echo -e "\033[1;31mNot enough disk space (1GB required). Exiting.\033[0m"
    exit 1
fi

set -eu -o pipefail # fail on error and report it, debug all lines

# First confirmation
echo -e "\033[1;31mWARNING: This script will overwrite the following directories:\033[0m"
echo -e "\033[1;33m
- ~/.config/hypr
- ~/.config/waybar
- ~/.config/alacritty
- ~/.config/rofi
- ~/.config/mako
- ~/.config/gtk-3.0
- ~/.config/SpeedCrunch
- ~/.config/fastfetch
- ~/.config/wlogout
- ~/.config/xdg-desktop-portal\033[0m"
echo -e "\033[1;31mAre you sure you want to continue? This action CANNOT be undone.\033[0m"
echo -e "\033[1;32mPress 'y' to continue or 'n' to cancel. Default is 'yes' if Enter is pressed:\033[0m"

read -n 1 -r first_confirmation
echo

# If user presses Enter (no input), default to 'y'
if [[ "$first_confirmation" != "y" && "$first_confirmation" != "Y" && "$first_confirmation" != "" ]]; then
    echo -e "\033[1;31mInstallation canceled by user.\033[0m"
    exit 1
fi

# Second confirmation
echo -e "\033[1;31mThis is your last chance! Are you absolutely sure? (y/n)\033[0m"
read -n 1 -r second_confirmation
echo

if [[ "$second_confirmation" != "y" && "$second_confirmation" != "Y" && "$second_confirmation" != "" ]]; then
    echo -e "\033[1;31mInstallation canceled by user.\033[0m"
    exit 1
fi

# Adding pause before continuing
echo -e "\033[1;32mProceeding with the installation...\033[0m"
read -r -p "Press Enter to continue..."

# Set the home directory of the sudo user
HOME_DIR="/home/$SUDO_USER"

# Function to check and create directories if they don't exist
create_directory() {
    if [ ! -d "$1" ]; then
        echo -e "\033[1;33mCreating missing directory: $1\033[0m"
        retry_command mkdir -p "$1" || { echo -e "\033[1;31mFailed to create directory $1. Exiting.\033[0m"; exit 1; }
    else
        echo -e "\033[1;32mDirectory already exists: $1\033[0m"
    fi
    # Ensure correct ownership for non-root user ($SUDO_USER)
    retry_command chown "$SUDO_USER:$SUDO_USER" "$1" || { echo -e "\033[1;31mFailed to set ownership for $1. Exiting.\033[0m"; exit 1; }
    retry_command chmod 755 "$1" || { echo -e "\033[1;31mFailed to set permissions for $1. Exiting.\033[0m"; exit 1; }
}

# Install git if it's not already installed
echo -e "\033[1;34mUpdating package list and installing git...\033[0m"
if ! retry_command pacman -Syu --noconfirm; then
    echo -e "\033[1;31mFailed to update package list. Refreshing mirrors...\033[0m"
    retry_command sudo reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
    echo -e "\033[1;34mMirrors refreshed. Retrying package list update...\033[0m"
    if ! retry_command pacman -Syu --noconfirm; then
        echo -e "\033[1;31mFailed to update package list after refreshing mirrors. Exiting.\033[0m"
        exit 1
    fi
fi

retry_command pacman -S --needed --noconfirm git || { echo -e "\033[1;31mFailed to install git. Exiting.\033[0m"; exit 1; }

# Check for ipcalc availability and install if not available
if ! command -v ipcalc &>/dev/null; then
    echo -e "\033[1;34mipcalc is not installed. Installing ipcalc...\033[0m"
    retry_command pacman -S --needed --noconfirm ipcalc || { echo -e "\033[1;31mFailed to install ipcalc. Exiting.\033[0m"; exit 1; }
else
    echo -e "\033[1;32mipcalc is already installed. Continuing...\033[0m"
fi

# Clone the arch-hypr-dots repository
if [ ! -d "$HOME_DIR/arch-hypr-dots" ]; then
    echo -e "\033[1;34mCloning arch-hypr-dots repository...\033[0m"
    retry_command git clone https://github.com/dillacorn/arch-hypr-dots "$HOME_DIR/arch-hypr-dots" || { echo -e "\033[1;31mFailed to clone arch-hypr-dots repository. Exiting.\033[0m"; exit 1; }
    retry_command chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR/arch-hypr-dots"
else
    echo -e "\033[1;32march-hypr-dots repository already exists in $HOME_DIR\033[0m"
fi

# Make scripts executable
echo -e "\033[1;34mMaking ~/arch-hypr-dots/scripts executable!\033[0m"
cd "$HOME_DIR/arch-hypr-dots/scripts" || exit
retry_command chmod +x ./* || { echo -e "\033[1;31mFailed to make scripts executable. Exiting.\033[0m"; exit 1; }
retry_command chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR/arch-hypr-dots/scripts" || { echo -e "\033[1;31mFailed to set ownership for scripts. Exiting.\033[0m"; exit 1; }

# Run installation scripts for packages
echo -e "\033[1;34mRunning install_arch_repo_apps.sh...\033[0m"
if ! retry_command ./install_arch_repo_apps.sh; then
    echo -e "\033[1;31minstall_arch_repo_apps.sh failed. Please check for errors in the script.\033[0m"
    exit 1
fi
read -r -p "Press Enter to run the next script..."

echo -e "\033[1;34mRunning install_aur_repo_apps.sh...\033[0m"
if ! retry_command ./install_aur_repo_apps.sh; then
    echo -e "\033[1;31minstall_aur_repo_apps.sh failed. Please check for errors in the script.\033[0m"
    exit 1
fi
read -r -p "Press Enter to run the next script..."

echo -e "\033[1;34mRunning install_flatpak_apps.sh...\033[0m"
if ! retry_command ./install_flatpak_apps.sh; then
    echo -e "\033[1;31minstall_flatpak_apps.sh failed. Please check for errors in the script.\033[0m"
    exit 1
fi

# Ensure ~/.local/share/applications directory exists
create_directory "$HOME_DIR/.local/share/applications"

# Copy .desktop files into ~/.local/share/applications
echo -e "\033[1;34mCopying .desktop files to ~/.local/share/applications...\033[0m"
retry_command cp -r "$HOME_DIR/arch-hypr-dots/local/share/applications/." "$HOME_DIR/.local/share/applications" || { echo -e "\033[1;31mFailed to copy .desktop files. Exiting.\033[0m"; exit 1; }

# Set correct permissions for ~/.local
retry_command chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR/.local"
retry_command chmod u+rwx "$HOME_DIR/.local"
retry_command chmod u+rwx "$HOME_DIR/.local/share"
echo -e "\033[1;32mOwnership and permissions for ~/.local set correctly.\033[0m"

# Check if Comix Cursors exist in ~/.local/share/icons
if [ ! -d "$HOME_DIR/.local/share/icons/ComixCursors-White" ]; then
    echo -e "\033[1;33mComix Cursors not found in ~/.local/share/icons. Attempting to install... \033[0m"
    
    # Attempt to install Comix Cursors
    retry_command pacman -S --needed --noconfirm xcursor-comix || { echo -e "\033[1;31mFailed to install Comix Cursors. Exiting.\033[0m"; exit 1; }
    
    echo -e "\033[1;33mCopying Comix Cursors to ~/.local/share/icons...\033[0m"
    mkdir -p "$HOME_DIR/.local/share/icons/ComixCursors-White"  # Ensure directory exists
    retry_command cp -r /usr/share/icons/ComixCursors-White/* "$HOME_DIR/.local/share/icons/ComixCursors-White" || { echo -e "\033[1;31mFailed to copy Comix Cursors. Exiting.\033[0m"; exit 1; }
    retry_command chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR/.local/share/icons/ComixCursors-White"
else
    echo -e "\033[1;32mComix Cursors already exists in ~/.local/share/icons.\033[0m"
fi

# Apply cursor theme system-wide
echo -e "\033[1;34mSetting cursor theme to ComixCursors-White...\033[0m"
retry_command sudo bash -c 'cat > /usr/share/icons/default/index.theme <<EOF
[Icon Theme]
Inherits=ComixCursors-White
EOF'

# Check the exit code directly
if ! retry_command sudo bash -c 'cat > /usr/share/icons/default/index.theme <<EOF
[Icon Theme]
Inherits=ComixCursors-White
EOF'; then
    echo -e "\033[1;31mFailed to set cursor theme. Exiting.\033[0m"
    exit 1
fi

# Apply cursor theme to Flatpak applications
echo -e "\033[1;34mApplying cursor theme to Flatpak applications...\033[0m"
if retry_command flatpak override --user --env=GTK_CURSOR_THEME=ComixCursors-White; then
    echo -e "\033[1;32mCursor theme applied to Flatpak applications successfully.\033[0m"
else
    echo -e "\033[1;31mFailed to apply cursor theme to Flatpak applications.\033[0m"
    exit 1
fi

# Run the micro themes installation script
echo -e "\033[1;34mRunning install_micro_themes.sh...\033[0m"
retry_command ./install_micro_themes.sh || { echo -e "\033[1;31minstall_micro_themes.sh failed. Exiting.\033[0m"; exit 1; }

# Copy configuration files
config_dirs=("gtk-3.0" "hypr" "waybar" "alacritty" "wlogout" "mako" "rofi" "SpeedCrunch" "fastfetch" "xdg-desktop-portal")

for config in "${config_dirs[@]}"; do
    echo -e "\033[1;32mCopying $config config...\033[0m"
    retry_command cp -r "$HOME_DIR/arch-hypr-dots/config/$config" "$HOME_DIR/.config" || { echo -e "\033[1;31mFailed to copy $config config. Exiting.\033[0m"; exit 1; }
    retry_command chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR/.config/$config"
done

# Copy mimeapps.list to ~/.config
echo -e "\033[1;34mCopying mimeapps.list to $HOME_DIR/.config...\033[0m"
retry_command cp "$HOME_DIR/arch-hypr-dots/config/mimeapps.list" "$HOME_DIR/.config/" || { echo -e "\033[1;31mFailed to copy mimeapps.list. Exiting.\033[0m"; exit 1; }
retry_command chown "$SUDO_USER:$SUDO_USER" "$HOME_DIR/.config/mimeapps.list"

# Set permissions for .config
echo -e "\033[1;34mSetting permissions on configuration files and directories...\033[0m"
retry_command find "$HOME_DIR/.config/" -type d -exec chmod 755 {} +
retry_command find "$HOME_DIR/.config/" -type f -exec chmod 644 {} +

# Make hypr-related scripts executable (recursively) ~ commented out unless I need scripts in the future
# echo -e "\033[1;34mMaking hypr-related scripts executable...\033[0m"
# retry_command find "$HOME_DIR/.config/hypr/scripts" -type f -exec chmod +x {} +

# Convert line endings to Unix format for hypr themes and scripts directories
# echo -e "\033[1;34mConverting line endings to Unix format for hypr themes and scripts...\033[0m"
# retry_command dos2unix $HOME_DIR/.config/hypr/themes/./* || { echo -e "\033[1;31mFailed to convert line endings for hypr themes. Exiting.\033[0m"; exit 1; }
# retry_command dos2unix $HOME_DIR/.config/hypr/scripts/./* || { echo -e "\033[1;31mFailed to convert line endings for hypr scripts. Exiting.\033[0m"; exit 1; }

# Install Alacritty themes
echo -e "\033[1;34mRunning install_alacritty_themes.sh...\033[0m"
cd "$HOME_DIR/arch-hypr-dots/scripts" || exit
if [ -f "./install_alacritty_themes.sh" ]; then
    retry_command chmod +x ./install_alacritty_themes.sh
    retry_command ./install_alacritty_themes.sh || { echo -e "\033[1;31mAlacritty themes installation failed. Exiting.\033[0m"; exit 1; }
    echo -e "\033[1;32mAlacritty themes installed successfully.\033[0m"
else
    echo -e "\033[1;31minstall_alacritty_themes.sh not found. Exiting.\033[0m"
    exit 1
fi
read -r -p "Press Enter to continue..."

# Install GPU dependencies
echo -e "\033[1;34mRunning install_GPU_dependencies.sh...\033[0m"
cd "$HOME_DIR/arch-hypr-dots/scripts" || exit

if [ -f "./install_GPU_dependencies.sh" ]; then
    retry_command chmod +x ./install_GPU_dependencies.sh

    if retry_command ./install_GPU_dependencies.sh; then
        if systemd-detect-virt --quiet; then
            echo -e "\033[1;33mRunning in a virtual machine. GPU-specific configuration skipped.\033[0m"
        else
            echo -e "\033[1;32mGPU dependencies installed successfully.\033[0m"
        fi
    else
        echo -e "\033[1;31mGPU dependencies installation failed. Exiting.\033[0m"
        exit 1
    fi
else
    echo -e "\033[1;31minstall_GPU_dependencies.sh not found. Exiting.\033[0m"
    exit 1
fi

read -r -p "Press Enter to continue..."

# Set alternatives for editor
echo -e "\033[1;94mSetting micro as default editor...\033[0m"
retry_command echo 'export EDITOR=/usr/bin/micro' >> "$HOME_DIR/.bashrc" || { echo -e "\033[1;31mFailed to set micro as default editor. Exiting.\033[0m"; exit 1; }

# Set hypr launch command
echo -e "\033[1;94mSetting \"hypr\" command in .bashrc...\033[0m"
echo "alias hypr='XDG_SESSION_TYPE=wayland exec Hyprland'" >> "$HOME_DIR/.bashrc" || {
    echo -e "\033[1;31mFailed to add alias to .bashrc. Exiting.\033[0m"
    exit 1
}

# Reload .bashrc after setting variables
retry_command source "$HOME_DIR/.bashrc" || { echo -e "\033[1;31mFailed to reload .bashrc. Exiting.\033[0m"; exit 1; }

# Set default file manager for directories
echo -e "\033[1;94mSetting pcmanfm as default GUI file manager...\033[0m"
retry_command xdg-mime default pcmanfm.desktop inode/directory

# Change ownership of all files in .config to the sudo user
echo -e "\033[1;32mConverting .config file ownership...\033[0m"
retry_command chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR/.config"

# Ensure ~/Pictures directory exists and correct permissions are set
create_directory "$HOME_DIR/Pictures/wallpapers"

# Copy wallpaper to ~/Pictures/wallpapers directory
echo -e "\033[1;94mCopying wallpaper...\033[0m"
retry_command cp "$HOME_DIR/arch-hypr-dots/arch_geology.png" "$HOME_DIR/Pictures/wallpapers/" || { echo -e "\033[1;31mFailed to copy wallpaper. Exiting.\033[0m"; exit 1; }

# Check if Wayland is running
if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
    if command -v swww &> /dev/null; then
        echo -e "\033[1;32mswww is installed. Setting up wallpaper...\033[0m"

        WALLPAPER_DIR="$HOME_DIR/Pictures/wallpapers"
        create_directory "$WALLPAPER_DIR" || {
            echo -e "\033[1;31mFailed to ensure wallpaper directory. Exiting.\033[0m"
            exit 1
        }

        WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | head -n 1)

        if [ -n "$WALLPAPER" ]; then
            if ! pgrep -x "swww-daemon" > /dev/null; then
                echo -e "\033[1;34mStarting swww daemon...\033[0m"
                swww-daemon --format=json &
                sleep 1
            fi

            echo -e "\033[1;34mSetting wallpaper to $WALLPAPER...\033[0m"
            swww img "$WALLPAPER" --transition-type any --transition-fps 60 --transition-duration 1

            echo -e "\033[1;32mWallpaper successfully set using swww.\033[0m"
        else
            echo -e "\033[1;33mNo wallpapers found in $WALLPAPER_DIR. Skipping...\033[0m"
        fi
    else
        echo -e "\033[1;33mswww is not installed. Skipping wallpaper setup...\033[0m"
    fi
else
    echo -e "\033[1;33mNot in a Wayland session. Skipping swww wallpaper setup...\033[0m"
fi

# Ensure ~/Pictures/Screenshots directory exists and correct permissions are set
create_directory "$HOME_DIR/Pictures/Screenshots"

# Set the cursor theme in /usr/share/icons/default/index.theme
echo -e "\033[1;34mSetting cursor theme to ComixCursor-White...\033[0m"
if ! retry_command sudo bash -c 'cat > /usr/share/icons/default/index.theme <<EOF
[Icon Theme]
Inherits=ComixCursor-White
EOF'; then
    echo -e "\033[1;31mFailed to set cursor theme. Exiting.\033[0m"
    exit 1
fi

# Create target directory
WLOGOUT_DIR="$HOME_DIR/.config/wlogout"
mkdir -p "$WLOGOUT_DIR"

# Download PNG icons for wlogout from GitHub
echo -e "\033[1;34mDownloading wlogout icons...\033[0m"
base_url="https://raw.githubusercontent.com/warpje5/hyprland-dotfiles-gruvbox/main/wlogout"

for icon in lock.png lock-hover.png logout.png logout-hover.png \
            power.png power-hover.png restart.png restart-hover.png \
            sleep.png sleep-hover.png windows.png windows-hover.png; do
    if curl -fsSL "$base_url/$icon" -o "$WLOGOUT_DIR/$icon"; then
        echo -e "\033[1;32mDownloaded $icon\033[0m"
    else
        echo -e "\033[1;31mFailed to download $icon\033[0m"
    fi
done

# List of directories to check/create
required_dirs=(
    "$HOME_DIR/.config"
    "$HOME_DIR/Videos"
    "$HOME_DIR/Pictures/wallpapers"
    "$HOME_DIR/Documents"
    "$HOME_DIR/Downloads"
    "$HOME_DIR/.local/share/icons"
)

# Create the required directories
for dir in "${required_dirs[@]}"; do
    create_directory "$dir"
done

# Fix permissions for Pictures directory
if [ -d "$HOME_DIR/Pictures" ]; then
    retry_command chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR/Pictures"
fi

# Path to the non-root user's .bash_profile
BASH_PROFILE="/home/$SUDO_USER/.bash_profile"

# Check if .bash_profile exists, create if it doesn't
if [ ! -f "$BASH_PROFILE" ]; then
    echo "Creating $BASH_PROFILE..."
    touch "$BASH_PROFILE"
    chown "$SUDO_USER:$SUDO_USER" "$BASH_PROFILE"
fi

# Add fastfetch to bash_profile if it doesn't exist already
if ! grep -q "fastfetch" "$BASH_PROFILE"; then
    echo "Adding fastfetch to $BASH_PROFILE..."
    echo -e "\nfastfetch --config ~/.config/fastfetch/tty_compatible.jsonc" >> "$BASH_PROFILE"
    chown "$SUDO_USER:$SUDO_USER" "$BASH_PROFILE"
fi

# Add figlet Welcome message using the default font
if ! grep -q "figlet" "$BASH_PROFILE"; then
    echo "Adding figlet welcome to $BASH_PROFILE..."
    echo -e "\nfiglet \"Welcome \$USER!\"" >> "$BASH_PROFILE"
    chown "$SUDO_USER:$SUDO_USER" "$BASH_PROFILE"
fi

# Add hypr-wm instruction
if ! grep -q "To start hypr" "$BASH_PROFILE"; then
    echo "Adding hypr instruction to $BASH_PROFILE..."
    printf 'echo -e "\033[1;34mTo start hypr, type: \033[1;31mhypr\033[0m"\n' >> "$BASH_PROFILE"
    chown "$SUDO_USER:$SUDO_USER" "$BASH_PROFILE"
fi

# Add random fun message generator to .bash_profile
if ! grep -q "add_random_fun_message" "$BASH_PROFILE"; then
    echo "Adding random fun message function to $BASH_PROFILE..."

    # Append the function definition and call to .bash_profile
    {
        echo -e "\n# Function to generate a random fun message"
        echo -e "add_random_fun_message() {"
        echo -e "  fun_messages=(\"cacafire\" \"cmatrix\" \"aafire\" \"sl\" \"asciiquarium\" \"figlet TTY is cool\")"
        echo -e "  RANDOM_FUN_MESSAGE=\${fun_messages[\$RANDOM % \${#fun_messages[@]}]}"
        echo -e "  echo -e \"\\033[1;33mFor some fun, try running \\033[1;31m\$RANDOM_FUN_MESSAGE\\033[1;33m !\\033[0m\""
        echo -e "}"
        echo -e "\n# Call the random fun message function on login"
        echo -e "add_random_fun_message"
    } >> "$BASH_PROFILE"

    chown "$SUDO_USER:$SUDO_USER" "$BASH_PROFILE"
fi

echo "Changes have been applied to $BASH_PROFILE."

# add grub directory for editing and updating with command:
# sudo grub-mkconfig -o /boot/grub/grub.cfg
mkdir -p /boot/grub

# Prompt the user to reboot the system after setup
echo -e "\033[1;34mSetup complete! Do you want to reboot now? (y/n)\033[0m"
read -n 1 -r reboot_choice
if [[ "$reboot_choice" == "y" || "$reboot_choice" == "Y" ]]; then
    echo -e "\033[1;34mRebooting...\033[0m"
    sleep 1
    retry_command reboot
else
    echo -e "\033[1;32mReboot skipped. You can reboot manually later.\033[0m"
    read -r -p "Press Enter to finish..."
fi
